import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/task.dart';
import 'models/transaction.dart';
import 'models/debt.dart';
import 'models/attendance_day.dart';
import 'pages/app_shell.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';
import 'pages/welcome_page.dart';
import 'services/notification_service.dart';

// Create a global instance
final NotificationService notificationService = NotificationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init notifications
  await notificationService.init();

  await Hive.initFlutter();

  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(DebtAdapter());
  Hive.registerAdapter(AttendanceDayAdapter());
  Hive.registerAdapter(AttendanceStatusAdapter());

  await Hive.openBox<Task>('tasks');
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<Debt>('debts');
  await Hive.openBox<AttendanceDay>('attendance');
  final settingsBox = await Hive.openBox('settings');
  await Hive.openBox('attendance_settings');

  // --- AUTO-DELETE LOGIC ---
  final autoDeleteProgress = settingsBox.get('autoDeleteProgress', defaultValue: false) as bool;
  final autoDeleteMoney = settingsBox.get('autoDeleteMoney', defaultValue: false) as bool;

  if (autoDeleteProgress) {
    await _runAutoDeleteProgressData();
  }
  if (autoDeleteMoney) {
    await _runAutoDeleteMoneyData();
  }
  // --- END LOGIC ---

  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsService(settingsBox),
      child: const MyApp(),
    ),
  );
}

// --- AUTO-DELETE HELPER FUNCTIONS ---
Future<void> _runAutoDeleteProgressData() async {
  final now = DateTime.now();
  final twelveMonthsAgo = DateTime(now.year - 1, now.month, now.day);

  final taskBox = Hive.box<Task>('tasks');
  List<Task> tasksToDelete = [];

  for (var task in taskBox.values) {
    if (!task.isHabit && task.isDone && task.createdAt.isBefore(twelveMonthsAgo)) {
      tasksToDelete.add(task);
    }
    else if (task.isHabit) {
      task.completionHistory.removeWhere((date) => date.isBefore(twelveMonthsAgo));
      await task.save();
    }
  }
  for (var task in tasksToDelete) {
    await task.delete();
  }
}

Future<void> _runAutoDeleteMoneyData() async {
  final now = DateTime.now();
  final twelveMonthsAgo = DateTime(now.year - 1, now.month, now.day);

  final transactionBox = Hive.box<Transaction>('transactions');
  final debtBox = Hive.box<Debt>('debts');
  final attendanceBox = Hive.box<AttendanceDay>('attendance');

  List<Transaction> toDeleteTx = transactionBox.values
      .where((tx) => tx.date.isBefore(twelveMonthsAgo))
      .toList();
  for (var tx in toDeleteTx) {
    await tx.delete();
  }

  List<Debt> toDeleteDebt = debtBox.values
      .where((debt) => debt.createdAt.isBefore(twelveMonthsAgo))
      .toList();
  for (var debt in toDeleteDebt) {
    await debt.delete();
  }

  List<AttendanceDay> toDeleteAttendance = attendanceBox.values
      .where((day) => DateTime.parse(day.dateKey).isBefore(twelveMonthsAgo))
      .toList();
  for (var day in toDeleteAttendance) {
    await day.delete();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = context.watch<SettingsService>();

    return MaterialApp(
      title: 'Get Up',
      debugShowCheckedModeBanner: false,
      themeMode: settingsService.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: settingsService.userName == null
          ? const WelcomePage()
          : const AppShell(),
    );
  }
}
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
import 'services/notification_service.dart'; // <-- 1. IMPORT NOTIFICATION SERVICE

// --- 2. CREATE A GLOBAL INSTANCE ---
final NotificationService notificationService = NotificationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- 3. INITIALIZE NOTIFICATIONS ---
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

  // ... (Auto-delete logic is unchanged) ...

  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsService(settingsBox),
      child: const MyApp(),
    ),
  );
}

// ... (Auto-delete functions are unchanged) ...
Future<void> _runAutoDeleteProgressData() async { /* ... */ }
Future<void> _runAutoDeleteMoneyData() async { /* ... */ }


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = context.watch<SettingsService>();

    return MaterialApp(
      title: 'Progress Tracker',
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
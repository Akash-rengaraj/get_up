import 'package:flutter/material.dart';
import 'package:get_up/models/task.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:get_up/main.dart'; // Import main.dart to get notificationService
import '../widgets/add_task_modal.dart';
import '../widgets/animated_task_tile.dart';
import 'settings_page.dart';
import '../services/settings_service.dart';
import 'edit_tasks_page.dart';

// A helper function to check if a date is "today"
bool isToday(DateTime? date) {
  if (date == null) return false;
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month && date.day == now.day;
}

// Checks if a list of dates contains "today"
bool isCompletedToday(List<DateTime> history) {
  return history.any((date) => isToday(date));
}

class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  final Box<Task> taskBox = Hive.box<Task>('tasks');

  bool _isBirthday = false;
  String _greeting = "Good Morning!";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateGreeting();
  }

  void _updateGreeting() {
    final settings = context.read<SettingsService>();
    final userName = settings.userName ?? "User";
    final dobString = settings.userDOB;

    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning, $userName!';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon, $userName!';
    } else {
      _greeting = 'Good Evening, $userName!';
    }

    if (dobString != null && dobString.isNotEmpty) {
      try {
        final dob = DateTime.parse(dobString);
        final now = DateTime.now();
        if (dob.month == now.month && dob.day == now.day) {
          _isBirthday = true;
          _greeting = 'Happy Birthday, $userName!';
        } else {
          _isBirthday = false;
        }
      } catch (e) {
        _isBirthday = false; // Invalid date format
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }


  Future<void> _confirmDelete(Task task) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await notificationService.cancelNotification(task);
      await task.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${task.title}"'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _toggleTask(Task task, bool isHabit) {
    if (isHabit) {
      final bool isDone = isCompletedToday(task.completionHistory);
      if (isDone) {
        task.completionHistory.removeWhere((date) => isToday(date));
        notificationService.scheduleHabitNotification(task);
      } else {
        task.completionHistory.add(DateTime.now());
        // You could cancel the notification here if you want
        // notificationService.cancelNotification(task);
      }
    } else {
      task.isDone = !task.isDone;
      if (task.isDone) {
        notificationService.cancelNotification(task);
      }
    }
    task.save();
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 10),
            Text('How to use "Get Up"'),
          ],
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              const Text(
                'Welcome to Get Up! This is your daily dashboard.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Habits (Studies & Personal)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Text(
                '• Habits (like "Workout" or "Read") reset every day.\n'
                    '• Check them off to track your progress. You can uncheck them.\n'
                    '• The "Progress" tab only tracks your habits, not todos.',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 16),
              const Text(
                '2. Todos (One-Time Tasks)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Text(
                '• Todos (like "Buy groceries") are for one-time tasks.\n'
                    '• When you check one off, it disappears from this page.\n'
                    '• Todos are NOT tracked in your "Progress" graphs.',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 16),
              const Text(
                'How to Add & Manage:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Text(
                '• Tap the big "+" button to add any new item.\n'
                    '• Go to the "Progress" tab to see your charts.\n'
                    '• Go to the "Money" tab to track your finances.\n'
                    '• Go to the "Attendance" tab to track your attendance.\n'
                    '• Go to the "Edit Tasks" tab to manage your data, theme, and profile.',
                style: TextStyle(fontSize: 15),
              ),
              const Divider(height: 32),
              const Text(
                'For Developers:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Text(
                'Welcome! This app is built with Flutter & Hive. If you want to contribute, feel free to fork the project and start building!',
                style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final String todayDate = DateFormat('MMMM d, yyyy').format(DateTime.now());

    final settingsService = context.watch<SettingsService>();
    final characterName = settingsService.characterName;

    return Scaffold(
      appBar: AppBar(
        title: Text(_greeting),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 26),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, size: 26),
            onPressed: () {
              _showInfoDialog(context);
            },
          ),
          const SizedBox(width: 10),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  todayDate.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EditTasksPage()),
          );
        },
        tooltip: 'Edit Tasks & Habits',
        child: const Icon(Icons.edit_note_outlined),
        mini: true,
      ),

      body: ValueListenableBuilder(
        valueListenable: taskBox.listenable(),
        builder: (context, Box<Task> box, _) {

          final allTasks = box.values.toList().cast<Task>();
          final allHabits = allTasks.where((task) => task.isHabit).toList();
          final studyHabits = allHabits.where((task) => task.category == 'Studies').toList();
          final personalHabits = allHabits.where((task) => task.category == 'Personal Care').toList();
          final openTodos = allTasks.where(
                  (task) => !task.isHabit && !task.isDone
          ).toList();
          final completedHabits = allHabits.where((task) => isCompletedToday(task.completionHistory)).length;
          final totalHabits = allHabits.length;

          final String quote = _getQuote(completedHabits, totalHabits);

          if (studyHabits.isEmpty && personalHabits.isEmpty && openTodos.isEmpty && !_isBirthday) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSummaryCard(0, 0, context, quote),
                  const SizedBox(height: 20),
                  Text(
                    'All clear for today!',
                    style: TextStyle(fontSize: 22, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Tap the "+" button to add a task or habit.',
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Padding for FAB
            children: [
              if (_isBirthday) _buildBirthdayCard(context),
              if (_isBirthday) const SizedBox(height: 24),

              _buildSummaryCard(completedHabits, totalHabits, context, quote),
              const SizedBox(height: 24),

              // Character card is removed

              _buildTaskSection('Studies', Icons.menu_book, studyHabits, context, true),
              const SizedBox(height: 24),

              _buildTaskSection('Personal Care', Icons.spa, personalHabits, context, true),
              const SizedBox(height: 24),

              _buildTaskSection('My To-Do List', Icons.checklist_rtl, openTodos, context, false),

              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  // --- BIRTHDAY CARD WIDGET ---
  Widget _buildBirthdayCard(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.pink.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.pink.shade200, width: 2),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cake_rounded, color: Colors.pink, size: 32),
            SizedBox(width: 16),
            Text(
              'Happy Birthday!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SUMMARY CARD WIDGET (REDESIGNED) ---
  Widget _buildSummaryCard(int completed, int total, BuildContext context, String quote) {
    double percent = total == 0 ? 0 : completed / total;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: percent),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOutCubic,
      builder: (context, value, child) {
        return Card(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // --- PROGRESS CIRCLE ---
                SizedBox(
                  width: 70,
                  height: 70,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: 1.0,
                        color: Theme.of(context).dividerColor,
                        strokeWidth: 8,
                      ),
                      CircularProgressIndicator(
                        value: value,
                        color: Colors.green,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                      ),
                      Center(
                        child: Text(
                          '${(value * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // --- TEXT AND QUOTE ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Habit Progress',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completed of $total habits completed today',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Divider(height: 20),
                      // --- THE QUOTE IS NOW HERE ---
                      Text(
                        '"$quote"',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- TASK SECTION BUILDER ---
  Widget _buildTaskSection(String title, IconData icon, List<Task> tasks, BuildContext context, bool isHabitList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(width: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0),
            child: Text(
              isHabitList ? 'No habits in this category.' : 'No open todos!',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
            ),
          )
        else
          Column(
            children: tasks.map((task) {
              bool isDone = isHabitList ? isCompletedToday(task.completionHistory) : task.isDone;

              return AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: isHabitList ? 1.0 : (isDone ? 0.0 : 1.0),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    height: (isHabitList == false && isDone) ? 0 : null,
                    child: AnimatedTaskTile(
                      task: task,
                      isHabit: isHabitList,
                      isDone: isDone,
                      onTap: () => _toggleTask(task, isHabitList),
                      onLongPress: () => _confirmDelete(task),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // --- DYNAMIC QUOTE GETTER ---
  final Map<int, String> _quotes = {
    0: "A new day! Let's get the first task done.",
    10: "Keep the momentum!",
    20: "You're on a roll!",
    50: "You're more than halfway there!",
    100: "Amazing! You've completed all your habits!",
  };

  String _getQuote(int completed, int total) {
    if (total == 0) {
      return "Let's get started! Add a new habit or todo.";
    }

    double percent = completed / total;
    int percentKey = ((percent * 100) / 10).floor() * 10;
    while (percentKey >= 0) {
      if (_quotes.containsKey(percentKey)) {
        return _quotes[percentKey]!;
      }
      percentKey -= 10;
    }

    return "Let's do this!";
  }
}
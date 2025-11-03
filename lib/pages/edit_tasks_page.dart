import 'package:flutter/material.dart';
import 'package:get_up/models/task.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../widgets/add_task_modal.dart';
import 'settings_page.dart';
import 'package:get_up/main.dart'; // <-- 1. IMPORT main.dart

class EditTasksPage extends StatefulWidget {
  const EditTasksPage({super.key});

  @override
  State<EditTasksPage> createState() => _EditTasksPageState();
}

class _EditTasksPageState extends State<EditTasksPage> with SingleTickerProviderStateMixin {
  final Box<Task> taskBox = Hive.box<Task>('tasks');
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleTaskStatus(Task task) {
    if (!task.isHabit) {
      setState(() {
        task.isDone = !task.isDone;
        task.save();
      });
    }
  }

  // --- 2. UPDATED DELETE FUNCTION ---
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
      // --- CANCEL NOTIFICATION ---
      await notificationService.cancelNotification(task);
      // ---
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
  // --- END UPDATE ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Studies', icon: Icon(Icons.menu_book)),
            Tab(text: 'Personal Care', icon: Icon(Icons.spa)),
            Tab(text: 'Todos', icon: Icon(Icons.checklist)),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          String currentCategory;
          if (_tabController.index == 0) {
            currentCategory = 'Studies';
          } else if (_tabController.index == 1) {
            currentCategory = 'Personal Care';
          } else {
            currentCategory = 'Todo';
          }

          showAddTaskModal(context, initialCategory: currentCategory);
        },
        label: const Text('Add Item'),
        icon: const Icon(Icons.add),
      ),

      body: ValueListenableBuilder(
        valueListenable: taskBox.listenable(),
        builder: (context, Box<Task> box, _) {
          final allTasks = box.values.toList().cast<Task>();

          final studyHabits = allTasks.where((t) => t.isHabit && t.category == 'Studies').toList();
          final personalHabits = allTasks.where((t) => t.isHabit && t.category == 'Personal Care').toList();
          final allTodos = allTasks.where((t) => !t.isHabit).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTaskList(studyHabits, 'Studies'),
              _buildTaskList(personalHabits, 'Personal Care'),
              _buildTaskList(allTodos, 'Todos'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, String categoryName) {
    if (tasks.isEmpty) {
      return Center(
        child: Text(
          'No items in "$categoryName" yet.',
          style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    tasks.sort((a, b) {
      if (a.isDone != b.isDone) {
        return a.isDone ? 1 : -1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });


    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskTile(task, context);
      },
    );
  }

  Widget _buildTaskTile(Task task, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        onTap: () => _toggleTaskStatus(task),
        leading: Icon(
          task.isHabit ? Icons.all_inclusive : (task.isDone ? Icons.check_circle : Icons.circle_outlined),
          color: task.isDone ? Colors.green : Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isHabit ? TextDecoration.none : (task.isDone ? TextDecoration.lineThrough : TextDecoration.none),
            color: task.isDone
                ? Theme.of(context).colorScheme.onSurface.withAlpha(128)
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          task.isHabit
              ? 'Daily Habit'
              : 'Added: ${DateFormat.yMd().format(task.createdAt)}',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => _confirmDelete(task),
        ),
      ),
    );
  }
}
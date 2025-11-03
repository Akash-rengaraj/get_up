import 'package:flutter/material.dart';
import 'package:get_up/models/task.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; 

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
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

  // --- Helper to show confirmation dialog ---
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tasks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Studies', icon: Icon(Icons.menu_book)),
            Tab(text: 'Personal Care', icon: Icon(Icons.spa)),
            Tab(text: 'Todos', icon: Icon(Icons.checklist)),
          ],
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: taskBox.listenable(),
        builder: (context, Box<Task> box, _) {
          final allTasks = box.values.toList().cast<Task>();
          
          // Filter for each tab
          final studyHabits = allTasks.where((t) => t.isHabit && t.category == 'Studies').toList();
          final personalHabits = allTasks.where((t) => t.isHabit && t.category == 'Personal Care').toList();
          final allTodos = allTasks.where((t) => !t.isHabit).toList(); // category == 'Todo'

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

  // A reusable widget to build the list for each tab
  Widget _buildTaskList(List<Task> tasks, String categoryName) {
    if (tasks.isEmpty) {
      return Center(
        child: Text(
          'No items in "$categoryName" yet.',
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }
    
    // Sort by creation date
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskTile(task, context);
      },
    );
  }

  // Master list task tile (includes date and delete)
  Widget _buildTaskTile(Task task, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        leading: Icon(
          task.isHabit ? Icons.all_inclusive : (task.isDone ? Icons.check_circle : Icons.circle_outlined),
          color: task.isDone ? Colors.green : Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isHabit ? TextDecoration.none : (task.isDone ? TextDecoration.lineThrough : TextDecoration.none),
            color: task.isDone ? Colors.grey[500] : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(task.isHabit
            ? 'Daily Habit'
            : 'Added: ${DateFormat.yMd().format(task.createdAt)}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => _confirmDelete(task),
        ),
      ),
    );
  }
}
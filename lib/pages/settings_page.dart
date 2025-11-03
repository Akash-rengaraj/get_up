import 'package:flutter/material.dart';
import 'package:get_up/models/debt.dart';
import 'package:get_up/models/task.dart';
import 'package:get_up/models/transaction.dart';
import 'package:get_up/models/attendance_day.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showFlushDialog(BuildContext context, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Flush all $type data?'),
        content: Text(
          'This will permanently delete ALL $type history. This action CANNOT be undone.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.shade900,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (type == 'progress') {
                await _flushProgressData();
              } else if (type == 'money') {
                await _flushMoneyData();
              } else if (type == 'attendance') {
                await _flushAttendanceData();
              }
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('All $type data has been flushed.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Flush Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _flushProgressData() async {
    final taskBox = Hive.box<Task>('tasks');
    List<Task> tasksToDelete = [];

    for (var task in taskBox.values) {
      if (!task.isHabit && task.isDone) {
        tasksToDelete.add(task);
      } else if (task.isHabit) {
        task.completionHistory.clear();
        await task.save();
      }
    }
    for (var task in tasksToDelete) {
      await task.delete();
    }
  }

  Future<void> _flushMoneyData() async {
    await Hive.box<Transaction>('transactions').clear();
    await Hive.box<Debt>('debts').clear();
  }

  Future<void> _flushAttendanceData() async {
    await Hive.box<AttendanceDay>('attendance').clear();
    await Hive.box('attendance_settings').clear(); // Also clear the settings
  }

  void _showEditInfoDialog(BuildContext context, SettingsService settings) {
    final nameController = TextEditingController(text: settings.userName);
    final dobController = TextEditingController(text: settings.userDOB);
    DateTime? selectedDate = settings.userDOB != null && settings.userDOB!.isNotEmpty
        ? DateTime.parse(settings.userDOB!)
        : null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Personal Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dobController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
                onTap: () async {
                  final now = DateTime.now();
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime(now.year - 20, now.month, now.day),
                    firstDate: DateTime(1900),
                    lastDate: now,
                  );
                  if (pickedDate != null) {
                    selectedDate = pickedDate;
                    dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && dobController.text.isNotEmpty) {
                  context.read<SettingsService>().savePersonalInfo(
                    nameController.text,
                    dobController.text,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = context.watch<SettingsService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- "MANAGE TASKS" BUTTON IS REMOVED FROM HERE ---

          Text(
            'PERSONAL INFO',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Your Info'),
            subtitle: Text(
              '${settingsService.userName ?? "No name set"}\n${settingsService.userDOB ?? "No birthday set"}',
            ),
            trailing: const Icon(Icons.edit),
            onTap: () => _showEditInfoDialog(context, settingsService),
          ),

          const Divider(height: 16),

          Text(
            'APPEARANCE',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark theme'),
            value: settingsService.isDarkMode,
            onChanged: (bool value) {
              context.read<SettingsService>().setTheme(value);
            },
            secondary: Icon(
                settingsService.isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Choose Your Companion',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Wrap(
              spacing: 8.0,
              children: [
                _buildCharacterChip('Fox', 'assets/images/logo.png', settingsService, context), // Default
                _buildCharacterChip('Boxer', 'assets/images/bear.png', settingsService, context),
                _buildCharacterChip('Mike', 'assets/images/mike.png', settingsService, context),
              ],
            ),
          ),
          const Divider(height: 32),

          Text(
            'DATA MANAGEMENT',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Auto-delete old progress'),
            subtitle: const Text('Automatically delete habit/todo data older than 12 months on app start.'),
            value: settingsService.autoDeleteProgress,
            onChanged: (bool value) {
              context.read<SettingsService>().setAutoDeleteProgress(value);
            },
          ),
          SwitchListTile(
            title: const Text('Auto-delete old money data'),
            subtitle: const Text('Automatically delete transaction/debt data older than 12 months on app start.'),
            value: settingsService.autoDeleteMoney,
            onChanged: (bool value) {
              context.read<SettingsService>().setAutoDeleteMoney(value);
            },
          ),

          const Divider(height: 32),

          Text(
            'DANGER ZONE',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Flush All Progress Data',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('Delete all completed todos and clear all habit completion history.'),
            onTap: () => _showFlushDialog(context, 'progress'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Flush All Money Data',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('Delete all transactions, incomes, and debts.'),
            onTap: () => _showFlushDialog(context, 'money'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Flush All Attendance Data',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('Delete all attendance history and settings.'),
            onTap: () => _showFlushDialog(context, 'attendance'),
          ),

          const Divider(height: 32),

          Text(
            'ABOUT',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.code),
            title: Text('Developed by Johan'),
            subtitle: Text('App Version 1.0.0'),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterChip(String name, String imagePath, SettingsService settings, BuildContext context) {
    final bool isSelected = settings.characterName == name;

    return FilterChip(
      label: Text(name),
      selected: isSelected,
      avatar: CircleAvatar(
        radius: 12,
        backgroundImage: AssetImage(imagePath),
        backgroundColor: Colors.transparent,
      ),
      onSelected: (bool selected) {
        if (selected) {
          context.read<SettingsService>().setCharacter(name);
        }
      },
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
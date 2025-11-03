import 'package:flutter/material.dart';
import 'package:get_up/models/task.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:get_up/main.dart'; // Import main.dart to get notificationService

void showAddTaskModal(BuildContext context, {String? initialCategory}) {
  final taskBox = Hive.box<Task>('tasks');
  final taskController = TextEditingController();

  // --- NEW STATE FOR THE MODAL ---
  String selectedCategory = initialCategory ?? 'Todo';
  TimeOfDay? reminderTime; // For Habits
  TimeOfDay? dueTime; // For Habits
  DateTime? reminderDateTime; // For Todos
  DateTime? dueDateTime; // For Todos
  // --- END NEW STATE ---

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {

          bool isHabit = (selectedCategory == 'Studies' || selectedCategory == 'Personal Care');
          final theme = Theme.of(context);
          final colors = theme.colorScheme;
          final textTheme = theme.textTheme;

          // --- NEW HELPER FUNCTIONS ---
          Future<void> _pickHabitTime(bool isReminder) async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (picked != null) {
              setModalState(() {
                if (isReminder) {
                  reminderTime = picked;
                } else {
                  dueTime = picked;
                }
              });
            }
          }

          Future<void> _pickTodoDateTime(bool isReminder) async {
            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2101),
            );

            if (pickedDate == null) return; // User cancelled date picker

            final TimeOfDay? pickedTime = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );

            if (pickedTime == null) return; // User cancelled time picker

            final fullDateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );

            setModalState(() {
              if (isReminder) {
                reminderDateTime = fullDateTime;
              } else {
                dueDateTime = fullDateTime;
              }
            });
          }
          // --- END NEW HELPERS ---

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Add a New Item',
                      style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(' SELECT TYPE', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    style: SegmentedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: 'Studies',
                        label: Text('Habit: Studies'),
                        icon: Icon(Icons.menu_book),
                      ),
                      ButtonSegment(
                        value: 'Personal Care',
                        label: Text('Habit: Personal'),
                        icon: Icon(Icons.spa),
                      ),
                      ButtonSegment(
                        value: 'Todo',
                        label: Text('One-Time Todo'),
                        icon: Icon(Icons.check_box_outline_blank),
                      ),
                    ],
                    selected: {selectedCategory},
                    onSelectionChanged: (Set<String> newSelection) {
                      setModalState(() {
                        selectedCategory = newSelection.first;
                        // Reset dates/times when type changes
                        reminderTime = null;
                        dueTime = null;
                        reminderDateTime = null;
                        dueDateTime = null;
                      });
                    },
                  ),

                  const SizedBox(height: 20),
                  const Text(' TASK TITLE', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: taskController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: isHabit ? 'e.g., Workout' : 'e.g., Buy groceries',
                      border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12))
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- NEW DATE/TIME PICKERS ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeChip(
                          context: context,
                          label: 'Set Reminder',
                          time: isHabit ? reminderTime : reminderDateTime,
                          onTap: () => isHabit ? _pickHabitTime(true) : _pickTodoDateTime(true),
                          onClear: () => setModalState(() {
                            reminderTime = null;
                            reminderDateTime = null;
                          }),
                          isHabit: isHabit,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTimeChip(
                          context: context,
                          label: 'Set Due Date',
                          time: isHabit ? dueTime : dueDateTime,
                          onTap: () => isHabit ? _pickHabitTime(false) : _pickTodoDateTime(false),
                          onClear: () => setModalState(() {
                            dueTime = null;
                            dueDateTime = null;
                          }),
                          isHabit: isHabit,
                        ),
                      ),
                    ],
                  ),
                  // --- END NEW PICKERS ---

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save Task'),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                          )
                      ),
                      onPressed: () async {
                        if (taskController.text.isNotEmpty) {
                          final newTask = Task(
                            title: taskController.text,
                            createdAt: DateTime.now(),
                            isDone: false,
                            isHabit: isHabit,
                            category: selectedCategory,
                            completionHistory: [],
                            // --- SAVE NEW DATA ---
                            reminderTime: isHabit ? reminderTime?.format(context) : null,
                            dueTime: isHabit ? dueTime?.format(context) : null,
                            reminderDateTime: isHabit ? null : reminderDateTime,
                            dueDateTime: isHabit ? null : dueDateTime,
                          );

                          // Save to box
                          await taskBox.add(newTask);

                          // --- SCHEDULE NOTIFICATIONS ---
                          if (newTask.isHabit) {
                            notificationService.scheduleHabitNotification(newTask);
                          } else {
                            notificationService.scheduleTodoNotification(newTask);
                          }

                          Navigator.pop(context); // Close the modal
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// --- NEW HELPER WIDGET FOR THE TIME CHIPS ---
Widget _buildTimeChip({
  required BuildContext context,
  required String label,
  required dynamic time, // Can be TimeOfDay or DateTime
  required VoidCallback onTap,
  required VoidCallback onClear,
  required bool isHabit,
}) {
  String displayText;
  if (time == null) {
    displayText = label;
  } else if (isHabit && time is TimeOfDay) {
    displayText = time.format(context);
  } else if (!isHabit && time is DateTime) {
    displayText = DateFormat('MMM d, h:mm a').format(time);
  } else {
    displayText = label;
  }

  return InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: time != null ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isHabit ? Icons.access_time : Icons.calendar_today,
            size: 18,
            color: time != null ? Theme.of(context).colorScheme.primary : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayText,
              style: TextStyle(
                fontWeight: time != null ? FontWeight.bold : FontWeight.normal,
                color: time != null ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (time != null)
            InkWell(
              onTap: onClear,
              child: const Icon(Icons.close, size: 18, color: Colors.grey),
            ),
        ],
      ),
    ),
  );
}
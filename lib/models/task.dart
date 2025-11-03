import 'package:hive/hive.dart';

part 'task.g.dart'; // This file is auto-generated

@HiveType(typeId: 0)
class Task extends HiveObject {

  @HiveField(0)
  String title;

  @HiveField(1)
  bool isDone; // For Todos

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  String category; // "Studies", "Personal Care", or "Todo"

  @HiveField(4)
  bool isHabit; // Is this a daily habit or a one-time todo?

  @HiveField(5)
  List<DateTime> completionHistory;

  // --- NEW FIELDS FOR NOTIFICATIONS ---
  @HiveField(6)
  String? reminderTime; // For Habits, stored as "HH:mm" (e.g., "17:30")

  @HiveField(7)
  String? dueTime; // For Habits, stored as "HH:mm"

  @HiveField(8)
  DateTime? reminderDateTime; // For Todos

  @HiveField(9)
  DateTime? dueDateTime; // For Todos
  // --- END NEW FIELDS ---


  Task({
    required this.title,
    this.isDone = false,
    required this.createdAt,
    required this.category,
    required this.isHabit,
    List<DateTime>? completionHistory,
    // Add new fields to constructor
    this.reminderTime,
    this.dueTime,
    this.reminderDateTime,
    this.dueDateTime,
  }) : completionHistory = completionHistory ?? [];
}
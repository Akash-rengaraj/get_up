import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:get_up/models/task.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  int _getNotificationId(Task task) {
    return task.key as int? ?? task.hashCode;
  }

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    tz.initializeTimeZones();

    // --- THIS IS THE FIX for flutter_timezone: ^1.0.0 ---
    // The old version returns a String, not an object.
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    // --- END FIX ---

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleTodoNotification(Task task) async {
    if (task.reminderDateTime == null) return;
    final id = _getNotificationId(task);
    if (task.reminderDateTime!.isBefore(DateTime.now())) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Task Reminder',
      task.title,
      tz.TZDateTime.from(task.reminderDateTime!, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_channel_id',
          'Task Reminders',
          channelDescription: 'Reminders for your Todos',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      // --- THIS IS THE FIX for flutter_local_notifications: ^16.3.0 ---
      // This parameter belongs here for this version.
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      // --- END FIX ---
    );
  }

  Future<void> scheduleHabitNotification(Task task) async {
    if (task.reminderTime == null) return;
    final id = _getNotificationId(task);

    final parts = task.reminderTime!.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Habit Reminder',
      task.title,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_channel_id',
          'Habit Reminders',
          channelDescription: 'Daily reminders for your habits',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      // --- THIS IS THE FIX for flutter_local_notifications: ^16.3.0 ---
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      // --- END FIX ---

      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelNotification(Task task) async {
    final id = _getNotificationId(task);
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
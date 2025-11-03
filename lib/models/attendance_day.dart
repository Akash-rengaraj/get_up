import 'package:hive/hive.dart';

part 'attendance_day.g.dart'; // This will be generated

@HiveType(typeId: 4)
enum AttendanceStatus {
  @HiveField(0)
  present,

  @HiveField(1)
  halfDay,

  @HiveField(2)
  absent,

  @HiveField(3)
  holiday,

  @HiveField(4)
  onDuty,

  @HiveField(5)
  none // Default for an empty day
}

@HiveType(typeId: 3)
class AttendanceDay extends HiveObject {

  @HiveField(0)
  String dateKey;

  @HiveField(1)
  AttendanceStatus status;

  AttendanceDay({
    required this.dateKey,
    required this.status,
  });
}
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_day.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceDayAdapter extends TypeAdapter<AttendanceDay> {
  @override
  final int typeId = 3;

  @override
  AttendanceDay read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttendanceDay(
      dateKey: fields[0] as String,
      status: fields[1] as AttendanceStatus,
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceDay obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.dateKey)
      ..writeByte(1)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceDayAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AttendanceStatusAdapter extends TypeAdapter<AttendanceStatus> {
  @override
  final int typeId = 4;

  @override
  AttendanceStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AttendanceStatus.present;
      case 1:
        return AttendanceStatus.halfDay;
      case 2:
        return AttendanceStatus.absent;
      case 3:
        return AttendanceStatus.holiday;
      case 4:
        return AttendanceStatus.onDuty;
      case 5:
        return AttendanceStatus.none;
      default:
        return AttendanceStatus.present;
    }
  }

  @override
  void write(BinaryWriter writer, AttendanceStatus obj) {
    switch (obj) {
      case AttendanceStatus.present:
        writer.writeByte(0);
        break;
      case AttendanceStatus.halfDay:
        writer.writeByte(1);
        break;
      case AttendanceStatus.absent:
        writer.writeByte(2);
        break;
      case AttendanceStatus.holiday:
        writer.writeByte(3);
        break;
      case AttendanceStatus.onDuty:
        writer.writeByte(4);
        break;
      case AttendanceStatus.none:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

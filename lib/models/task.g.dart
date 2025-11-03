// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      title: fields[0] as String,
      isDone: fields[1] as bool,
      createdAt: fields[2] as DateTime,
      category: fields[3] as String,
      isHabit: fields[4] as bool,
      completionHistory: (fields[5] as List?)?.cast<DateTime>(),
      reminderTime: fields[6] as String?,
      dueTime: fields[7] as String?,
      reminderDateTime: fields[8] as DateTime?,
      dueDateTime: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.isDone)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.isHabit)
      ..writeByte(5)
      ..write(obj.completionHistory)
      ..writeByte(6)
      ..write(obj.reminderTime)
      ..writeByte(7)
      ..write(obj.dueTime)
      ..writeByte(8)
      ..write(obj.reminderDateTime)
      ..writeByte(9)
      ..write(obj.dueDateTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

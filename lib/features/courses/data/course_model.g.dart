// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CourseAdapter extends TypeAdapter<Course> {
  @override
  final int typeId = 0;

  @override
  Course read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Course(
      id: fields[0] as String,
      title: fields[1] as String,
      totalDurationMinutes: fields[2] as int,
      totalSections: fields[3] as int,
      dailyStudyMinutes: fields[4] as int,
      startDate: fields[5] as DateTime,
      totalDays: fields[8] as int,
      completedMinutes: fields[6] as int,
      streak: fields[7] as int,
      todayCompletedMinutes: fields[9] as int,
      lastStudyDate: fields[10] as DateTime?,
      targetDate: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Course obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.totalDurationMinutes)
      ..writeByte(3)
      ..write(obj.totalSections)
      ..writeByte(4)
      ..write(obj.dailyStudyMinutes)
      ..writeByte(5)
      ..write(obj.startDate)
      ..writeByte(6)
      ..write(obj.completedMinutes)
      ..writeByte(7)
      ..write(obj.streak)
      ..writeByte(8)
      ..write(obj.totalDays)
      ..writeByte(9)
      ..write(obj.todayCompletedMinutes)
      ..writeByte(10)
      ..write(obj.lastStudyDate)
      ..writeByte(11)
      ..write(obj.targetDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

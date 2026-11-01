// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_session_model.dart';

class StudySessionAdapter extends TypeAdapter<StudySession> {
  @override
  final int typeId = 1;

  @override
  StudySession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int index = 0; index < numOfFields; index++)
        reader.readByte(): reader.read(),
    };

    return StudySession(
      id: fields[0] as String,
      courseId: fields[1] as String,
      startedAt: fields[2] as DateTime,
      endedAt: fields[3] as DateTime,
      durationMinutes: fields[4] as int,
      source: StudySessionSource.fromStorage(fields[5] as String),
    );
  }

  @override
  void write(BinaryWriter writer, StudySession object) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(object.id)
      ..writeByte(1)
      ..write(object.courseId)
      ..writeByte(2)
      ..write(object.startedAt)
      ..writeByte(3)
      ..write(object.endedAt)
      ..writeByte(4)
      ..write(object.durationMinutes)
      ..writeByte(5)
      ..write(object.source.storageValue);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is StudySessionAdapter;

  @override
  int get hashCode => typeId.hashCode;
}

import 'package:hive/hive.dart';

part 'study_session_model.g.dart';

enum StudySessionSource {
  timer,
  quickAdd,
  planner,
  manual;

  String get storageValue => switch (this) {
    StudySessionSource.timer => 'timer',
    StudySessionSource.quickAdd => 'quickAdd',
    StudySessionSource.planner => 'planner',
    StudySessionSource.manual => 'manual',
  };

  static StudySessionSource fromStorage(String value) => switch (value) {
    'timer' => StudySessionSource.timer,
    'quickAdd' => StudySessionSource.quickAdd,
    'planner' => StudySessionSource.planner,
    'manual' => StudySessionSource.manual,
    _ => StudySessionSource.manual,
  };
}

@HiveType(typeId: 1)
class StudySession {
  const StudySession({
    required this.id,
    required this.courseId,
    required this.startedAt,
    required this.endedAt,
    required this.durationMinutes,
    required this.source,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String courseId;

  @HiveField(2)
  final DateTime startedAt;

  @HiveField(3)
  final DateTime endedAt;

  @HiveField(4)
  final int durationMinutes;

  /// Stored as a stable string in Hive rather than an enum index.
  @HiveField(5)
  final StudySessionSource source;
}

import 'package:hive/hive.dart';

part 'course_model.g.dart';

@HiveType(typeId: 0)
class Course extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  int totalDurationMinutes;

  @HiveField(3)
  int totalSections;

  @HiveField(4)
  int dailyStudyMinutes;

  @HiveField(5)
  DateTime startDate;

  @HiveField(6)
  int completedMinutes;

  @HiveField(7)
  int streak;

  // ✅ NEW FIELDS (for planner + tracking)

  @HiveField(8)
  int totalDays;

  @HiveField(9)
  int todayCompletedMinutes;

  @HiveField(10)
  DateTime? lastStudyDate;

  /// Optional explicit completion goal. Legacy courses derive an effective
  /// target date from startDate and totalDays when this is null.
  @HiveField(11)
  DateTime? targetDate;

  Course({
    required this.id,
    required this.title,
    required this.totalDurationMinutes,
    required this.totalSections,
    required this.dailyStudyMinutes,
    required this.startDate,
    required this.totalDays, // ✅ NEW REQUIRED

    this.completedMinutes = 0,
    this.streak = 0,

    this.todayCompletedMinutes = 0, // ✅ NEW
    this.lastStudyDate, // ✅ NEW
    this.targetDate,
  });
}

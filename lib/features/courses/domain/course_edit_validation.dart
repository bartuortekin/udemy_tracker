import '../../../core/utils/course_progress.dart';

List<String> validateCourseEdit({
  required String title,
  required int? totalDurationMinutes,
  required int? totalSections,
  required int completedMinutes,
  required DateTime startDate,
  required DateTime? targetDate,
}) {
  final errors = <String>[];
  if (title.trim().isEmpty) {
    errors.add('Course title cannot be empty.');
  }
  if (totalDurationMinutes == null || totalDurationMinutes <= 0) {
    errors.add('Total duration must be greater than zero.');
  } else if (totalDurationMinutes < completedMinutes) {
    errors.add('Total duration cannot be below completed progress.');
  }
  if (totalSections == null || totalSections <= 0) {
    errors.add('Total sections must be greater than zero.');
  }
  if (targetDate != null && calendarDayDifference(startDate, targetDate) < 0) {
    errors.add('Target date cannot be before the start date.');
  }
  return errors;
}

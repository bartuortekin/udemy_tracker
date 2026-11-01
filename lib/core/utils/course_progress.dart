import '../../features/courses/data/course_model.dart';

/// Returns whether [first] and [second] fall on the same local calendar day.
bool isSameCalendarDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

/// Returns the number of local calendar-day boundaries from [from] to [to].
int calendarDayDifference(DateTime from, DateTime to) {
  final fromDay = DateTime(from.year, from.month, from.day);
  final toDay = DateTime(to.year, to.month, to.day);
  return toDay.difference(fromDay).inDays;
}

/// Returns the recorded minutes for [date], treating a previous day's value as
/// zero until the next positive study update persists the reset.
int todayCompletedMinutesFor(Course course, DateTime date) {
  final lastStudyDate = course.lastStudyDate;
  if (lastStudyDate == null || !isSameCalendarDay(lastStudyDate, date)) {
    return 0;
  }

  final totalMinutes = course.totalDurationMinutes < 0
      ? 0
      : course.totalDurationMinutes;
  return course.todayCompletedMinutes.clamp(0, totalMinutes).toInt();
}

class ProgressUpdate {
  const ProgressUpdate({
    required this.recordedMinutes,
    required this.didChange,
  });

  final int recordedMinutes;
  final bool didChange;
}

/// Records up to [requestedMinutes] of study time without allowing a course
/// to exceed its total duration. A positive study update also consistently
/// refreshes today's total and streak.
ProgressUpdate recordStudyProgress({
  required Course course,
  required int requestedMinutes,
  required DateTime studiedAt,
}) {
  if (requestedMinutes <= 0) {
    return const ProgressUpdate(recordedMinutes: 0, didChange: false);
  }

  final totalMinutes = course.totalDurationMinutes < 0
      ? 0
      : course.totalDurationMinutes;
  final normalizedCompleted = course.completedMinutes
      .clamp(0, totalMinutes)
      .toInt();
  final normalizedToday = course.todayCompletedMinutes
      .clamp(0, totalMinutes)
      .toInt();
  var didChange =
      normalizedCompleted != course.completedMinutes ||
      normalizedToday != course.todayCompletedMinutes;

  course.completedMinutes = normalizedCompleted;
  course.todayCompletedMinutes = normalizedToday;

  final recordedMinutes = (totalMinutes - normalizedCompleted)
      .clamp(0, requestedMinutes)
      .toInt();

  if (recordedMinutes == 0) {
    return ProgressUpdate(recordedMinutes: 0, didChange: didChange);
  }

  if (course.lastStudyDate == null ||
      !isSameCalendarDay(course.lastStudyDate!, studiedAt)) {
    course.todayCompletedMinutes = 0;
  }

  final previousStudyDate = course.lastStudyDate;
  if (previousStudyDate == null) {
    course.streak = 1;
  } else {
    final elapsedDays = calendarDayDifference(previousStudyDate, studiedAt);
    if (elapsedDays == 1) {
      course.streak = course.streak < 1 ? 1 : course.streak + 1;
    } else if (elapsedDays != 0) {
      course.streak = 1;
    }
  }

  course.completedMinutes += recordedMinutes;
  course.todayCompletedMinutes =
      (course.todayCompletedMinutes + recordedMinutes)
          .clamp(0, totalMinutes)
          .toInt();
  course.lastStudyDate = studiedAt;
  didChange = true;

  return ProgressUpdate(recordedMinutes: recordedMinutes, didChange: didChange);
}

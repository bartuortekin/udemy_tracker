import '../../../core/utils/course_progress.dart';
import 'study_session_model.dart';

int totalStudyMinutes(Iterable<StudySession> sessions) {
  return sessions.fold(0, (total, session) => total + session.durationMinutes);
}

int studyMinutesToday(Iterable<StudySession> sessions, DateTime now) {
  return sessions
      .where((session) => isSameCalendarDay(session.endedAt, now))
      .fold(0, (total, session) => total + session.durationMinutes);
}

/// Includes today and the preceding six local calendar days.
int studyMinutesInLast7CalendarDays(
  Iterable<StudySession> sessions,
  DateTime now,
) {
  final today = DateTime(now.year, now.month, now.day);
  final firstDay = today.subtract(const Duration(days: 6));

  return sessions
      .where((session) {
        final sessionDay = DateTime(
          session.endedAt.year,
          session.endedAt.month,
          session.endedAt.day,
        );
        return !sessionDay.isBefore(firstDay) && !sessionDay.isAfter(today);
      })
      .fold(0, (total, session) => total + session.durationMinutes);
}

/// Counts consecutive local study dates ending today, or yesterday when the
/// learner has not studied today. A study date needs one positive session.
int currentStudyStreak(Iterable<StudySession> sessions, DateTime now) {
  final studyDays = <DateTime>{
    for (final session in sessions)
      if (session.durationMinutes > 0)
        DateTime(
          session.endedAt.year,
          session.endedAt.month,
          session.endedAt.day,
        ),
  };
  final today = DateTime(now.year, now.month, now.day);
  var currentDay = studyDays.contains(today)
      ? today
      : today.subtract(const Duration(days: 1));
  var streak = 0;

  while (studyDays.contains(currentDay)) {
    streak++;
    currentDay = currentDay.subtract(const Duration(days: 1));
  }
  return streak;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:udemy_tracker/core/utils/course_progress.dart';
import 'package:udemy_tracker/features/courses/data/course_model.dart';

Course createCourse({
  int totalMinutes = 120,
  int completedMinutes = 0,
  int todayCompletedMinutes = 0,
  int streak = 0,
  DateTime? lastStudyDate,
}) {
  return Course(
    id: 'course-1',
    title: 'Test course',
    totalDurationMinutes: totalMinutes,
    totalSections: 1,
    dailyStudyMinutes: 30,
    startDate: DateTime(2026, 1, 1),
    totalDays: 4,
    completedMinutes: completedMinutes,
    todayCompletedMinutes: todayCompletedMinutes,
    streak: streak,
    lastStudyDate: lastStudyDate,
  );
}

void main() {
  group('calendar-day utilities', () {
    test('compare the full calendar date', () {
      expect(
        isSameCalendarDay(DateTime(2026, 1, 5), DateTime(2026, 2, 5)),
        isFalse,
      );
      expect(
        isSameCalendarDay(DateTime(2026, 2, 5, 8), DateTime(2026, 2, 5, 22)),
        isTrue,
      );
    });

    test('does not show a previous day as today progress', () {
      final course = createCourse(
        todayCompletedMinutes: 30,
        lastStudyDate: DateTime(2026, 1, 5),
      );

      expect(todayCompletedMinutesFor(course, DateTime(2026, 2, 5)), 0);
    });
  });

  group('recordStudyProgress', () {
    test('caps progress at the course duration', () {
      final course = createCourse(totalMinutes: 100, completedMinutes: 85);

      final update = recordStudyProgress(
        course: course,
        requestedMinutes: 30,
        studiedAt: DateTime(2026, 2, 5),
      );

      expect(update.recordedMinutes, 15);
      expect(course.completedMinutes, 100);
      expect(course.todayCompletedMinutes, 15);
    });

    test('resets today total when recording study on a new date', () {
      final course = createCourse(
        todayCompletedMinutes: 25,
        lastStudyDate: DateTime(2026, 1, 5, 20),
        streak: 2,
      );

      recordStudyProgress(
        course: course,
        requestedMinutes: 10,
        studiedAt: DateTime(2026, 2, 5, 9),
      );

      expect(course.todayCompletedMinutes, 10);
      expect(course.streak, 1);
    });

    test('updates streak only for consecutive calendar days', () {
      final course = createCourse(
        streak: 3,
        lastStudyDate: DateTime(2026, 2, 5),
      );

      recordStudyProgress(
        course: course,
        requestedMinutes: 10,
        studiedAt: DateTime(2026, 2, 6),
      );
      expect(course.streak, 4);

      recordStudyProgress(
        course: course,
        requestedMinutes: 10,
        studiedAt: DateTime(2026, 2, 6, 18),
      );
      expect(course.streak, 4);

      recordStudyProgress(
        course: course,
        requestedMinutes: 10,
        studiedAt: DateTime(2026, 2, 8),
      );
      expect(course.streak, 1);
    });

    test('does not alter date or streak for zero minutes', () {
      final lastStudyDate = DateTime(2026, 2, 5);
      final course = createCourse(streak: 3, lastStudyDate: lastStudyDate);

      final update = recordStudyProgress(
        course: course,
        requestedMinutes: 0,
        studiedAt: DateTime(2026, 2, 8),
      );

      expect(update.didChange, isFalse);
      expect(course.streak, 3);
      expect(course.lastStudyDate, lastStudyDate);
    });
  });
}

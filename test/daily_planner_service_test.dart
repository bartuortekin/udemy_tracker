import 'package:flutter_test/flutter_test.dart';
import 'package:udemy_tracker/features/courses/data/course_model.dart';
import 'package:udemy_tracker/features/courses/domain/course_edit_validation.dart';
import 'package:udemy_tracker/features/planner/domain/daily_planner_service.dart';

Course createCourse({
  required String id,
  int totalMinutes = 100,
  int completedMinutes = 0,
  DateTime? targetDate,
  int totalDays = 0,
  DateTime? startDate,
}) {
  return Course(
    id: id,
    title: id,
    totalDurationMinutes: totalMinutes,
    totalSections: 1,
    dailyStudyMinutes: 0,
    startDate: startDate ?? DateTime(2026, 9, 1),
    totalDays: totalDays,
    completedMinutes: completedMinutes,
    targetDate: targetDate,
  );
}

void main() {
  const service = DailyPlannerService();
  final today = DateTime(2026, 9, 10);

  group('goal-date planning', () {
    test('calculates required pace from remaining minutes and goal date', () {
      final snapshot = service.snapshotFor(
        createCourse(
          id: 'course',
          totalMinutes: 600,
          targetDate: DateTime(2026, 9, 20),
        ),
        today,
      );

      expect(snapshot.remainingMinutes, 600);
      expect(snapshot.remainingCalendarDays, 10);
      expect(snapshot.requiredAverageMinutesPerDay, 60);
    });

    test('reports no deadline when no explicit or legacy deadline exists', () {
      final snapshot = service.snapshotFor(createCourse(id: 'course'), today);

      expect(snapshot.targetDate, isNull);
      expect(snapshot.status, CourseScheduleStatus.noDeadline);
      expect(snapshot.requiredAverageMinutesPerDay, 0);
    });

    test('treats a deadline today as one useful planning day', () {
      final snapshot = service.snapshotFor(
        createCourse(id: 'course', totalMinutes: 60, targetDate: today),
        today,
      );

      expect(snapshot.remainingCalendarDays, 0);
      expect(snapshot.requiredAverageMinutesPerDay, 60);
      expect(snapshot.status, CourseScheduleStatus.onTrack);
    });

    test('marks unfinished past-target courses as overdue', () {
      final snapshot = service.snapshotFor(
        createCourse(id: 'course', targetDate: DateTime(2026, 9, 9)),
        today,
      );

      expect(snapshot.status, CourseScheduleStatus.overdue);
    });

    test('does not plan completed courses', () {
      final plan = service.createPlan(
        courses: [
          createCourse(
            id: 'complete',
            completedMinutes: 100,
            targetDate: DateTime(2026, 9, 20),
          ),
        ],
        dailyAvailableMinutes: 90,
        completedMinutesToday: 0,
        date: today,
      );

      expect(plan.items, isEmpty);
    });
  });

  group('adaptive allocation', () {
    test('never exceeds insufficient global capacity', () {
      final plan = service.createPlan(
        courses: [
          createCourse(
            id: 'urgent',
            totalMinutes: 600,
            targetDate: DateTime(2026, 9, 15),
          ),
          createCourse(
            id: 'soon',
            totalMinutes: 300,
            targetDate: DateTime(2026, 9, 16),
          ),
          createCourse(
            id: 'later',
            totalMinutes: 300,
            targetDate: DateTime(2026, 9, 20),
          ),
        ],
        dailyAvailableMinutes: 90,
        completedMinutesToday: 30,
        date: today,
      );

      expect(plan.remainingAvailableMinutes, 60);
      expect(plan.plannedMinutes, 60);
      expect(plan.items.first.courseId, 'urgent');
    });

    test('allocates only required work when capacity exceeds demand', () {
      final plan = service.createPlan(
        courses: [
          createCourse(
            id: 'course',
            totalMinutes: 100,
            targetDate: DateTime(2026, 9, 30),
          ),
        ],
        dailyAvailableMinutes: 90,
        completedMinutesToday: 0,
        date: today,
      );

      expect(plan.items.single.recommendedMinutes, 5);
      expect(plan.plannedMinutes, 5);
    });

    test('changing capacity changes allocation', () {
      final course = createCourse(
        id: 'course',
        totalMinutes: 60,
        targetDate: DateTime(2026, 9, 11),
      );
      final constrained = service.createPlan(
        courses: [course],
        dailyAvailableMinutes: 30,
        completedMinutesToday: 0,
        date: today,
      );
      final sufficient = service.createPlan(
        courses: [course],
        dailyAvailableMinutes: 90,
        completedMinutesToday: 0,
        date: today,
      );

      expect(constrained.items.single.recommendedMinutes, 30);
      expect(sufficient.items.single.recommendedMinutes, 60);
    });

    test('a closer target date increases urgency', () {
      final course = createCourse(id: 'course', totalMinutes: 120);
      course.targetDate = DateTime(2026, 9, 12);
      final soon = service.snapshotFor(course, today);
      course.targetDate = DateTime(2026, 9, 22);
      final later = service.snapshotFor(course, today);

      expect(
        soon.requiredAverageMinutesPerDay,
        greaterThan(later.requiredAverageMinutesPerDay),
      );
    });

    test('forecasts completion from allocated daily minutes', () {
      final plan = service.createPlan(
        courses: [
          createCourse(
            id: 'course',
            totalMinutes: 120,
            targetDate: DateTime(2026, 9, 14),
          ),
        ],
        dailyAvailableMinutes: 90,
        completedMinutesToday: 0,
        date: today,
      );

      expect(plan.items.single.estimatedCompletionDate, DateTime(2026, 9, 13));
      expect(plan.items.single.forecastDifferenceDays, -1);
    });
  });

  group('forecast status and legacy compatibility', () {
    test('derives status directly from the forecast date', () {
      final target = DateTime(2026, 9, 19);
      expect(
        statusForForecast(
          remainingMinutes: 10,
          date: today,
          targetDate: target,
          estimatedCompletionDate: DateTime(2026, 9, 17),
        ),
        CourseScheduleStatus.ahead,
      );
      expect(
        statusForForecast(
          remainingMinutes: 10,
          date: today,
          targetDate: target,
          estimatedCompletionDate: DateTime(2026, 9, 20),
        ),
        CourseScheduleStatus.onTrack,
      );
      expect(
        statusForForecast(
          remainingMinutes: 10,
          date: today,
          targetDate: target,
          estimatedCompletionDate: DateTime(2026, 9, 21),
        ),
        CourseScheduleStatus.behind,
      );
      expect(
        statusForForecast(
          remainingMinutes: 10,
          date: DateTime(2026, 9, 20),
          targetDate: target,
          estimatedCompletionDate: DateTime(2026, 9, 21),
        ),
        CourseScheduleStatus.overdue,
      );
      expect(
        statusForForecast(
          remainingMinutes: 10,
          date: today,
          targetDate: null,
          estimatedCompletionDate: null,
        ),
        CourseScheduleStatus.noDeadline,
      );
    });

    test('plan item status matches its displayed forecast', () {
      final plan = service.createPlan(
        courses: [
          createCourse(
            id: 'course',
            totalMinutes: 300,
            targetDate: DateTime(2026, 9, 12),
          ),
        ],
        dailyAvailableMinutes: 30,
        completedMinutesToday: 0,
        date: today,
      );
      final item = plan.items.single;

      expect(
        item.status,
        statusForForecast(
          remainingMinutes: 300,
          date: today,
          targetDate: item.targetDate,
          estimatedCompletionDate: item.estimatedCompletionDate,
        ),
      );
    });

    test('derives a target date for legacy courses without one', () {
      final legacyCourse = createCourse(id: 'legacy', totalDays: 10);

      expect(effectiveTargetDateFor(legacyCourse), DateTime(2026, 9, 11));
    });

    test('validates edits that would reduce duration below progress', () {
      final errors = validateCourseEdit(
        title: 'Course',
        totalDurationMinutes: 90,
        totalSections: 1,
        completedMinutes: 100,
        startDate: DateTime(2026, 9, 1),
        targetDate: DateTime(2026, 9, 20),
      );

      expect(
        errors,
        contains('Total duration cannot be below completed progress.'),
      );
    });
  });
}

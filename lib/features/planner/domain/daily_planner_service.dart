import '../../../core/utils/course_progress.dart';
import '../../courses/data/course_model.dart';

enum CourseScheduleStatus { ahead, onTrack, behind, overdue, noDeadline }

class CoursePlanningSnapshot {
  const CoursePlanningSnapshot({
    required this.courseId,
    required this.remainingMinutes,
    required this.targetDate,
    required this.remainingCalendarDays,
    required this.requiredAverageMinutesPerDay,
    required this.status,
  });

  final String courseId;
  final int remainingMinutes;
  final DateTime? targetDate;
  final int? remainingCalendarDays;
  final double requiredAverageMinutesPerDay;
  final CourseScheduleStatus status;
}

class DailyPlanItem {
  const DailyPlanItem({
    required this.courseId,
    required this.recommendedMinutes,
    required this.requiredAverageMinutesPerDay,
    required this.status,
    required this.targetDate,
    required this.estimatedCompletionDate,
    required this.forecastDifferenceDays,
  });

  final String courseId;
  final int recommendedMinutes;
  final double requiredAverageMinutesPerDay;
  final CourseScheduleStatus status;
  final DateTime? targetDate;
  final DateTime? estimatedCompletionDate;

  /// Positive means the forecast is after the target; negative means ahead.
  final int? forecastDifferenceDays;
}

class DailyPlan {
  const DailyPlan({
    required this.dailyAvailableMinutes,
    required this.completedMinutesToday,
    required this.remainingAvailableMinutes,
    required this.items,
  });

  final int dailyAvailableMinutes;
  final int completedMinutesToday;
  final int remainingAvailableMinutes;
  final List<DailyPlanItem> items;

  int get plannedMinutes =>
      items.fold(0, (total, item) => total + item.recommendedMinutes);
}

/// Returns an explicit target date or a compatibility fallback for legacy
/// courses created before target dates were introduced.
DateTime? effectiveTargetDateFor(Course course) {
  if (course.targetDate != null) {
    return course.targetDate;
  }
  if (course.totalDays <= 0) {
    return null;
  }
  return DateTime(
    course.startDate.year,
    course.startDate.month,
    course.startDate.day,
  ).add(Duration(days: course.totalDays));
}

/// The only user-facing schedule status rule. It is derived from the same
/// forecast displayed in the Today plan, preventing contradictory messages.
CourseScheduleStatus statusForForecast({
  required int remainingMinutes,
  required DateTime date,
  required DateTime? targetDate,
  required DateTime? estimatedCompletionDate,
}) {
  if (targetDate == null) {
    return CourseScheduleStatus.noDeadline;
  }
  if (remainingMinutes > 0 && calendarDayDifference(date, targetDate) < 0) {
    return CourseScheduleStatus.overdue;
  }
  if (estimatedCompletionDate == null) {
    return CourseScheduleStatus.behind;
  }

  final forecastDifferenceDays = calendarDayDifference(
    targetDate,
    estimatedCompletionDate,
  );
  if (forecastDifferenceDays < -1) {
    return CourseScheduleStatus.ahead;
  }
  if (forecastDifferenceDays > 1) {
    return CourseScheduleStatus.behind;
  }
  return CourseScheduleStatus.onTrack;
}

class DailyPlannerService {
  const DailyPlannerService();

  CoursePlanningSnapshot snapshotFor(Course course, DateTime date) {
    final totalDuration = course.totalDurationMinutes < 0
        ? 0
        : course.totalDurationMinutes;
    final remainingMinutes = (totalDuration - course.completedMinutes)
        .clamp(0, totalDuration)
        .toInt();
    final targetDate = effectiveTargetDateFor(course);

    if (remainingMinutes == 0) {
      return CoursePlanningSnapshot(
        courseId: course.id,
        remainingMinutes: 0,
        targetDate: targetDate,
        remainingCalendarDays: targetDate == null
            ? null
            : calendarDayDifference(date, targetDate),
        requiredAverageMinutesPerDay: 0,
        status: statusForForecast(
          remainingMinutes: 0,
          date: date,
          targetDate: targetDate,
          estimatedCompletionDate: date,
        ),
      );
    }

    if (targetDate == null) {
      return CoursePlanningSnapshot(
        courseId: course.id,
        remainingMinutes: remainingMinutes,
        targetDate: null,
        remainingCalendarDays: null,
        requiredAverageMinutesPerDay: 0,
        status: CourseScheduleStatus.noDeadline,
      );
    }

    final remainingCalendarDays = calendarDayDifference(date, targetDate);
    final requiredAverageMinutesPerDay =
        remainingMinutes / remainingCalendarDays.clamp(1, 9999);

    return CoursePlanningSnapshot(
      courseId: course.id,
      remainingMinutes: remainingMinutes,
      targetDate: targetDate,
      remainingCalendarDays: remainingCalendarDays,
      requiredAverageMinutesPerDay: requiredAverageMinutesPerDay,
      status: remainingCalendarDays < 0
          ? CourseScheduleStatus.overdue
          : CourseScheduleStatus.onTrack,
    );
  }

  DailyPlan createPlan({
    required Iterable<Course> courses,
    required int dailyAvailableMinutes,
    required int completedMinutesToday,
    required DateTime date,
  }) {
    final capacity = dailyAvailableMinutes < 0 ? 0 : dailyAvailableMinutes;
    final completedToday = completedMinutesToday < 0
        ? 0
        : completedMinutesToday;
    final remainingCapacity = (capacity - completedToday)
        .clamp(0, capacity)
        .toInt();
    final candidates =
        courses
            .map((course) => _PlanCandidate(course, snapshotFor(course, date)))
            .where(
              (candidate) =>
                  candidate.snapshot.remainingMinutes > 0 &&
                  candidate.snapshot.targetDate != null,
            )
            .toList()
          ..sort(_compareCandidates);

    if (remainingCapacity == 0 || candidates.isEmpty) {
      return DailyPlan(
        dailyAvailableMinutes: capacity,
        completedMinutesToday: completedToday,
        remainingAvailableMinutes: remainingCapacity,
        items: const [],
      );
    }

    final totalRequiredMinutes = candidates.fold<int>(
      0,
      (total, candidate) => total + candidate.requiredMinutes,
    );
    var unallocatedMinutes = remainingCapacity;

    if (remainingCapacity < totalRequiredMinutes) {
      for (final candidate in candidates) {
        candidate.allocatedMinutes =
            (remainingCapacity *
                    candidate.requiredMinutes ~/
                    totalRequiredMinutes)
                .clamp(0, candidate.snapshot.remainingMinutes)
                .toInt();
        unallocatedMinutes -= candidate.allocatedMinutes;
      }
      _distributeShortfallMinutes(candidates, unallocatedMinutes);
    } else {
      for (final candidate in candidates) {
        candidate.allocatedMinutes = candidate.requiredMinutes;
      }
    }

    return DailyPlan(
      dailyAvailableMinutes: capacity,
      completedMinutesToday: completedToday,
      remainingAvailableMinutes: remainingCapacity,
      items: candidates
          .where((candidate) => candidate.allocatedMinutes > 0)
          .map((candidate) => _itemFor(candidate, date))
          .toList(growable: false),
    );
  }

  int _compareCandidates(_PlanCandidate first, _PlanCandidate second) {
    final urgency = second.snapshot.requiredAverageMinutesPerDay.compareTo(
      first.snapshot.requiredAverageMinutesPerDay,
    );
    if (urgency != 0) {
      return urgency;
    }
    final deadline = first.snapshot.targetDate!.compareTo(
      second.snapshot.targetDate!,
    );
    if (deadline != 0) {
      return deadline;
    }
    return first.course.id.compareTo(second.course.id);
  }

  void _distributeShortfallMinutes(
    List<_PlanCandidate> candidates,
    int unallocatedMinutes,
  ) {
    while (unallocatedMinutes > 0) {
      var allocatedInPass = false;
      for (final candidate in candidates) {
        if (candidate.allocatedMinutes < candidate.snapshot.remainingMinutes) {
          candidate.allocatedMinutes++;
          unallocatedMinutes--;
          allocatedInPass = true;
          if (unallocatedMinutes == 0) {
            return;
          }
        }
      }
      if (!allocatedInPass) {
        return;
      }
    }
  }

  DailyPlanItem _itemFor(_PlanCandidate candidate, DateTime date) {
    final estimatedStudyDays =
        (candidate.snapshot.remainingMinutes / candidate.allocatedMinutes)
            .ceil();
    final estimatedCompletionDate = date.add(
      Duration(days: estimatedStudyDays - 1),
    );
    final forecastDifferenceDays = calendarDayDifference(
      candidate.snapshot.targetDate!,
      estimatedCompletionDate,
    );
    return DailyPlanItem(
      courseId: candidate.course.id,
      recommendedMinutes: candidate.allocatedMinutes,
      requiredAverageMinutesPerDay:
          candidate.snapshot.requiredAverageMinutesPerDay,
      status: statusForForecast(
        remainingMinutes: candidate.snapshot.remainingMinutes,
        date: date,
        targetDate: candidate.snapshot.targetDate,
        estimatedCompletionDate: estimatedCompletionDate,
      ),
      targetDate: candidate.snapshot.targetDate,
      estimatedCompletionDate: estimatedCompletionDate,
      forecastDifferenceDays: forecastDifferenceDays,
    );
  }
}

class _PlanCandidate {
  _PlanCandidate(this.course, this.snapshot);

  final Course course;
  final CoursePlanningSnapshot snapshot;
  int allocatedMinutes = 0;

  int get requiredMinutes => snapshot.requiredAverageMinutesPerDay
      .ceil()
      .clamp(0, snapshot.remainingMinutes)
      .toInt();
}

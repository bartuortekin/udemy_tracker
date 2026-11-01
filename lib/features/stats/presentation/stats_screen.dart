import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../courses/data/course_model.dart';
import '../../study/data/study_session_model.dart';
import '../../study/data/study_session_statistics.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final courseBox = Hive.box<Course>('courses');
    final sessionBox = Hive.box<StudySession>('studySessions');

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: ValueListenableBuilder(
        valueListenable: courseBox.listenable(),
        builder: (context, Box<Course> courseBox, _) {
          return ValueListenableBuilder(
            valueListenable: sessionBox.listenable(),
            builder: (context, Box<StudySession> sessionBox, _) {
              return StatisticsContent(
                courses: courseBox.values.toList(),
                sessions: sessionBox.values.toList(),
                now: DateTime.now(),
              );
            },
          );
        },
      ),
    );
  }
}

class StatisticsContent extends StatelessWidget {
  const StatisticsContent({
    super.key,
    required this.courses,
    required this.sessions,
    required this.now,
  });

  final List<Course> courses;
  final List<StudySession> sessions;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final totalMinutes = totalStudyMinutes(sessions);
    final todayMinutes = studyMinutesToday(sessions, now);
    final last7DaysMinutes = studyMinutesInLast7CalendarDays(sessions, now);
    final streak = currentStudyStreak(sessions, now);
    final mostStudiedCourse = _mostStudiedCourse();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Overview', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final useTwoColumns = constraints.maxWidth >= 560;
            final itemWidth = useTwoColumns
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: _MetricCard(
                    label: 'Total study time',
                    value: _formatHours(totalMinutes),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _MetricCard(
                    label: 'Today',
                    value: '$todayMinutes min',
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _MetricCard(
                    label: 'Last 7 days',
                    value: '$last7DaysMinutes min',
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _MetricCard(
                    label: 'Current streak',
                    value: '$streak days',
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        Text('Most studied', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              mostStudiedCourse?.title ?? 'No study sessions yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text('Course progress', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (courses.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Add a course to start tracking progress.'),
            ),
          ),
        ...courses.map((course) => _CourseProgressCard(course: course)),
      ],
    );
  }

  Course? _mostStudiedCourse() {
    final minutesByCourseId = <String, int>{};
    for (final session in sessions) {
      minutesByCourseId.update(
        session.courseId,
        (minutes) => minutes + session.durationMinutes,
        ifAbsent: () => session.durationMinutes,
      );
    }
    if (minutesByCourseId.isEmpty) {
      return null;
    }
    final mostStudiedId = minutesByCourseId.entries
        .reduce((current, next) => next.value > current.value ? next : current)
        .key;
    for (final course in courses) {
      if (course.id == mostStudiedId) {
        return course;
      }
    }
    return null;
  }

  String _formatHours(int minutes) => '${(minutes / 60).toStringAsFixed(1)} h';
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(value, style: theme.textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class _CourseProgressCard extends StatelessWidget {
  const _CourseProgressCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final total = course.totalDurationMinutes;
    final progress = total > 0
        ? (course.completedMinutes / total).clamp(0.0, 1.0).toDouble()
        : 0.0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    course.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('${(progress * 100).toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress),
          ],
        ),
      ),
    );
  }
}

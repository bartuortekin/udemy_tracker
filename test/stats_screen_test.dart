import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udemy_tracker/features/courses/data/course_model.dart';
import 'package:udemy_tracker/features/stats/presentation/stats_screen.dart';
import 'package:udemy_tracker/features/study/data/study_session_model.dart';

void main() {
  testWidgets('Statistics content scrolls without overflow on a small phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final courses = List.generate(
      8,
      (index) => Course(
        id: 'course-$index',
        title: 'Course $index',
        totalDurationMinutes: 100,
        totalSections: 1,
        dailyStudyMinutes: 0,
        startDate: DateTime(2026, 1, 1),
        totalDays: 10,
        completedMinutes: index * 5,
      ),
    );
    final now = DateTime(2026, 9, 16);
    final sessions = [
      StudySession(
        id: 'session',
        courseId: 'course-0',
        startedAt: now.subtract(const Duration(minutes: 20)),
        endedAt: now,
        durationMinutes: 20,
        source: StudySessionSource.timer,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatisticsContent(
            courses: courses,
            sessions: sessions,
            now: now,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Course progress'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

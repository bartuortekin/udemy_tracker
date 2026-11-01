import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:udemy_tracker/features/courses/data/course_model.dart';
import 'package:udemy_tracker/features/study/data/study_session_model.dart';
import 'package:udemy_tracker/features/study/data/study_session_repository.dart';
import 'package:udemy_tracker/features/study/data/study_session_statistics.dart';

late Directory temporaryDirectory;
late Box<Course> courseBox;
late Box<StudySession> sessionBox;

Course createCourse({int totalMinutes = 120}) {
  return Course(
    id: 'course-1',
    title: 'Test course',
    totalDurationMinutes: totalMinutes,
    totalSections: 1,
    dailyStudyMinutes: 30,
    startDate: DateTime(2026, 1, 1),
    totalDays: 4,
  );
}

StudySession createSession({
  required String id,
  required DateTime endedAt,
  required int durationMinutes,
}) {
  return StudySession(
    id: id,
    courseId: 'course-1',
    startedAt: endedAt.subtract(Duration(minutes: durationMinutes)),
    endedAt: endedAt,
    durationMinutes: durationMinutes,
    source: StudySessionSource.timer,
  );
}

Future<Course> saveCourse(Course course) async {
  await courseBox.put(course.id, course);
  return courseBox.get(course.id)!;
}

void main() {
  setUpAll(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'udemy_tracker_study_session_test_',
    );
    Hive.init(temporaryDirectory.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CourseAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(StudySessionAdapter());
    }
    courseBox = await Hive.openBox<Course>('courses_test');
    sessionBox = await Hive.openBox<StudySession>('study_sessions_test');
  });

  tearDown(() async {
    await courseBox.clear();
    await sessionBox.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await temporaryDirectory.delete(recursive: true);
  });

  group('StudySessionRepository', () {
    test('creates a persisted session for recorded progress', () async {
      final course = await saveCourse(createCourse());
      final repository = StudySessionRepository(sessionBox: sessionBox);
      final startedAt = DateTime(2026, 9, 16, 10);
      final endedAt = DateTime(2026, 9, 16, 10, 20);

      await repository.recordProgress(
        course: course,
        requestedMinutes: 20,
        startedAt: startedAt,
        endedAt: endedAt,
        source: StudySessionSource.timer,
      );

      expect(course.completedMinutes, 20);
      expect(sessionBox.length, 1);
      final session = sessionBox.values.single;
      expect(session.courseId, course.id);
      expect(session.durationMinutes, 20);
      expect(session.startedAt, startedAt);
      expect(session.endedAt, endedAt);
      expect(session.source, StudySessionSource.timer);
    });

    test('records only the capped progress duration in the session', () async {
      final course = await saveCourse(createCourse(totalMinutes: 10));
      final repository = StudySessionRepository(sessionBox: sessionBox);

      await repository.recordProgress(
        course: course,
        requestedMinutes: 30,
        startedAt: DateTime(2026, 9, 16, 9),
        endedAt: DateTime(2026, 9, 16, 9, 30),
        source: StudySessionSource.quickAdd,
      );

      expect(course.completedMinutes, 10);
      expect(sessionBox.values.single.durationMinutes, 10);
    });

    test('does not create a session for zero minutes', () async {
      final course = await saveCourse(createCourse());
      final repository = StudySessionRepository(sessionBox: sessionBox);

      await repository.recordProgress(
        course: course,
        requestedMinutes: 0,
        startedAt: DateTime(2026, 9, 16, 9),
        endedAt: DateTime(2026, 9, 16, 9),
        source: StudySessionSource.timer,
      );

      expect(course.completedMinutes, 0);
      expect(sessionBox.length, 0);
    });
  });

  group('study session statistics', () {
    final now = DateTime(2026, 9, 16, 18);
    final sessions = [
      createSession(
        id: 'today',
        endedAt: DateTime(2026, 9, 16, 9),
        durationMinutes: 20,
      ),
      createSession(
        id: 'six-days-ago',
        endedAt: DateTime(2026, 9, 10, 9),
        durationMinutes: 30,
      ),
      createSession(
        id: 'seven-days-ago',
        endedAt: DateTime(2026, 9, 9, 9),
        durationMinutes: 40,
      ),
    ];

    test('aggregates study time for today', () {
      expect(studyMinutesToday(sessions, now), 20);
    });

    test('aggregates the current and previous six calendar days', () {
      expect(studyMinutesInLast7CalendarDays(sessions, now), 50);
    });

    test('counts consecutive study days ending today', () {
      final streakSessions = [
        createSession(
          id: 'today-streak',
          endedAt: DateTime(2026, 9, 16, 10),
          durationMinutes: 10,
        ),
        createSession(
          id: 'yesterday-streak',
          endedAt: DateTime(2026, 9, 15, 10),
          durationMinutes: 10,
        ),
        createSession(
          id: 'two-days-ago-streak',
          endedAt: DateTime(2026, 9, 14, 10),
          durationMinutes: 10,
        ),
      ];

      expect(currentStudyStreak(streakSessions, now), 3);
    });

    test('continues a streak from yesterday when today has no study', () {
      final streakSessions = [
        createSession(
          id: 'yesterday-streak',
          endedAt: DateTime(2026, 9, 15, 10),
          durationMinutes: 10,
        ),
        createSession(
          id: 'two-days-ago-streak',
          endedAt: DateTime(2026, 9, 14, 10),
          durationMinutes: 10,
        ),
      ];

      expect(currentStudyStreak(streakSessions, now), 2);
    });

    test('resets the streak after a gap', () {
      final streakSessions = [
        createSession(
          id: 'today-streak',
          endedAt: DateTime(2026, 9, 16, 10),
          durationMinutes: 10,
        ),
        createSession(
          id: 'old-streak',
          endedAt: DateTime(2026, 9, 13, 10),
          durationMinutes: 10,
        ),
      ];

      expect(currentStudyStreak(streakSessions, now), 1);
    });
  });
}

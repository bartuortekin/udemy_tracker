import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_shell.dart';
import 'core/settings/daily_capacity_repository.dart';
import 'features/courses/data/course_model.dart';
import 'features/study/data/study_session_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(CourseAdapter());
  Hive.registerAdapter(StudySessionAdapter());

  await Hive.openBox<Course>('courses');
  await Hive.openBox<StudySession>('studySessions');
  await Hive.openBox<int>(dailySettingsBoxName);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Course Tracker',
      theme: ThemeData(useMaterial3: true),
      home: const AppShell(),
    );
  }
}

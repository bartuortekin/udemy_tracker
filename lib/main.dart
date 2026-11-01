import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/courses/data/course_model.dart';
import 'features/courses/presentation/course_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  //  await Hive.deleteBoxFromDisk('courses');

  Hive.registerAdapter(CourseAdapter());

  await Hive.openBox<Course>('courses');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Course Tracker',
      theme: ThemeData(useMaterial3: true),
      home: const CourseListScreen(),
    );
  }
}

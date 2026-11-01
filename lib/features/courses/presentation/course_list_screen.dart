import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/utils/app_date_format.dart';
import '../../planner/domain/daily_planner_service.dart';
import '../../study/data/study_session_model.dart';
import '../../study/data/study_session_repository.dart';
import '../../study/presentation/study_session_screen.dart';
import '../data/course_model.dart';
import 'add_course_screen.dart';
import 'edit_course_screen.dart';

class CourseListScreen extends StatelessWidget {
  const CourseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final courseBox = Hive.box<Course>('courses');
    const planner = DailyPlannerService();

    return Scaffold(
      appBar: AppBar(title: const Text('Courses')),
      body: ValueListenableBuilder(
        valueListenable: courseBox.listenable(),
        builder: (context, Box<Course> courseBox, _) {
          if (courseBox.values.isEmpty) {
            return const Center(child: Text('No courses yet.'));
          }

          return ListView(
            padding: const EdgeInsets.all(8),
            children: courseBox.values.map((course) {
              final total = course.totalDurationMinutes;
              final completed = course.completedMinutes;
              final progress = total > 0
                  ? (completed / total).clamp(0.0, 1.0).toDouble()
                  : 0.0;
              final remainingMinutes = (total - completed).clamp(0, total);
              final remainingHours = (remainingMinutes / 60).toStringAsFixed(1);
              final snapshot = planner.snapshotFor(course, DateTime.now());

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 8),
                      Text('${(progress * 100).toInt()}% completed'),
                      Text('Remaining: $remainingHours hours'),
                      Text(_targetText(snapshot.targetDate)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      StudySessionScreen(course: course),
                                ),
                              );
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Study'),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Edit course',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditCourseScreen(course: course),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            tooltip: 'Add 30 minutes',
                            onPressed: () async {
                              final now = DateTime.now();
                              await StudySessionRepository().recordProgress(
                                course: course,
                                requestedMinutes: 30,
                                startedAt: now,
                                endedAt: now,
                                source: StudySessionSource.quickAdd,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCourseScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _targetText(DateTime? targetDate) {
    if (targetDate == null) {
      return 'No target date';
    }
    return 'Target: ${formatCompactDate(targetDate)}';
  }
}

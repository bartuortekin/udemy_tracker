import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/settings/daily_capacity_repository.dart';
import '../../../core/utils/app_date_format.dart';
import '../../courses/data/course_model.dart';
import '../../study/data/study_session_model.dart';
import '../../study/data/study_session_statistics.dart';
import '../../study/presentation/study_session_screen.dart';
import '../domain/daily_planner_service.dart';

class TodayDashboardScreen extends StatelessWidget {
  const TodayDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final courseBox = Hive.box<Course>('courses');
    final sessionBox = Hive.box<StudySession>('studySessions');
    final settingsBox = Hive.box<int>(dailySettingsBoxName);
    final capacityRepository = DailyCapacityRepository(
      settingsBox: settingsBox,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Edit daily study capacity',
            onPressed: () => showDailyCapacityDialog(
              context,
              initialMinutes: capacityRepository.dailyAvailableMinutes,
              onSave: capacityRepository.setDailyAvailableMinutes,
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: courseBox.listenable(),
        builder: (context, Box<Course> courseBox, _) {
          return ValueListenableBuilder(
            valueListenable: sessionBox.listenable(),
            builder: (context, Box<StudySession> sessionBox, _) {
              return ValueListenableBuilder(
                valueListenable: settingsBox.listenable(),
                builder: (context, Box<int> settingsBox, _) {
                  final now = DateTime.now();
                  final completedToday = studyMinutesToday(
                    sessionBox.values,
                    now,
                  );
                  final plan = const DailyPlannerService().createPlan(
                    courses: courseBox.values,
                    dailyAvailableMinutes:
                        capacityRepository.dailyAvailableMinutes,
                    completedMinutesToday: completedToday,
                    date: now,
                  );
                  final coursesById = {
                    for (final course in courseBox.values) course.id: course,
                  };

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _TodayProgressCard(plan: plan),
                      const SizedBox(height: 28),
                      Text(
                        "Today's plan",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (plan.items.isEmpty) const _EmptyPlanCard(),
                      ...plan.items.map((item) {
                        final course = coursesById[item.courseId];
                        if (course == null) {
                          return const SizedBox.shrink();
                        }
                        return _PlanCourseCard(
                          course: course,
                          item: item,
                          date: now,
                        );
                      }),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

Future<void> showDailyCapacityDialog(
  BuildContext context, {
  required int initialMinutes,
  required Future<void> Function(int minutes) onSave,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) =>
        DailyCapacityDialog(initialMinutes: initialMinutes, onSave: onSave),
  );
}

class DailyCapacityDialog extends StatefulWidget {
  const DailyCapacityDialog({
    super.key,
    required this.initialMinutes,
    required this.onSave,
  });

  final int initialMinutes;
  final Future<void> Function(int minutes) onSave;

  @override
  State<DailyCapacityDialog> createState() => _DailyCapacityDialogState();
}

class _DailyCapacityDialogState extends State<DailyCapacityDialog> {
  late final TextEditingController _controller;
  String? _errorText;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialMinutes.toString());
  }

  Future<void> _save() async {
    final minutes = int.tryParse(_controller.text.trim());
    if (minutes == null || minutes <= 0) {
      setState(() => _errorText = 'Enter a positive whole number.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      await widget.onSave(minutes);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorText = 'Could not save daily capacity. Try again.';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Daily study capacity'),
      content: TextField(
        controller: _controller,
        enabled: !_isSaving,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Minutes available each day',
          errorText: _errorText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _TodayProgressCard extends StatelessWidget {
  const _TodayProgressCard({required this.plan});

  final DailyPlan plan;

  @override
  Widget build(BuildContext context) {
    final progress = plan.dailyAvailableMinutes == 0
        ? 0.0
        : (plan.completedMinutesToday / plan.dailyAvailableMinutes)
              .clamp(0.0, 1.0)
              .toDouble();
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's progress", style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              '${plan.completedMinutesToday} / ${plan.dailyAvailableMinutes} min',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress, minHeight: 8),
            const SizedBox(height: 12),
            Text(
              '${plan.remainingAvailableMinutes} min left today',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPlanCard extends StatelessWidget {
  const _EmptyPlanCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('No study blocks are planned for the rest of today.'),
      ),
    );
  }
}

class _PlanCourseCard extends StatelessWidget {
  const _PlanCourseCard({
    required this.course,
    required this.item,
    required this.date,
  });

  final Course course;
  final DailyPlanItem item;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showEstimate =
        item.forecastDifferenceDays != null && item.forecastDifferenceDays != 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(course.title, style: theme.textTheme.titleMedium),
                ),
                Text(
                  '${item.recommendedMinutes} min',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _StatusChip(status: item.status),
            const SizedBox(height: 12),
            if (item.targetDate != null)
              Text('Target: ${formatCompactDate(item.targetDate!, date)}'),
            if (showEstimate && item.estimatedCompletionDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Estimated: ${formatCompactDate(item.estimatedCompletionDate!, date)} - ${_forecastText(item.forecastDifferenceDays!)}',
                ),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudySessionScreen(course: course),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start session'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _forecastText(int differenceDays) {
    if (differenceDays > 0) {
      return '$differenceDays days behind';
    }
    return '${-differenceDays} days ahead';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final CourseScheduleStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      CourseScheduleStatus.ahead => Colors.green,
      CourseScheduleStatus.onTrack => Colors.blue,
      CourseScheduleStatus.behind => Colors.orange,
      CourseScheduleStatus.overdue => Colors.red,
      CourseScheduleStatus.noDeadline => Colors.grey,
    };
    final label = switch (status) {
      CourseScheduleStatus.ahead => 'Ahead',
      CourseScheduleStatus.onTrack => 'On track',
      CourseScheduleStatus.behind => 'Behind',
      CourseScheduleStatus.overdue => 'Overdue',
      CourseScheduleStatus.noDeadline => 'No deadline',
    };
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color.withValues(alpha: 0.4)),
    );
  }
}

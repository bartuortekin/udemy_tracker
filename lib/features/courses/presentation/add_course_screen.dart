import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/app_date_format.dart';
import '../../../core/utils/course_progress.dart';
import '../data/course_model.dart';

class AddCourseScreen extends StatefulWidget {
  const AddCourseScreen({super.key});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  final _sectionsController = TextEditingController();
  final _uuid = const Uuid();

  DateTime? _startDate;
  DateTime? _targetDate;

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickTargetDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  void _saveCourse() {
    final title = _titleController.text.trim();
    final durationHours = int.tryParse(_durationController.text);
    final sections = int.tryParse(_sectionsController.text);
    final errors = <String>[];

    if (title.isEmpty) {
      errors.add('Course title cannot be empty.');
    }
    if (durationHours == null || durationHours <= 0) {
      errors.add('Total duration must be greater than zero.');
    }
    if (sections == null || sections <= 0) {
      errors.add('Total sections must be greater than zero.');
    }
    if (_startDate == null) {
      errors.add('Choose a start date.');
    }
    if (_targetDate == null) {
      errors.add('Choose a target completion date.');
    }
    if (_startDate != null &&
        _targetDate != null &&
        calendarDayDifference(_startDate!, _targetDate!) < 0) {
      errors.add('Target date cannot be before the start date.');
    }

    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errors.join('\n'))));
      return;
    }

    final validDurationHours = durationHours!;
    final validSections = sections!;
    final validStartDate = _startDate!;
    final validTargetDate = _targetDate!;
    final totalMinutes = validDurationHours * 60;
    final totalDays = calendarDayDifference(
      validStartDate,
      validTargetDate,
    ).clamp(1, 9999).toInt();
    final course = Course(
      id: _uuid.v4(),
      title: title,
      totalDurationMinutes: totalMinutes,
      totalSections: validSections,
      // Retained only for legacy Hive compatibility; global capacity drives plans.
      dailyStudyMinutes: 0,
      startDate: validStartDate,
      totalDays: totalDays,
      targetDate: validTargetDate,
    );

    Hive.box<Course>('courses').put(course.id, course);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Course saved.')));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _sectionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add course')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Course title'),
            ),
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total duration (hours)',
              ),
            ),
            TextField(
              controller: _sectionsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Total sections'),
            ),
            const SizedBox(height: 16),
            _DateSelector(
              label: 'Start date',
              date: _startDate,
              onPressed: _pickStartDate,
            ),
            _DateSelector(
              label: 'Target completion date',
              date: _targetDate,
              onPressed: _pickTargetDate,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _saveCourse, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.label,
    required this.date,
    required this.onPressed,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            date == null ? 'Choose $label' : '$label: ${_formatDate(date!)}',
          ),
        ),
        TextButton(onPressed: onPressed, child: const Text('Choose')),
      ],
    );
  }

  String _formatDate(DateTime date) => formatCompactDate(date);
}

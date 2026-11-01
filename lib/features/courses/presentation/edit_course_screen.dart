import 'package:flutter/material.dart';
import '../../../core/utils/app_date_format.dart';
import '../../../core/utils/course_progress.dart';
import '../../planner/domain/daily_planner_service.dart';
import '../data/course_model.dart';
import '../domain/course_edit_validation.dart';

class EditCourseScreen extends StatefulWidget {
  const EditCourseScreen({super.key, required this.course});

  final Course course;

  @override
  State<EditCourseScreen> createState() => _EditCourseScreenState();
}

class _EditCourseScreenState extends State<EditCourseScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _durationController;
  late final TextEditingController _sectionsController;
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.course.title);
    _durationController = TextEditingController(
      text: (widget.course.totalDurationMinutes / 60).ceil().toString(),
    );
    _sectionsController = TextEditingController(
      text: widget.course.totalSections.toString(),
    );
    _targetDate = effectiveTargetDateFor(widget.course);
  }

  Future<void> _pickTargetDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _save() async {
    final durationHours = int.tryParse(_durationController.text);
    final totalMinutes = durationHours == null ? null : durationHours * 60;
    final sections = int.tryParse(_sectionsController.text);
    final errors = validateCourseEdit(
      title: _titleController.text,
      totalDurationMinutes: totalMinutes,
      totalSections: sections,
      completedMinutes: widget.course.completedMinutes,
      startDate: widget.course.startDate,
      targetDate: _targetDate,
    );
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errors.join('\n'))));
      return;
    }

    widget.course
      ..title = _titleController.text.trim()
      ..totalDurationMinutes = totalMinutes!
      ..totalSections = sections!
      ..targetDate = _targetDate;
    if (_targetDate != null) {
      widget.course.totalDays = calendarDayDifference(
        widget.course.startDate,
        _targetDate!,
      ).clamp(1, 9999).toInt();
    }
    await widget.course.save();
    if (mounted) {
      Navigator.pop(context);
    }
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
      appBar: AppBar(title: const Text('Edit course')),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    _targetDate == null
                        ? 'No target date'
                        : 'Target: ${_formatDate(_targetDate!)}',
                  ),
                ),
                TextButton(
                  onPressed: _pickTargetDate,
                  child: const Text('Choose'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _save, child: const Text('Save changes')),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => formatCompactDate(date);
}

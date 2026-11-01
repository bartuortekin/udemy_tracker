import 'dart:async';
import 'package:flutter/material.dart';
import '../../courses/data/course_model.dart';
import '../data/study_session_model.dart';
import '../data/study_session_repository.dart';

class StudySessionScreen extends StatefulWidget {
  const StudySessionScreen({super.key, required this.course});

  final Course course;

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  Timer? _timer;
  var _seconds = 0;
  var _isRunning = false;
  DateTime? _startedAt;

  void _startTimer() {
    _startedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _seconds++);
      }
    });
    setState(() => _isRunning = true);
  }

  Future<void> _stopTimer() async {
    _timer?.cancel();
    final now = DateTime.now();
    await StudySessionRepository().recordProgress(
      course: widget.course,
      requestedMinutes: _seconds ~/ 60,
      startedAt: _startedAt ?? now,
      endedAt: now,
      source: StudySessionSource.timer,
    );
    if (!mounted) {
      return;
    }
    setState(() => _isRunning = false);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.course.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTime(_seconds),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            if (!_isRunning)
              ElevatedButton(
                onPressed: _startTimer,
                child: const Text('Start'),
              ),
            if (_isRunning)
              ElevatedButton(
                onPressed: _stopTimer,
                child: const Text('Finish'),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

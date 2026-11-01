import 'dart:async';
import 'package:flutter/material.dart';
import '../../courses/data/course_model.dart';

class StudySessionScreen extends StatefulWidget {
  final Course course;

  const StudySessionScreen({super.key, required this.course});

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });

    setState(() {
      _isRunning = true;
    });
  }

  void _stopTimer() async {
    _timer?.cancel();

    final minutes = (_seconds / 60).floor();
    final now = DateTime.now();

    final updatedCourse = widget.course;

    if (minutes > 0) {
      updatedCourse.completedMinutes += minutes;
      updatedCourse.todayCompletedMinutes += minutes;

      // streak logic (once per day)
      if (updatedCourse.lastStudyDate == null ||
          updatedCourse.lastStudyDate!.day != now.day) {
        updatedCourse.streak += 1;
      }

      updatedCourse.lastStudyDate = now;
    } else {
      updatedCourse.streak = 0;
    }

    await updatedCourse.save();

    setState(() {
      _isRunning = false;
    });

    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;

    return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
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
                child: const Text("Başla"),
              ),

            if (_isRunning)
              ElevatedButton(onPressed: _stopTimer, child: const Text("Bitir")),
          ],
        ),
      ),
    );
  }
}

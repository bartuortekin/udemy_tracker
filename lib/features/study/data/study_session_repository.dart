import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/course_progress.dart';
import '../../courses/data/course_model.dart';
import 'study_session_model.dart';

/// Persists a course progress update and, when minutes were actually added,
/// an immutable session describing that activity.
class StudySessionRepository {
  StudySessionRepository({Box<StudySession>? sessionBox, Uuid? uuid})
    : _sessionBox = sessionBox ?? Hive.box<StudySession>('studySessions'),
      _uuid = uuid ?? const Uuid();

  final Box<StudySession> _sessionBox;
  final Uuid _uuid;

  Future<ProgressUpdate> recordProgress({
    required Course course,
    required int requestedMinutes,
    required DateTime startedAt,
    required DateTime endedAt,
    required StudySessionSource source,
  }) async {
    final update = recordStudyProgress(
      course: course,
      requestedMinutes: requestedMinutes,
      studiedAt: endedAt,
    );

    if (update.didChange) {
      await course.save();
    }

    if (update.recordedMinutes > 0) {
      final session = StudySession(
        id: _uuid.v4(),
        courseId: course.id,
        startedAt: startedAt,
        endedAt: endedAt,
        durationMinutes: update.recordedMinutes,
        source: source,
      );
      await _sessionBox.put(session.id, session);
    }

    return update;
  }
}

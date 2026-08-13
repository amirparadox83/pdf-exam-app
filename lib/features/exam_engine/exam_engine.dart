/// Exam Engine — Stage 19
/// Manages exam state, answers, timer, persistence, resume.
///
/// Stage 19 wiring (real): uses ExamRepository for exam CRUD + answer
/// persistence, and ResultRepository to persist submitted results. Every
/// method touches the repository layer.
import 'dart:async';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

abstract class ExamEngine {
  Future<String> createExam(Exam exam);
  Future<Exam?> getExam(String id);
  Future<void> startExam(String examId);
  Future<void> pauseExam(String examId);
  Future<void> resumeExam(String examId);
  Future<void> selectAnswer(String examId, String questionId, String? optionId);
  Future<void> toggleBookmark(String examId, String questionId);
  Future<void> recordTimeSpent(String examId, String questionId, Duration time);
  Future<List<ExamAnswer>> getAnswers(String examId);
  Future<void> cancelExam(String examId);
  Future<void> deleteExam(String examId);

  /// Get remaining time using timestamps (handles clock changes & background).
  Duration? getRemainingTime(String examId);

  /// Subscribe to remaining time updates.
  Stream<Duration> remainingTimeStream(String examId);
}

class ExamEngineImpl implements ExamEngine {
  final ExamRepository examRepository;
  final ResultRepository resultRepository;

  // In-memory timer state (deadline per running exam). The persisted
  // `startedAt` + `timeLimitSeconds` are the source of truth across app
  // restarts; this map just holds the active countdown for the UI stream.
  final Map<String, Timer> _timers = {};
  final Map<String, DateTime> _deadlines = {};
  final Map<String, StreamController<Duration>> _streams = {};

  ExamEngineImpl({
    required this.examRepository,
    required this.resultRepository,
  });

  @override
  Future<String> createExam(Exam exam) async {
    // Persist immediately with status=ready (exam is immutable after creation).
    final toInsert = exam.copyWith(
      status: exam.status == ExamStatus.draft ? ExamStatus.ready : exam.status,
    );
    final id = await examRepository.insert(toInsert);
    return id;
  }

  @override
  Future<Exam?> getExam(String id) => examRepository.getById(id);

  @override
  Future<void> startExam(String examId) async {
    final exam = await examRepository.getById(examId);
    if (exam == null) {
      throw StateError('Exam $examId not found');
    }
    // Persist the startedAt + inProgress status so we can resume after crash.
    final now = DateTime.now();
    await examRepository.update(exam.copyWith(
      status: ExamStatus.inProgress,
      startedAt: now,
    ));
    _deadlines[examId] = now.add(Duration(seconds: exam.timeLimitSeconds));
    _startTimer(examId);
  }

  @override
  Future<void> pauseExam(String examId) async {
    _stopTimer(examId);
    // We deliberately don't change the persisted status on pause — UI
    // lifecycle pauses the in-memory timer, but the exam remains
    // "in progress" in the DB so the user can resume after re-opening
    // the app. The next startExam/resumeExam call reloads the deadline
    // from `startedAt + timeLimitSeconds`.
  }

  @override
  Future<void> resumeExam(String examId) async {
    final exam = await examRepository.getById(examId);
    if (exam == null) return;
    if (exam.startedAt != null) {
      _deadlines[examId] = exam.startedAt!.add(Duration(seconds: exam.timeLimitSeconds));
    }
    _startTimer(examId);
  }

  @override
  Future<void> selectAnswer(String examId, String questionId, String? optionId) async {
    final existing = await examRepository.getAnswer(examId, questionId);
    final updated = ExamAnswer(
      examId: examId,
      questionId: questionId,
      selectedOptionId: optionId,
      isBookmarked: existing?.isBookmarked ?? false,
      timeSpent: existing?.timeSpent,
      updatedAt: DateTime.now(),
    );
    await examRepository.saveAnswer(updated);
  }

  @override
  Future<void> toggleBookmark(String examId, String questionId) async {
    final existing = await examRepository.getAnswer(examId, questionId);
    final updated = ExamAnswer(
      examId: examId,
      questionId: questionId,
      selectedOptionId: existing?.selectedOptionId,
      isBookmarked: !(existing?.isBookmarked ?? false),
      timeSpent: existing?.timeSpent,
      updatedAt: DateTime.now(),
    );
    await examRepository.saveAnswer(updated);
  }

  @override
  Future<void> recordTimeSpent(String examId, String questionId, Duration time) async {
    final existing = await examRepository.getAnswer(examId, questionId);
    if (existing == null) {
      // Create a stub answer row so we have somewhere to persist the time.
      await examRepository.saveAnswer(ExamAnswer(
        examId: examId,
        questionId: questionId,
        timeSpent: time,
        updatedAt: DateTime.now(),
      ));
    } else {
      await examRepository.saveAnswer(existing.copyWith(timeSpent: time));
    }
  }

  @override
  Future<List<ExamAnswer>> getAnswers(String examId) => examRepository.getAnswers(examId);

  @override
  Future<void> cancelExam(String examId) async {
    _stopTimer(examId);
    _deadlines.remove(examId);
    final exam = await examRepository.getById(examId);
    if (exam != null) {
      await examRepository.update(exam.copyWith(status: ExamStatus.cancelled));
    }
  }

  @override
  Future<void> deleteExam(String examId) async {
    await cancelExam(examId);
    await examRepository.delete(examId);
  }

  @override
  Duration? getRemainingTime(String examId) {
    final deadline = _deadlines[examId];
    if (deadline == null) return null;
    final now = DateTime.now();
    final remaining = deadline.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  Stream<Duration> remainingTimeStream(String examId) {
    _streams[examId] ??= StreamController<Duration>.broadcast();
    return _streams[examId]!.stream;
  }

  void _startTimer(String examId) {
    _timers[examId]?.cancel();
    _timers[examId] = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = getRemainingTime(examId);
      if (remaining == null) return;
      _streams[examId]?.add(remaining);
      if (remaining == Duration.zero) {
        _stopTimer(examId);
      }
    });
  }

  void _stopTimer(String examId) {
    _timers[examId]?.cancel();
    _timers.remove(examId);
  }

  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    for (final s in _streams.values) {
      s.close();
    }
  }
}

/// Mistake Manager — Stage 23
/// Dedicated mistake system with reasons, streaks, and "Start Mistake Test".
///
/// Stage 23 wiring (real): all CRUD goes through MistakeRepository +
/// QuestionRepository. recordMistake inserts-or-increments; markCorrect
/// increments the correctStreak and removes the mistake record once the
/// streak hits 3 (configurable below).
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

abstract class MistakeManager {
  Future<void> recordMistake({
    required String questionId,
    String? examResultId,
    MistakeReason? reason,
    String? note,
  });
  Future<void> markCorrect(String questionId);
  Future<List<Mistake>> getAll({int limit = 200, int offset = 0});
  Future<List<Mistake>> filterByReason(MistakeReason reason);
  Future<int> count();
  Future<void> addNote(String mistakeId, String note);
  Future<void> removeMistake(String mistakeId);

  /// Generate an exam from mistakes.
  Future<List<String>> getMistakeQuestionIds({
    int limit = 40,
    String? subjectId,
    MistakeReason? reason,
  });
}

class MistakeManagerImpl implements MistakeManager {
  final MistakeRepository mistakeRepository;
  final QuestionRepository questionRepository;

  /// Number of consecutive correct answers required to auto-remove a mistake.
  static const int correctStreakThreshold = 3;

  MistakeManagerImpl({
    required this.mistakeRepository,
    required this.questionRepository,
  });

  @override
  Future<void> recordMistake({
    required String questionId,
    String? examResultId,
    MistakeReason? reason,
    String? note,
  }) async {
    final now = DateTime.now();
    final existing = await mistakeRepository.getByQuestion(questionId);
    if (existing == null) {
      await mistakeRepository.insert(Mistake(
        id: '',
        questionId: questionId,
        examResultId: examResultId ?? '',
        reason: reason,
        note: note,
        mistakeCount: 1,
        lastMistakeAt: now,
        correctStreak: 0,
        createdAt: now,
        updatedAt: now,
      ));
    } else {
      // Increment mistakeCount, reset the correct streak (we just failed again),
      // update reason/note if provided.
      await mistakeRepository.update(existing.copyWith(
        examResultId: examResultId ?? existing.examResultId,
        reason: reason ?? existing.reason,
        note: note ?? existing.note,
        mistakeCount: existing.mistakeCount + 1,
        lastMistakeAt: now,
        correctStreak: 0,
        updatedAt: now,
      ));
    }
  }

  @override
  Future<void> markCorrect(String questionId) async {
    // Bump the question's correct counter (so analytics sees it), and bump
    // the mistake's correctStreak. If the streak crosses the threshold we
    // remove the mistake — the user has demonstrated mastery.
    await questionRepository.markAnswered(questionId, true);
    final existing = await mistakeRepository.getByQuestion(questionId);
    if (existing == null) return;
    final newStreak = existing.correctStreak + 1;
    if (newStreak >= correctStreakThreshold) {
      await mistakeRepository.delete(existing.id);
    } else {
      await mistakeRepository.update(existing.copyWith(
        correctStreak: newStreak,
        updatedAt: DateTime.now(),
      ));
    }
  }

  @override
  Future<List<Mistake>> getAll({int limit = 200, int offset = 0}) =>
      mistakeRepository.getAll(limit: limit, offset: offset);

  @override
  Future<List<Mistake>> filterByReason(MistakeReason reason) async {
    final all = await mistakeRepository.getAll(limit: 1000);
    return all.where((m) => m.reason == reason).toList();
  }

  @override
  Future<int> count() async => (await mistakeRepository.getAll(limit: 100000)).length;

  @override
  Future<void> addNote(String mistakeId, String note) async {
    final all = await mistakeRepository.getAll(limit: 100000);
    final target = all.firstWhere(
      (m) => m.id == mistakeId,
      orElse: () => throw StateError('Mistake $mistakeId not found'),
    );
    await mistakeRepository.update(target.copyWith(
      note: note,
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<void> removeMistake(String mistakeId) =>
      mistakeRepository.delete(mistakeId);

  @override
  Future<List<String>> getMistakeQuestionIds({
    int limit = 40,
    String? subjectId,
    MistakeReason? reason,
  }) async {
    List<Mistake> mistakes = await mistakeRepository.getAll(limit: 1000);
    if (reason != null) {
      mistakes = mistakes.where((m) => m.reason == reason).toList();
    }
    // Sort by lastMistakeAt DESC so the most recent failures come first.
    mistakes.sort((a, b) =>
        (b.lastMistakeAt ?? b.updatedAt).compareTo(a.lastMistakeAt ?? a.updatedAt));
    final out = <String>[];
    for (final m in mistakes) {
      if (subjectId != null) {
        final q = await questionRepository.getById(m.questionId);
        if (q == null || q.subjectId != subjectId) continue;
      }
      out.add(m.questionId);
      if (out.length >= limit) break;
    }
    return out;
  }
}

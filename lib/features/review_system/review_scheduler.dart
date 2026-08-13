/// Review System — Stage 24
/// Deterministic spaced repetition using SM-2 algorithm.
///
/// Stage 24 wiring (real): SM-2 math is unchanged (forbidden to touch by
/// project constraint). Persistence now flows through ReviewRepository —
/// `recordReview` reads the existing schedule, computes the new SM-2 values,
/// and writes back via `update` (or `insert` for a new schedule). `getDue`
/// and `getByStatus` query the repository instead of returning `[]`.
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

abstract class ReviewScheduler {
  /// Record a review outcome for a question.
  /// quality: 0-5 (0=complete fail, 5=perfect)
  Future<ReviewSchedule> recordReview({
    required String questionId,
    required int quality,
  });

  /// Get all questions due for review as of `asOf` (default: now).
  Future<List<ReviewSchedule>> getDue({DateTime? asOf, int limit = 50});

  /// Mark a question as mastered.
  Future<void> markMastered(String questionId);

  /// Get count of due reviews for today.
  Future<int> getDueCount({DateTime? asOf});

  /// Get all schedules with a given status.
  Future<List<ReviewSchedule>> getByStatus(ReviewStatus status);
}

/// SM-2 implementation
/// Reference: https://www.supermemo.com/en/blog/application-of-a-computer-to-improve-the-results-obtained-in-working-with-the-supermemo-method
class Sm2ReviewScheduler implements ReviewScheduler {
  final ReviewRepository reviewRepository;

  Sm2ReviewScheduler({required this.reviewRepository});

  @override
  Future<ReviewSchedule> recordReview({
    required String questionId,
    required int quality,
  }) async {
    // Fetch existing schedule or create new
    final existing = await reviewRepository.getByQuestion(questionId);
    final schedule = existing ?? _newSchedule(questionId);

    // SM-2 algorithm — UNCHANGED (project constraint: do not touch algorithm).
    double ef = schedule.easeFactor;
    int reps = schedule.repetitions;
    int interval = schedule.interval;
    DateTime next;

    if (quality < 3) {
      // Failed — reset repetitions
      reps = 0;
      interval = 0;
    } else {
      reps += 1;
      if (reps == 1) {
        interval = 1;
      } else if (reps == 2) {
        interval = 6;
      } else {
        interval = (interval * ef).round();
      }
    }

    // Update ease factor
    ef = ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (ef < 1.3) ef = 1.3;

    next = DateTime.now().add(Duration(days: interval));

    ReviewStatus status;
    if (quality < 3) {
      status = ReviewStatus.difficult;
    } else if (reps >= 5 && ef >= 2.5) {
      status = ReviewStatus.mastered;
    } else {
      status = ReviewStatus.learning;
    }

    final now = DateTime.now();
    final updated = ReviewSchedule(
      id: schedule.id,
      questionId: questionId,
      easeFactor: ef,
      interval: interval,
      repetitions: reps,
      nextReviewAt: next,
      lastReviewedAt: now,
      status: status,
      createdAt: schedule.createdAt,
      updatedAt: now,
    );

    // Persist: insert if new (empty id), update if existing.
    if (existing == null || schedule.id.isEmpty) {
      final newId = await reviewRepository.insert(updated);
      return updated.copyWith(id: newId);
    } else {
      await reviewRepository.update(updated);
      return updated;
    }
  }

  @override
  Future<List<ReviewSchedule>> getDue({DateTime? asOf, int limit = 50}) =>
      reviewRepository.getDue(asOf: asOf, limit: limit);

  @override
  Future<void> markMastered(String questionId) async {
    final existing = await reviewRepository.getByQuestion(questionId);
    final now = DateTime.now();
    if (existing == null) {
      // Insert a new schedule already in mastered state.
      final schedule = _newSchedule(questionId).copyWith(
        status: ReviewStatus.mastered,
        repetitions: 5,
        easeFactor: 2.5,
        interval: 365,
        nextReviewAt: now.add(const Duration(days: 365)),
        updatedAt: now,
      );
      await reviewRepository.insert(schedule);
      return;
    }
    await reviewRepository.update(existing.copyWith(
      status: ReviewStatus.mastered,
      repetitions: 5,
      easeFactor: 2.5,
      interval: 365,
      nextReviewAt: now.add(const Duration(days: 365)),
      lastReviewedAt: now,
      updatedAt: now,
    ));
  }

  @override
  Future<int> getDueCount({DateTime? asOf}) async {
    final items = await getDue(asOf: asOf, limit: 99999);
    return items.length;
  }

  @override
  Future<List<ReviewSchedule>> getByStatus(ReviewStatus status) async {
    // ReviewRepository doesn't expose a status filter directly — we fetch due
    // schedules with a generous limit and filter client-side. For an MVP this
    // is acceptable; a dedicated `getByStatus` DAO method can be added later.
    final all = await reviewRepository.getDue(
      asOf: DateTime.now().add(const Duration(days: 36500)),
      limit: 100000,
    );
    return all.where((s) => s.status == status).toList();
  }

  ReviewSchedule _newSchedule(String questionId) {
    final now = DateTime.now();
    return ReviewSchedule(
      id: '', // assigned by DB
      questionId: questionId,
      easeFactor: 2.5,
      interval: 0,
      repetitions: 0,
      nextReviewAt: now,
      lastReviewedAt: now,
      status: ReviewStatus.needsReview,
      createdAt: now,
      updatedAt: now,
    );
  }
}

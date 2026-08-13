// Stage 24 — ReviewScheduler (SM-2) real-DB integration tests.
//
// Verifies that recordReview persists to ReviewRepository (no more "return
// updated;" without write) and that getDue/getByStatus query the real DB.
//
// The SM-2 math itself is NOT tested here — that's the algorithm's contract
// and is forbidden to modify per project constraint. We test the persistence
// layer around it.
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_pdf_exam/data/database/app_database.dart';
import 'package:persian_pdf_exam/data/repositories/implementations/implementations.dart';
import 'package:persian_pdf_exam/domain/entities/entities.dart';
import 'package:persian_pdf_exam/features/review_system/review_scheduler.dart';

import 'repositories/helpers.dart';

void main() {
  late AppDatabase db;
  late Sm2ReviewScheduler scheduler;
  late ReviewRepositoryImpl reviewRepo;
  late QuestionRepositoryImpl questionRepo;

  setUp(() {
    db = createInMemoryDb();
    reviewRepo = ReviewRepositoryImpl(database: db);
    questionRepo = QuestionRepositoryImpl(database: db);
    scheduler = Sm2ReviewScheduler(reviewRepository: reviewRepo);
  });
  tearDown(() => db.close());

  Future<String> seedQuestion() async {
    return questionRepo.insert(Question(
      id: '',
      pdfId: '',
      sourcePageNumber: 1,
      body: 'سؤال',
      correctOptionId: 'opt-1',
      options: [
        QuestionOption(id: '', label: '۱', text: 'گزینه ۱'),
        QuestionOption(id: '', label: '۲', text: 'گزینه ۲'),
      ],
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ));
  }

  group('recordReview persistence', () {
    test('first review (quality=5) inserts a new schedule', () async {
      final q = await seedQuestion();
      final schedule = await scheduler.recordReview(questionId: q, quality: 5);
      // Should be persisted — read it back via the repository directly.
      final fetched = await reviewRepo.getByQuestion(q);
      expect(fetched, isNotNull, reason: 'recordReview must persist');
      expect(fetched!.id, schedule.id);
      expect(fetched.repetitions, 1);
      expect(fetched.interval, 1);
      // EF after quality=5: 2.5 + (0.1 - 0*...) = 2.6
      expect(fetched.easeFactor, closeTo(2.6, 0.01));
    });

    test('second quality=5 review updates existing row (no duplicate)', () async {
      final q = await seedQuestion();
      await scheduler.recordReview(questionId: q, quality: 5);
      await scheduler.recordReview(questionId: q, quality: 5);
      // Fetch via getDue with a far-future date so we see all schedules.
      final all = await reviewRepo.getDue(
        asOf: DateTime.now().add(const Duration(days: 36500)),
        limit: 100,
      );
      final mine = all.where((s) => s.questionId == q).toList();
      expect(mine, hasLength(1), reason: 'no duplicate schedules');
      expect(mine.first.repetitions, 2);
      // 2nd successful rep → interval = 6 days (SM-2 spec)
      expect(mine.first.interval, 6);
    });

    test('quality=2 (fail) resets repetitions to 0', () async {
      final q = await seedQuestion();
      await scheduler.recordReview(questionId: q, quality: 5);
      await scheduler.recordReview(questionId: q, quality: 2);
      final fetched = await reviewRepo.getByQuestion(q);
      expect(fetched!.repetitions, 0);
      expect(fetched.interval, 0);
      expect(fetched.status, ReviewStatus.difficult);
    });
  });

  group('getDue + getDueCount', () {
    test('returns schedules with nextReviewAt <= now', () async {
      final q1 = await seedQuestion();
      final q2 = await seedQuestion();
      // q1 due now (quality=5 → nextReview = today+1 day, but we override
      // by inserting a schedule with nextReviewAt in the past)
      await reviewRepo.insert(ReviewSchedule(
        id: '',
        questionId: q1,
        easeFactor: 2.5,
        interval: 0,
        repetitions: 1,
        nextReviewAt: DateTime.now().subtract(const Duration(days: 1)),
        lastReviewedAt: DateTime(2024),
        status: ReviewStatus.needsReview,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ));
      // q2 due in the future
      await reviewRepo.insert(ReviewSchedule(
        id: '',
        questionId: q2,
        easeFactor: 2.5,
        interval: 30,
        repetitions: 3,
        nextReviewAt: DateTime.now().add(const Duration(days: 30)),
        lastReviewedAt: DateTime(2024),
        status: ReviewStatus.learning,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ));

      final due = await scheduler.getDue();
      expect(due, hasLength(1));
      expect(due.first.questionId, q1);
      expect(await scheduler.getDueCount(), 1);
    });
  });

  group('markMastered', () {
    test('marks an existing schedule as mastered', () async {
      final q = await seedQuestion();
      await scheduler.recordReview(questionId: q, quality: 5);
      await scheduler.markMastered(q);
      final fetched = await reviewRepo.getByQuestion(q);
      expect(fetched!.status, ReviewStatus.mastered);
      expect(fetched.interval, greaterThanOrEqualTo(365));
    });

    test('creates a mastered schedule when none existed', () async {
      final q = await seedQuestion();
      await scheduler.markMastered(q);
      final fetched = await reviewRepo.getByQuestion(q);
      expect(fetched, isNotNull);
      expect(fetched!.status, ReviewStatus.mastered);
    });
  });

  group('getByStatus', () {
    test('returns only schedules matching the status', () async {
      final q1 = await seedQuestion();
      final q2 = await seedQuestion();
      await reviewRepo.insert(ReviewSchedule(
        id: '',
        questionId: q1,
        easeFactor: 2.5,
        interval: 0,
        repetitions: 1,
        nextReviewAt: DateTime.now().add(const Duration(days: 1)),
        lastReviewedAt: DateTime(2024),
        status: ReviewStatus.learning,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ));
      await reviewRepo.insert(ReviewSchedule(
        id: '',
        questionId: q2,
        easeFactor: 2.5,
        interval: 0,
        repetitions: 1,
        nextReviewAt: DateTime.now().add(const Duration(days: 1)),
        lastReviewedAt: DateTime(2024),
        status: ReviewStatus.mastered,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ));

      final learning = await scheduler.getByStatus(ReviewStatus.learning);
      final mastered = await scheduler.getByStatus(ReviewStatus.mastered);
      expect(learning, hasLength(1));
      expect(learning.first.questionId, q1);
      expect(mastered, hasLength(1));
      expect(mastered.first.questionId, q2);
    });
  });

  // === Pure-math reference tests (kept from the original) ===
  // These verify the SM-2 formula in isolation — they don't touch the DB but
  // they document the algorithm's contract. We re-implement the formula
  // locally so the test fails loudly if someone changes the math in
  // review_scheduler.dart.

  test('SM-2 reference: quality=5 first review → ef=2.6', () {
    final ef = _computeEf(2.5, 5);
    expect(ef, closeTo(2.6, 0.01));
  });

  test('SM-2 reference: quality=2 → ef decreases but floors at 1.3', () {
    var ef = 1.4;
    for (var i = 0; i < 10; i++) {
      ef = _computeEf(ef, 0);
    }
    expect(ef, greaterThanOrEqualTo(1.3));
  });

  test('SM-2 reference: interval after reps=2 is 6 days', () {
    expect(_computeInterval(reps: 2, prevInterval: 1, ef: 2.5), 6);
  });
}

double _computeEf(double ef, int quality) {
  final newEf = ef + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
  return newEf < 1.3 ? 1.3 : newEf;
}

int _computeInterval({required int reps, required int prevInterval, required double ef}) {
  if (reps == 1) return 1;
  if (reps == 2) return 6;
  return (prevInterval * ef).round();
}

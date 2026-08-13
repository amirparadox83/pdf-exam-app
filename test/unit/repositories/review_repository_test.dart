// Stage 09 — ReviewRepository tests
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_pdf_exam/data/database/app_database.dart';
import 'package:persian_pdf_exam/data/repositories/implementations/question_repository_impl.dart';
import 'package:persian_pdf_exam/data/repositories/implementations/review_repository_impl.dart';
import 'package:persian_pdf_exam/domain/entities/entities.dart';

import 'helpers.dart';

void main() {
  late AppDatabase db;
  late ReviewRepositoryImpl repo;
  late QuestionRepositoryImpl questionRepo;

  setUp(() {
    db = createInMemoryDb();
    repo = ReviewRepositoryImpl(database: db);
    questionRepo = QuestionRepositoryImpl(database: db);
  });

  tearDown(() => db.close());

  Future<void> _seedQuestion(String id) async {
    await questionRepo.insert(Question(
      id: id, pdfId: '', sourcePageNumber: 1, body: 'body',
      createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
  }

  ReviewSchedule _makeSchedule({
    String id = 'rs1',
    String questionId = 'q1',
    DateTime? nextReviewAt,
    ReviewStatus status = ReviewStatus.needsReview,
  }) {
    final now = DateTime(2024);
    return ReviewSchedule(
      id: id,
      questionId: questionId,
      easeFactor: 2.5,
      interval: 1,
      repetitions: 1,
      nextReviewAt: nextReviewAt ?? now,
      lastReviewedAt: now,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('insert + getByQuestion round-trips', () async {
    await _seedQuestion('q1');
    final id = await repo.insert(_makeSchedule());
    final fetched = await repo.getByQuestion('q1');
    expect(fetched, isNotNull);
    expect(fetched!.easeFactor, 2.5);
    expect(fetched.interval, 1);
    expect(fetched.repetitions, 1);
    expect(fetched.status, ReviewStatus.needsReview);
  });

  test('getDue returns only schedules with nextReviewAt <= asOf', () async {
    await _seedQuestion('q1');
    await _seedQuestion('q2');
    final now = DateTime(2024, 6, 15, 12);
    await repo.insert(_makeSchedule(
      id: 'rs1', questionId: 'q1',
      nextReviewAt: now.subtract(const Duration(days: 1)), // due
    ));
    await repo.insert(_makeSchedule(
      id: 'rs2', questionId: 'q2',
      nextReviewAt: now.add(const Duration(days: 1)), // not due yet
    ));
    final due = await repo.getDue(asOf: now);
    expect(due.length, 1);
    expect(due.first.id, 'rs1');
  });

  test('update mutates status and nextReviewAt', () async {
    await _seedQuestion('q1');
    final id = await repo.insert(_makeSchedule());
    final tomorrow = DateTime(2024, 6, 16);
    await repo.update(_makeSchedule(
      id: id,
      nextReviewAt: tomorrow,
      status: ReviewStatus.mastered,
    ));
    final fetched = await repo.getByQuestion('q1');
    expect(fetched!.status, ReviewStatus.mastered);
    expect(fetched.nextReviewAt, tomorrow);
  });

  test('delete removes the row', () async {
    await _seedQuestion('q1');
    final id = await repo.insert(_makeSchedule());
    await repo.delete(id);
    expect(await repo.getByQuestion('q1'), isNull);
  });
}

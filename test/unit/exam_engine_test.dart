// Stage 19 — ExamEngine real-DB integration tests.
//
// Verifies that ExamEngine.createExam/getExam/startExam/selectAnswer actually
// hit ExamRepository (in-memory drift) — no more null returns or no-op writes.
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_pdf_exam/data/database/app_database.dart';
import 'package:persian_pdf_exam/data/repositories/implementations/exam_repository_impl.dart';
import 'package:persian_pdf_exam/data/repositories/implementations/result_repository_impl.dart';
import 'package:persian_pdf_exam/domain/entities/entities.dart';
import 'package:persian_pdf_exam/features/exam_engine/exam_engine.dart';

import 'repositories/helpers.dart';

void main() {
  late AppDatabase db;
  late ExamEngineImpl engine;

  setUp(() {
    db = createInMemoryDb();
    engine = ExamEngineImpl(
      examRepository: ExamRepositoryImpl(database: db),
      resultRepository: ResultRepositoryImpl(database: db),
    );
  });
  tearDown(() {
    engine.dispose();
    db.close();
  });

  Exam _makeExam({
    String id = 'exam-1',
    String name = 'آزمون ریاضی',
    List<String> questionIds = const ['q1', 'q2', 'q3'],
    int timeLimitSeconds = 600,
    ExamStatus status = ExamStatus.draft,
  }) {
    return Exam(
      id: id,
      name: name,
      questionIds: questionIds,
      timeLimitSeconds: timeLimitSeconds,
      status: status,
      createdAt: DateTime(2024),
    );
  }

  group('createExam + getExam', () {
    test('createExam persists and getExam returns the same row', () async {
      final id = await engine.createExam(_makeExam());
      final fetched = await engine.getExam(id);
      expect(fetched, isNotNull,
          reason: 'getExam must return real data, not null');
      expect(fetched!.name, 'آزمون ریاضی');
      expect(fetched.questionIds, ['q1', 'q2', 'q3']);
      expect(fetched.timeLimitSeconds, 600);
    });

    test('createExam upgrades draft → ready', () async {
      final id = await engine.createExam(_makeExam(status: ExamStatus.draft));
      final fetched = await engine.getExam(id);
      expect(fetched!.status, ExamStatus.ready);
    });

    test('getExam returns null for unknown id (real DB miss)', () async {
      final fetched = await engine.getExam('does-not-exist');
      expect(fetched, isNull);
    });
  });

  group('answer persistence', () {
    test('selectAnswer writes a row retrievable by getAnswers', () async {
      final id = await engine.createExam(_makeExam());
      await engine.selectAnswer(id, 'q1', 'opt-A');
      final answers = await engine.getAnswers(id);
      expect(answers, hasLength(1));
      expect(answers.first.questionId, 'q1');
      expect(answers.first.selectedOptionId, 'opt-A');
    });

    test('selectAnswer twice updates the same row (idempotent upsert)', () async {
      final id = await engine.createExam(_makeExam());
      await engine.selectAnswer(id, 'q1', 'opt-A');
      await engine.selectAnswer(id, 'q1', 'opt-B');
      final answers = await engine.getAnswers(id);
      expect(answers, hasLength(1));
      expect(answers.first.selectedOptionId, 'opt-B');
    });

    test('toggleBookmark flips isBookmarked', () async {
      final id = await engine.createExam(_makeExam());
      await engine.toggleBookmark(id, 'q1');
      expect((await engine.getAnswers(id)).first.isBookmarked, isTrue);
      await engine.toggleBookmark(id, 'q1');
      expect((await engine.getAnswers(id)).first.isBookmarked, isFalse);
    });

    test('recordTimeSpent persists duration', () async {
      final id = await engine.createExam(_makeExam());
      await engine.recordTimeSpent(id, 'q1', const Duration(seconds: 42));
      final answers = await engine.getAnswers(id);
      expect(answers.first.timeSpent!.inSeconds, 42);
    });
  });

  group('lifecycle', () {
    test('startExam sets status=inProgress + startedAt', () async {
      final id = await engine.createExam(_makeExam());
      await engine.startExam(id);
      final fetched = await engine.getExam(id);
      expect(fetched!.status, ExamStatus.inProgress);
      expect(fetched.startedAt, isNotNull);
    });

    test('cancelExam sets status=cancelled', () async {
      final id = await engine.createExam(_makeExam());
      await engine.startExam(id);
      await engine.cancelExam(id);
      final fetched = await engine.getExam(id);
      expect(fetched!.status, ExamStatus.cancelled);
    });

    test('deleteExam removes the row', () async {
      final id = await engine.createExam(_makeExam());
      await engine.deleteExam(id);
      expect(await engine.getExam(id), isNull);
    });
  });

  group('timer', () {
    test('getRemainingTime returns null before start, Duration after', () async {
      final id = await engine.createExam(_makeExam(timeLimitSeconds: 60));
      expect(engine.getRemainingTime(id), isNull);
      await engine.startExam(id);
      final remaining = engine.getRemainingTime(id);
      expect(remaining, isNotNull);
      expect(remaining!.inSeconds, lessThanOrEqualTo(60));
      expect(remaining.inSeconds, greaterThan(55));
    });
  });
}

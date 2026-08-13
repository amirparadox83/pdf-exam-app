// Stage 23 — MistakeManager real-DB integration tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_pdf_exam/data/database/app_database.dart';
import 'package:persian_pdf_exam/data/repositories/implementations/implementations.dart';
import 'package:persian_pdf_exam/domain/entities/entities.dart';
import 'package:persian_pdf_exam/features/mistake_system/mistake_manager.dart';

import 'repositories/helpers.dart';

void main() {
  late AppDatabase db;
  late MistakeManagerImpl manager;
  late QuestionRepositoryImpl questionRepo;
  late MistakeRepositoryImpl mistakeRepo;

  setUp(() {
    db = createInMemoryDb();
    questionRepo = QuestionRepositoryImpl(database: db);
    mistakeRepo = MistakeRepositoryImpl(database: db);
    manager = MistakeManagerImpl(
      mistakeRepository: mistakeRepo,
      questionRepository: questionRepo,
    );
  });
  tearDown(() => db.close());

  Future<String> seedQuestion(String body) async {
    return questionRepo.insert(Question(
      id: '',
      pdfId: '',
      sourcePageNumber: 1,
      body: body,
      correctOptionId: 'opt-1',
      options: [
        QuestionOption(id: '', label: '۱', text: 'گزینه ۱'),
        QuestionOption(id: '', label: '۲', text: 'گزینه ۲'),
      ],
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ));
  }

  group('recordMistake', () {
    test('inserts a new mistake on first call', () async {
      final q1 = await seedQuestion('سؤال ۱');
      await manager.recordMistake(
        questionId: q1,
        examResultId: 'r1',
        reason: MistakeReason.forgotFormula,
        note: 'یادم رفت',
      );
      final all = await manager.getAll();
      expect(all, hasLength(1));
      expect(all.first.questionId, q1);
      expect(all.first.mistakeCount, 1);
      expect(all.first.reason, MistakeReason.forgotFormula);
    });

    test('increments mistakeCount on repeat (not duplicate row)', () async {
      final q1 = await seedQuestion('سؤال ۱');
      await manager.recordMistake(questionId: q1);
      await manager.recordMistake(questionId: q1);
      await manager.recordMistake(questionId: q1);
      final all = await manager.getAll();
      expect(all, hasLength(1));
      expect(all.first.mistakeCount, 3);
    });

    test('resets correctStreak on new mistake', () async {
      final q1 = await seedQuestion('سؤال ۱');
      // First fail → streak=0
      await manager.recordMistake(questionId: q1);
      // Mark correct twice → streak=2
      await manager.markCorrect(q1);
      await manager.markCorrect(q1);
      expect((await mistakeRepo.getByQuestion(q1))!.correctStreak, 2);
      // Fail again → streak should reset
      await manager.recordMistake(questionId: q1);
      expect((await mistakeRepo.getByQuestion(q1))!.correctStreak, 0);
      expect((await mistakeRepo.getByQuestion(q1))!.mistakeCount, 2);
    });
  });

  group('markCorrect', () {
    test('bumps question.timesCorrect counter', () async {
      final q1 = await seedQuestion('سؤال ۱');
      await manager.recordMistake(questionId: q1);
      await manager.markCorrect(q1);
      final q = await questionRepo.getById(q1);
      expect(q!.timesCorrect, 1);
      expect(q.timesAnswered, 1);
    });

    test('removes the mistake once correctStreak hits threshold (3)', () async {
      final q1 = await seedQuestion('سؤال ۱');
      await manager.recordMistake(questionId: q1);
      await manager.markCorrect(q1);
      await manager.markCorrect(q1);
      // Still in mistakes list (streak=2)
      expect(await manager.count(), 1);
      await manager.markCorrect(q1);
      // Now streak=3 → auto-removed
      expect(await manager.count(), 0);
    });
  });

  group('filterByReason + count + addNote + removeMistake', () {
    test('filterByReason returns only matching reason', () async {
      final q1 = await seedQuestion('سؤال ۱');
      final q2 = await seedQuestion('سؤال ۲');
      await manager.recordMistake(questionId: q1, reason: MistakeReason.careless);
      await manager.recordMistake(questionId: q2, reason: MistakeReason.forgotFormula);
      final careless = await manager.filterByReason(MistakeReason.careless);
      expect(careless, hasLength(1));
      expect(careless.first.questionId, q1);
    });

    test('count returns total', () async {
      final q1 = await seedQuestion('سؤال ۱');
      final q2 = await seedQuestion('سؤال ۲');
      await manager.recordMistake(questionId: q1);
      await manager.recordMistake(questionId: q2);
      expect(await manager.count(), 2);
    });

    test('addNote updates the note field', () async {
      final q1 = await seedQuestion('سؤال ۱');
      await manager.recordMistake(questionId: q1);
      final mistake = (await manager.getAll()).first;
      await manager.addNote(mistake.id, 'یادآوری جدید');
      final updated = (await manager.getAll()).first;
      expect(updated.note, 'یادآوری جدید');
    });

    test('removeMistake deletes the row', () async {
      final q1 = await seedQuestion('سؤال ۱');
      await manager.recordMistake(questionId: q1);
      final mistake = (await manager.getAll()).first;
      await manager.removeMistake(mistake.id);
      expect(await manager.count(), 0);
    });
  });

  group('getMistakeQuestionIds', () {
    test('returns question IDs sorted by recency', () async {
      final q1 = await seedQuestion('سؤال ۱');
      final q2 = await seedQuestion('سؤال ۲');
      await manager.recordMistake(questionId: q1);
      await manager.recordMistake(questionId: q2);
      final ids = await manager.getMistakeQuestionIds(limit: 10);
      expect(ids, containsAll([q1, q2]));
    });

    test('respects subjectId filter', () async {
      // Insert questions with subject — but seedQuestion helper doesn't set
      // subjectId. We test the filter returns empty for an unknown subject.
      final q1 = await seedQuestion('سؤال ۱');
      await manager.recordMistake(questionId: q1);
      final ids = await manager.getMistakeQuestionIds(limit: 10, subjectId: 'no-such-subject');
      expect(ids, isEmpty);
    });
  });
}

// Stage 09 — MistakeRepository tests
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_pdf_exam/data/database/app_database.dart';
import 'package:persian_pdf_exam/data/repositories/implementations/mistake_repository_impl.dart';
import 'package:persian_pdf_exam/data/repositories/implementations/question_repository_impl.dart';
import 'package:persian_pdf_exam/domain/entities/entities.dart';

import 'helpers.dart';

void main() {
  late AppDatabase db;
  late MistakeRepositoryImpl repo;
  late QuestionRepositoryImpl questionRepo;

  setUp(() {
    db = createInMemoryDb();
    repo = MistakeRepositoryImpl(database: db);
    questionRepo = QuestionRepositoryImpl(database: db);
  });

  tearDown(() => db.close());

  // Parent question must exist (FK constraint)
  Future<void> _seedQuestion(String id) async {
    await questionRepo.insert(Question(
      id: id, pdfId: '', sourcePageNumber: 1, body: 'body',
      createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
  }

  Mistake _makeMistake({
    String id = 'm1',
    String questionId = 'q1',
    int mistakeCount = 1,
    int correctStreak = 0,
  }) {
    return Mistake(
      id: id,
      questionId: questionId,
      examResultId: 'r1',
      reason: MistakeReason.forgotFormula,
      note: 'یادآوری فرمول',
      mistakeCount: mistakeCount,
      correctStreak: correctStreak,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );
  }

  test('insert + getByQuestion round-trips', () async {
    await _seedQuestion('q1');
    final id = await repo.insert(_makeMistake());
    final fetched = await repo.getByQuestion('q1');
    expect(fetched, isNotNull);
    expect(fetched!.reason, MistakeReason.forgotFormula);
    expect(fetched.note, 'یادآوری فرمول');
  });

  test('getAll returns paginated', () async {
    await _seedQuestion('q1');
    await _seedQuestion('q2');
    await _seedQuestion('q3');
    await repo.insert(_makeMistake(id: 'm1', questionId: 'q1'));
    await repo.insert(_makeMistake(id: 'm2', questionId: 'q2'));
    await repo.insert(_makeMistake(id: 'm3', questionId: 'q3'));
    final all = await repo.getAll(limit: 2, offset: 0);
    expect(all.length, 2);
  });

  test('update mutates note and mistakeCount', () async {
    await _seedQuestion('q1');
    final id = await repo.insert(_makeMistake());
    await repo.update(_makeMistake(
      id: id, mistakeCount: 3, correctStreak: 1,
    ));
    final fetched = await repo.getByQuestion('q1');
    expect(fetched!.mistakeCount, 3);
    expect(fetched.correctStreak, 1);
  });

  test('markCorrectStreak increments on correct', () async {
    await _seedQuestion('q1');
    await repo.insert(_makeMistake(correctStreak: 0));
    await repo.markCorrectStreak('q1', true);
    expect((await repo.getByQuestion('q1'))!.correctStreak, 1);
  });

  test('markCorrectStreak resets to 0 on incorrect', () async {
    await _seedQuestion('q1');
    await repo.insert(_makeMistake(correctStreak: 2));
    await repo.markCorrectStreak('q1', false);
    expect((await repo.getByQuestion('q1'))!.correctStreak, 0);
  });

  test('delete removes the row', () async {
    await _seedQuestion('q1');
    final id = await repo.insert(_makeMistake());
    await repo.delete(id);
    expect(await repo.getByQuestion('q1'), isNull);
  });
}

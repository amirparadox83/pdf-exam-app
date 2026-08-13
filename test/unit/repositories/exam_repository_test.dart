// Stage 09 — ExamRepository tests
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_pdf_exam/data/database/app_database.dart';
import 'package:persian_pdf_exam/data/repositories/implementations/exam_repository_impl.dart';
import 'package:persian_pdf_exam/domain/entities/entities.dart';

import 'helpers.dart';

void main() {
  late AppDatabase db;
  late ExamRepositoryImpl repo;

  setUp(() {
    db = createInMemoryDb();
    repo = ExamRepositoryImpl(database: db);
  });

  tearDown(() => db.close());

  Exam _makeExam({
    String id = 'e1',
    String name = 'آزمون ۱',
    List<String> questionIds = const ['q1', 'q2'],
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

  test('insert + getById round-trips', () async {
    final id = await repo.insert(_makeExam());
    final fetched = await repo.getById(id);
    expect(fetched, isNotNull);
    expect(fetched!.name, 'آزمون ۱');
    expect(fetched.questionIds, ['q1', 'q2']);
    expect(fetched.timeLimitSeconds, 600);
  });

  test('getAll returns paginated', () async {
    for (var i = 0; i < 3; i++) {
      await repo.insert(_makeExam(id: 'e$i', name: 'آزمون $i'));
    }
    final all = await repo.getAll(limit: 2, offset: 0);
    expect(all.length, 2);
  });

  test('update mutates status', () async {
    final id = await repo.insert(_makeExam());
    await repo.update(_makeExam(id: id, status: ExamStatus.submitted));
    final fetched = await repo.getById(id);
    expect(fetched!.status, ExamStatus.submitted);
  });

  test('saveAnswer + getAnswer round-trips', () async {
    await repo.insert(_makeExam());
    await repo.saveAnswer(ExamAnswer(
      examId: 'e1', questionId: 'q1',
      selectedOptionId: 'opt1',
      isBookmarked: true,
      timeSpent: const Duration(seconds: 30),
      updatedAt: DateTime(2024),
    ));
    final fetched = await repo.getAnswer('e1', 'q1');
    expect(fetched, isNotNull);
    expect(fetched!.selectedOptionId, 'opt1');
    expect(fetched.isBookmarked, isTrue);
    expect(fetched.timeSpent!.inSeconds, 30);
  });

  test('saveAnswer is idempotent (upsert)', () async {
    await repo.insert(_makeExam());
    await repo.saveAnswer(ExamAnswer(
      examId: 'e1', questionId: 'q1',
      selectedOptionId: 'opt1', updatedAt: DateTime(2024),
    ));
    await repo.saveAnswer(ExamAnswer(
      examId: 'e1', questionId: 'q1',
      selectedOptionId: 'opt2', updatedAt: DateTime(2024),
    ));
    final fetched = await repo.getAnswer('e1', 'q1');
    expect(fetched!.selectedOptionId, 'opt2');
  });

  test('getAnswers returns all answers for an exam', () async {
    await repo.insert(_makeExam());
    await repo.saveAnswer(ExamAnswer(
      examId: 'e1', questionId: 'q1', updatedAt: DateTime(2024)));
    await repo.saveAnswer(ExamAnswer(
      examId: 'e1', questionId: 'q2', updatedAt: DateTime(2024)));
    final answers = await repo.getAnswers('e1');
    expect(answers.length, 2);
  });

  test('clearAnswers removes all answers for an exam', () async {
    await repo.insert(_makeExam());
    await repo.saveAnswer(ExamAnswer(
      examId: 'e1', questionId: 'q1', updatedAt: DateTime(2024)));
    await repo.clearAnswers('e1');
    final answers = await repo.getAnswers('e1');
    expect(answers, isEmpty);
  });

  test('delete removes exam and its answers', () async {
    final id = await repo.insert(_makeExam());
    await repo.saveAnswer(ExamAnswer(
      examId: id, questionId: 'q1', updatedAt: DateTime(2024)));
    await repo.delete(id);
    expect(await repo.getById(id), isNull);
    expect(await repo.getAnswers(id), isEmpty);
  });
}

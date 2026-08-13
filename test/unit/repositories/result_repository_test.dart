// Stage 09 — ResultRepository tests
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_pdf_exam/data/database/app_database.dart';
import 'package:persian_pdf_exam/data/repositories/implementations/exam_repository_impl.dart';
import 'package:persian_pdf_exam/data/repositories/implementations/result_repository_impl.dart';
import 'package:persian_pdf_exam/domain/entities/entities.dart';

import 'helpers.dart';

void main() {
  late AppDatabase db;
  late ExamRepositoryImpl examRepo;
  late ResultRepositoryImpl repo;

  setUp(() {
    db = createInMemoryDb();
    examRepo = ExamRepositoryImpl(database: db);
    repo = ResultRepositoryImpl(database: db);
  });

  tearDown(() => db.close());

  ExamResult _makeResult({String id = 'r1', String examId = 'e1'}) {
    return ExamResult(
      id: id,
      examId: examId,
      totalQuestions: 10,
      correctCount: 7,
      incorrectCount: 2,
      unansweredCount: 1,
      rawScore: 6.5,
      percentage: 65.0,
      accuracy: 77.7,
      answeredAccuracy: 87.5,
      totalTime: const Duration(minutes: 30),
      averageTimePerQuestion: const Duration(seconds: 180),
      gradingConfig: {'negativeMarking': true, 'ratio': 0.25},
      questions: [
        ResultQuestion(
          questionId: 'q1',
          selectedOptionId: 'opt1',
          correctOptionId: 'opt1',
          isCorrect: true,
          isUnanswered: false,
          score: 1.0,
          timeSpent: const Duration(seconds: 60),
        ),
      ],
      submittedAt: DateTime(2024),
    );
  }

  // Parent exam must exist (FK constraint)
  Future<void> _seedExam(String examId) async {
    await examRepo.insert(Exam(
      id: examId,
      name: 'آزمون',
      questionIds: ['q1'],
      timeLimitSeconds: 600,
      status: ExamStatus.submitted,
      createdAt: DateTime(2024),
      submittedAt: DateTime(2024),
    ));
  }

  test('insert + getById round-trips with JSON fields', () async {
    await _seedExam('e1');
    final id = await repo.insert(_makeResult());
    final fetched = await repo.getById(id);
    expect(fetched, isNotNull);
    expect(fetched!.totalQuestions, 10);
    expect(fetched.correctCount, 7);
    expect(fetched.gradingConfig['negativeMarking'], isTrue);
    expect(fetched.questions.length, 1);
    expect(fetched.questions.first.questionId, 'q1');
    expect(fetched.totalTime.inMinutes, 30);
  });

  test('getAll returns paginated list', () async {
    await _seedExam('e1');
    await repo.insert(_makeResult(id: 'r1'));
    await repo.insert(_makeResult(id: 'r2'));
    final all = await repo.getAll(limit: 1, offset: 0);
    expect(all.length, 1);
  });

  test('delete removes the row', () async {
    await _seedExam('e1');
    final id = await repo.insert(_makeResult());
    await repo.delete(id);
    expect(await repo.getById(id), isNull);
  });
}

// Stage 22 — AnalyticsEngine real-DB integration tests.
//
// Seeds real ExamResult + Question + Mistake rows via the repositories, then
// verifies AnalyticsEngine returns non-zero aggregates (no empty lists).
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_pdf_exam/data/database/app_database.dart';
import 'package:persian_pdf_exam/data/repositories/implementations/implementations.dart';
import 'package:persian_pdf_exam/domain/entities/entities.dart';
import 'package:persian_pdf_exam/features/analytics_engine/analytics_engine.dart';

import 'repositories/helpers.dart';

void main() {
  late AppDatabase db;
  late AnalyticsEngineImpl engine;
  late ExamRepositoryImpl examRepo;
  late ResultRepositoryImpl resultRepo;
  late QuestionRepositoryImpl questionRepo;
  late MistakeRepositoryImpl mistakeRepo;
  late SubjectRepositoryImpl subjectRepo;

  setUp(() {
    db = createInMemoryDb();
    examRepo = ExamRepositoryImpl(database: db);
    resultRepo = ResultRepositoryImpl(database: db);
    questionRepo = QuestionRepositoryImpl(database: db);
    mistakeRepo = MistakeRepositoryImpl(database: db);
    subjectRepo = SubjectRepositoryImpl(database: db);
    engine = AnalyticsEngineImpl(
      resultRepository: resultRepo,
      questionRepository: questionRepo,
      mistakeRepository: mistakeRepo,
      subjectRepository: subjectRepo,
    );
  });
  tearDown(() => db.close());

  Future<void> seedSubject(String id, String name) async {
    await subjectRepo.insert(Subject(
      id: id,
      name: name,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ));
  }

  Future<String> seedQuestion({String? subjectId, String body = 'سؤال'}) async {
    return questionRepo.insert(Question(
      id: '',
      pdfId: '',
      sourcePageNumber: 1,
      body: body,
      subjectId: subjectId,
      correctOptionId: 'opt-1',
      options: [
        QuestionOption(id: '', label: '۱', text: 'گزینه ۱'),
        QuestionOption(id: '', label: '۲', text: 'گزینه ۲'),
      ],
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ));
  }

  Future<String> seedExam() async {
    return examRepo.insert(Exam(
      id: '',
      name: 'آزمون',
      questionIds: [],
      timeLimitSeconds: 600,
      status: ExamStatus.submitted,
      createdAt: DateTime(2024),
    ));
  }

  Future<String> seedResult({
    required String examId,
    required List<ResultQuestion> questions,
    int correct = 0,
    int incorrect = 0,
    int unanswered = 0,
  }) async {
    return resultRepo.insert(ExamResult(
      id: '',
      examId: examId,
      totalQuestions: questions.length,
      correctCount: correct,
      incorrectCount: incorrect,
      unansweredCount: unanswered,
      rawScore: correct.toDouble(),
      percentage: questions.isEmpty ? 0 : (correct / questions.length) * 100,
      accuracy: questions.isEmpty ? 0 : correct / questions.length,
      answeredAccuracy: (correct + incorrect) == 0 ? 0 : correct / (correct + incorrect),
      totalTime: const Duration(seconds: 300),
      averageTimePerQuestion: const Duration(seconds: 30),
      gradingConfig: {},
      questions: questions,
      submittedAt: DateTime(2024),
    ));
  }

  test('getOverallStats returns zeros on empty DB', () async {
    final stats = await engine.getOverallStats();
    expect(stats.totalExams, 0);
    expect(stats.totalQuestions, 0);
    expect(stats.overallAccuracy, 0);
  });

  test('getOverallStats returns non-zero after seeding', () async {
    final q1 = await seedQuestion(body: '۲+۲؟');
    final q2 = await seedQuestion(body: '۳+۳؟');
    final examId = await seedExam();
    await seedResult(
      examId: examId,
      correct: 1,
      incorrect: 1,
      unanswered: 0,
      questions: [
        ResultQuestion(
          questionId: q1,
          selectedOptionId: 'opt-1',
          correctOptionId: 'opt-1',
          isCorrect: true,
          isUnanswered: false,
          score: 1,
          timeSpent: const Duration(seconds: 10),
        ),
        ResultQuestion(
          questionId: q2,
          selectedOptionId: 'opt-2',
          correctOptionId: 'opt-1',
          isCorrect: false,
          isUnanswered: false,
          score: 0,
          timeSpent: const Duration(seconds: 20),
        ),
      ],
    );

    final stats = await engine.getOverallStats();
    expect(stats.totalExams, 1);
    expect(stats.totalQuestions, 2);
    expect(stats.overallAccuracy, closeTo(0.5, 0.001));
    expect(stats.averageTimePerQuestion.inSeconds, 15);
  });

  test('getStatsBySubject aggregates per-subject', () async {
    await seedSubject('s1', 'ریاضی');
    await seedSubject('s2', 'فیزیک');
    final q1 = await seedQuestion(subjectId: 's1', body: 'ریاضی ۱');
    final q2 = await seedQuestion(subjectId: 's2', body: 'فیزیک ۱');
    final examId = await seedExam();
    await seedResult(
      examId: examId,
      correct: 1,
      incorrect: 1,
      questions: [
        ResultQuestion(
          questionId: q1,
          selectedOptionId: 'opt-1',
          correctOptionId: 'opt-1',
          isCorrect: true,
          isUnanswered: false,
          score: 1,
          timeSpent: const Duration(seconds: 5),
        ),
        ResultQuestion(
          questionId: q2,
          selectedOptionId: 'opt-2',
          correctOptionId: 'opt-1',
          isCorrect: false,
          isUnanswered: false,
          score: 0,
          timeSpent: const Duration(seconds: 25),
        ),
      ],
    );

    final stats = await engine.getStatsBySubject();
    expect(stats, hasLength(2));
    final math = stats.firstWhere((s) => s.subjectId == 's1');
    final phys = stats.firstWhere((s) => s.subjectId == 's2');
    expect(math.correct, 1);
    expect(math.accuracy, 1.0);
    expect(phys.correct, 0);
    expect(phys.accuracy, 0.0);
  });

  test('getScoreTrend groups results by day', () async {
    final q1 = await seedQuestion();
    final examId = await seedExam();
    await seedResult(
      examId: examId,
      correct: 1,
      questions: [
        ResultQuestion(
          questionId: q1,
          selectedOptionId: 'opt-1',
          correctOptionId: 'opt-1',
          isCorrect: true,
          isUnanswered: false,
          score: 1,
          timeSpent: const Duration(seconds: 5),
        ),
      ],
    );
    final trend = await engine.getScoreTrend();
    expect(trend, isNotEmpty);
    expect(trend.first.score, greaterThanOrEqualTo(0));
  });

  test('getRepeatedMistakes returns real mistakes sorted by count', () async {
    final q1 = await seedQuestion(body: 'سؤال دشوار');
    final q2 = await seedQuestion(body: 'سؤال آسان');
    await mistakeRepo.insert(Mistake(
      id: '',
      questionId: q1,
      examResultId: 'r1',
      reason: MistakeReason.forgotFormula,
      mistakeCount: 5,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ));
    await mistakeRepo.insert(Mistake(
      id: '',
      questionId: q2,
      examResultId: 'r1',
      reason: MistakeReason.careless,
      mistakeCount: 2,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ));

    final repeated = await engine.getRepeatedMistakes(limit: 5);
    expect(repeated, hasLength(2));
    expect(repeated.first.mistakeCount, 5);
    expect(repeated.first.bodyPreview, contains('دشوار'));
  });

  test('getStrongestTopics + getWeakestTopics order by accuracy', () async {
    await seedSubject('s1', 'قوی');
    await seedSubject('s2', 'ضعیف');
    final q1 = await seedQuestion(subjectId: 's1', body: 'قوی');
    final q2 = await seedQuestion(subjectId: 's2', body: 'ضعیف');
    final examId = await seedExam();
    await seedResult(
      examId: examId,
      correct: 1,
      incorrect: 1,
      questions: [
        ResultQuestion(
          questionId: q1,
          selectedOptionId: 'opt-1',
          correctOptionId: 'opt-1',
          isCorrect: true,
          isUnanswered: false,
          score: 1,
          timeSpent: const Duration(seconds: 5),
        ),
        ResultQuestion(
          questionId: q2,
          selectedOptionId: 'opt-2',
          correctOptionId: 'opt-1',
          isCorrect: false,
          isUnanswered: false,
          score: 0,
          timeSpent: const Duration(seconds: 5),
        ),
      ],
    );

    final strongest = await engine.getStrongestTopics();
    final weakest = await engine.getWeakestTopics();
    expect(strongest, isNotEmpty);
    expect(weakest, isNotEmpty);
    expect(strongest.first.accuracy, greaterThanOrEqualTo(weakest.first.accuracy));
  });
}

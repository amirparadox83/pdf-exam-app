// Stage 28 — Grading Engine Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_pdf_exam/features/grading/grading_engine.dart';
import 'package:persian_pdf_exam/domain/entities/entities.dart';

void main() {
  late GradingEngineImpl engine;

  setUp(() {
    engine = GradingEngineImpl();
  });

  Exam _makeExam({
    bool negativeMarking = false,
    double ratio = 0.25,
  }) =>
      Exam(
        id: 'exam-1',
        name: 'Test',
        questionIds: ['q1', 'q2', 'q3', 'q4'],
        timeLimitSeconds: 600,
        negativeMarkingEnabled: negativeMarking,
        negativeMarkingRatio: ratio,
        shuffleQuestions: false,
        shuffleOptions: false,
        status: ExamStatus.submitted,
        createdAt: DateTime.now(),
      );

  List<Question> _makeQuestions() => [
        Question(
          id: 'q1', pdfId: 'p1', sourcePageNumber: 1, body: 'Q1',
          options: [
            QuestionOption(id: 'o1', label: 'الف', text: 'A', order: 0),
            QuestionOption(id: 'o2', label: 'ب', text: 'B', order: 1),
            QuestionOption(id: 'o3', label: 'ج', text: 'C', order: 2),
            QuestionOption(id: 'o4', label: 'د', text: 'D', order: 3),
          ],
          correctOptionId: 'o2',
          createdAt: DateTime.now(), updatedAt: DateTime.now(),
        ),
        Question(
          id: 'q2', pdfId: 'p1', sourcePageNumber: 1, body: 'Q2',
          options: [
            QuestionOption(id: 'o5', label: 'الف', text: 'A', order: 0),
            QuestionOption(id: 'o6', label: 'ب', text: 'B', order: 1),
          ],
          correctOptionId: 'o5',
          createdAt: DateTime.now(), updatedAt: DateTime.now(),
        ),
        Question(
          id: 'q3', pdfId: 'p1', sourcePageNumber: 1, body: 'Q3',
          options: [
            QuestionOption(id: 'o9', label: 'الف', text: 'A', order: 0),
            QuestionOption(id: 'o10', label: 'ب', text: 'B', order: 1),
          ],
          correctOptionId: 'o9',
          createdAt: DateTime.now(), updatedAt: DateTime.now(),
        ),
        Question(
          id: 'q4', pdfId: 'p1', sourcePageNumber: 1, body: 'Q4',
          options: [
            QuestionOption(id: 'o13', label: 'الف', text: 'A', order: 0),
            QuestionOption(id: 'o14', label: 'ب', text: 'B', order: 1),
          ],
          correctOptionId: 'o14',
          createdAt: DateTime.now(), updatedAt: DateTime.now(),
        ),
      ];

  test('all correct → 100%', () {
    final questions = _makeQuestions();
    final answers = {
      'q1': ExamAnswer(examId: 'exam-1', questionId: 'q1', selectedOptionId: 'o2', updatedAt: DateTime.now()),
      'q2': ExamAnswer(examId: 'exam-1', questionId: 'q2', selectedOptionId: 'o5', updatedAt: DateTime.now()),
      'q3': ExamAnswer(examId: 'exam-1', questionId: 'q3', selectedOptionId: 'o9', updatedAt: DateTime.now()),
      'q4': ExamAnswer(examId: 'exam-1', questionId: 'q4', selectedOptionId: 'o14', updatedAt: DateTime.now()),
    };
    final result = engine.grade(
      exam: _makeExam(),
      questions: questions,
      answers: answers,
      totalTime: const Duration(minutes: 10),
    );
    expect(result.correctCount, 4);
    expect(result.incorrectCount, 0);
    expect(result.unansweredCount, 0);
    expect(result.percentage, 100);
    expect(result.accuracy, 1.0);
  });

  test('all unanswered → 0% accuracy, 0% answeredAccuracy', () {
    final questions = _makeQuestions();
    final answers = <String, ExamAnswer>{};
    final result = engine.grade(
      exam: _makeExam(),
      questions: questions,
      answers: answers,
      totalTime: const Duration(minutes: 10),
    );
    expect(result.correctCount, 0);
    expect(result.unansweredCount, 4);
    expect(result.accuracy, 0);
    expect(result.answeredAccuracy, 0);
  });

  test('negative marking reduces score', () {
    final questions = _makeQuestions();
    final answers = {
      'q1': ExamAnswer(examId: 'exam-1', questionId: 'q1', selectedOptionId: 'o2', updatedAt: DateTime.now()), // correct
      'q2': ExamAnswer(examId: 'exam-1', questionId: 'q2', selectedOptionId: 'o6', updatedAt: DateTime.now()), // wrong
    };
    final result = engine.grade(
      exam: _makeExam(negativeMarking: true, ratio: 0.25),
      questions: questions,
      answers: answers,
      totalTime: const Duration(minutes: 10),
    );
    expect(result.correctCount, 1);
    expect(result.incorrectCount, 1);
    expect(result.unansweredCount, 2);
    // raw = 1 - 0.25 = 0.75; percentage = 0.75/4 * 100 = 18.75
    expect(result.rawScore, 0.75);
  });

  test('grading config is stored in result', () {
    final questions = _makeQuestions();
    final exam = _makeExam(negativeMarking: true);
    final result = engine.grade(
      exam: exam,
      questions: questions,
      answers: {},
      totalTime: Duration.zero,
    );
    expect(result.gradingConfig['negativeMarkingEnabled'], true);
    expect(result.gradingConfig['negativeMarkingRatio'], 0.25);
  });

  test('average time per question computed correctly', () {
    final questions = _makeQuestions();
    final result = engine.grade(
      exam: _makeExam(),
      questions: questions,
      answers: {},
      totalTime: const Duration(minutes: 8), // 480s / 4 = 120s
    );
    expect(result.averageTimePerQuestion.inSeconds, 120);
  });
}

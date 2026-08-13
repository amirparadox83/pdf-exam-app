/// Grading Engine — Stage 20
/// Deterministic grading with positive/negative scoring.
import '../../domain/entities/entities.dart';

abstract class GradingEngine {
  ExamResult grade({
    required Exam exam,
    required List<Question> questions,
    required Map<String, ExamAnswer> answers,
    required Duration totalTime,
  });
}

class GradingEngineImpl implements GradingEngine {
  @override
  ExamResult grade({
    required Exam exam,
    required List<Question> questions,
    required Map<String, ExamAnswer> answers,
    required Duration totalTime,
  }) {
    int correct = 0;
    int incorrect = 0;
    int unanswered = 0;
    final resultQuestions = <ResultQuestion>[];

    for (final q in questions) {
      final ans = answers[q.id];
      final isUnanswered = ans?.selectedOptionId == null;
      final isCorrect = !isUnanswered && ans!.selectedOptionId == q.correctOptionId;

      double score;
      if (isUnanswered) {
        unanswered++;
        score = 0;
      } else if (isCorrect) {
        correct++;
        score = 1.0;
      } else {
        incorrect++;
        score = exam.negativeMarkingEnabled ? -exam.negativeMarkingRatio : 0.0;
      }

      resultQuestions.add(ResultQuestion(
        questionId: q.id,
        selectedOptionId: ans?.selectedOptionId,
        correctOptionId: q.correctOptionId ?? '',
        isCorrect: isCorrect,
        isUnanswered: isUnanswered,
        score: score,
        timeSpent: ans?.timeSpent ?? Duration.zero,
      ));
    }

    final rawScore = resultQuestions.fold<double>(0, (a, q) => a + q.score);
    final percentage = (rawScore / questions.length) * 100;
    final answered = correct + incorrect;
    final accuracy = questions.isEmpty ? 0.0 : correct / questions.length;
    final answeredAccuracy = answered == 0 ? 0.0 : correct / answered;
    final avgTime = totalTime ~/ (questions.isEmpty ? 1 : questions.length);

    return ExamResult(
      id: '', // assigned by repository
      examId: exam.id,
      totalQuestions: questions.length,
      correctCount: correct,
      incorrectCount: incorrect,
      unansweredCount: unanswered,
      rawScore: rawScore,
      percentage: percentage,
      accuracy: accuracy,
      answeredAccuracy: answeredAccuracy,
      totalTime: totalTime,
      averageTimePerQuestion: avgTime,
      gradingConfig: {
        'negativeMarkingEnabled': exam.negativeMarkingEnabled,
        'negativeMarkingRatio': exam.negativeMarkingRatio,
        'shuffleQuestions': exam.shuffleQuestions,
        'shuffleOptions': exam.shuffleOptions,
      },
      questions: resultQuestions,
      submittedAt: DateTime.now(),
    );
  }
}

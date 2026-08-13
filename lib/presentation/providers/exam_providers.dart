/// Exam-taking screen providers.
/// Stage 18 / 19 / 20 / 21 — wire ExamEngine + GradingEngine to the UI.
library presentation.providers.exam_providers;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_state_notifier/riverpod_state_notifier.dart';

import '../../domain/entities/entities.dart';
import 'core_providers.dart';

/// Active exam session — held in memory between ExamPreparation and SubmitConfirmation.
/// Set by ExamPreparationScreen.startExam, read by ExamScreen + SubmitConfirmationScreen.
class ExamSession {
  final String examId;
  final Exam exam;
  final List<Question> questions;
  final Map<String, ExamAnswer> answersById; // questionId → answer

  const ExamSession({
    required this.examId,
    required this.exam,
    required this.questions,
    required this.answersById,
  });

  ExamSession copyWith({
    Map<String, ExamAnswer>? answersById,
  }) =>
      ExamSession(
        examId: examId,
        exam: exam,
        questions: questions,
        answersById: answersById ?? this.answersById,
      );

  static ExamSession get empty => ExamSession(
        examId: '',
        exam: Exam(
          id: '',
          name: '',
          questionIds: [],
          timeLimitSeconds: 0,
          status: ExamStatus.draft,
          createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        ),
        questions: [],
        answersById: {},
      );
}

class ExamSessionNotifier extends StateNotifier<ExamSession> {
  final Ref ref;
  ExamSessionNotifier(this.ref) : super(ExamSession.empty);

  void set(Exam exam, List<Question> questions, Map<String, ExamAnswer> answers) {
    state = ExamSession(
      examId: exam.id,
      exam: exam,
      questions: questions,
      answersById: Map.from(answers),
    );
  }

  void upsertAnswer(String questionId, ExamAnswer answer) {
    final updated = Map<String, ExamAnswer>.from(state.answersById);
    updated[questionId] = answer;
    state = state.copyWith(answersById: updated);
  }

  void clear() {
    state = ExamSession.empty;
  }
}

final examSessionProvider =
    StateNotifierProvider<ExamSessionNotifier, ExamSession>(
  (ref) => ExamSessionNotifier(ref),
);

/// Load an exam (and its questions) by ID — used by ExamPreparationScreen.
final examByIdProvider =
    FutureProvider.family<({Exam exam, List<Question> questions})?, String>(
  (ref, examId) async {
    if (examId.isEmpty) return null;
    final container = ref.watch(serviceContainerProvider);
    final exam = await container.examRepository.getById(examId);
    if (exam == null) return null;
    final questions = <Question>[];
    for (final qid in exam.questionIds) {
      final q = await container.questionRepository.getById(qid);
      if (q != null) questions.add(q);
    }
    return (exam: exam, questions: questions);
  },
);

/// Load an ExamResult by ID — used by ResultsScreen.
final resultByIdProvider =
    FutureProvider.family<ExamResult?, String>(
  (ref, resultId) async {
    if (resultId.isEmpty) return null;
    final container = ref.watch(serviceContainerProvider);
    return container.resultRepository.getById(resultId);
  },
);

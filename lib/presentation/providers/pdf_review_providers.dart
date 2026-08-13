/// PDF review session providers.
/// Stage 16 — PDF Review
///
/// Holds the result of the most recent PDF processing pipeline run
/// (PDF → blocks → parsed questions) plus the persisted PdfSource ID and an
/// optional resolved Subject ID. The PdfReviewScreen reads from
/// `pdfReviewSessionProvider` to display real `DetectedQuestion` entities.
library presentation.providers.pdf_review_providers;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_notifier_compat.dart';

import '../../features/question_parser/question_parser.dart';

/// Holds the most recent batch of detected questions from the parser.
class PdfReviewSession {
  final String pdfPath;
  final String pdfName;
  final String pdfId;          // persisted PdfSource.id (empty if not yet saved)
  final String? subjectId;     // resolved Subject.id (null = unassigned)
  final List<DetectedQuestion> questions;

  const PdfReviewSession({
    required this.pdfPath,
    required this.pdfName,
    required this.pdfId,
    required this.subjectId,
    required this.questions,
  });

  static const empty = PdfReviewSession(
    pdfPath: '',
    pdfName: '',
    pdfId: '',
    subjectId: null,
    questions: [],
  );
}

class PdfReviewSessionNotifier extends StateNotifier<PdfReviewSession> {
  PdfReviewSessionNotifier() : super(PdfReviewSession.empty);

  void set({
    required String pdfPath,
    required String pdfName,
    required String pdfId,
    required String? subjectId,
    required List<DetectedQuestion> questions,
  }) {
    state = PdfReviewSession(
      pdfPath: pdfPath,
      pdfName: pdfName,
      pdfId: pdfId,
      subjectId: subjectId,
      questions: questions,
    );
  }

  void clear() {
    state = PdfReviewSession.empty;
  }
}

final pdfReviewSessionProvider =
    stateNotifierProvider<PdfReviewSessionNotifier, PdfReviewSession>(
  (ref) => PdfReviewSessionNotifier(),
);

/// Derived counts for the summary header.
final pdfReviewSummaryProvider = Provider<PdfReviewSummary>(
  (ref) {
    final PdfReviewSession session = ref.watch(pdfReviewSessionProvider);
    var valid = 0;
    var suspicious = 0;
    var invalid = 0;
    var noAnswer = 0;
    for (final q in session.questions) {
      switch (q.status) {
        case QuestionStatus.valid:
          valid++;
          break;
        case QuestionStatus.suspicious:
          suspicious++;
          break;
        case QuestionStatus.invalid:
          invalid++;
          break;
        case QuestionStatus.needsReview:
          valid++;
          break;
      }
      if (q.options.isEmpty) {
        noAnswer++;
      }
    }
    return PdfReviewSummary(
      total: session.questions.length,
      valid: valid,
      suspicious: suspicious,
      invalid: invalid,
      noAnswer: noAnswer,
    );
  },
);

class PdfReviewSummary {
  final int total;
  final int valid;
  final int suspicious;
  final int invalid;
  final int noAnswer;

  const PdfReviewSummary({
    required this.total,
    required this.valid,
    required this.suspicious,
    required this.invalid,
    required this.noAnswer,
  });
}

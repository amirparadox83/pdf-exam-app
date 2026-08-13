/// GoRouter-style router using Navigator 2.0 (simplified for MVP)
/// Stage 04 — Project Foundation
/// Stage 05 — Architecture skeleton
/// Stage 07 — UI/UX navigation
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/import_pdf/import_pdf_screen.dart';
import '../screens/processing/processing_screen.dart';
import '../screens/pdf_review/pdf_review_screen.dart';
import '../screens/question_review/question_review_screen.dart';
import '../screens/question_editor/question_editor_screen.dart';
import '../screens/question_bank/question_bank_screen.dart';
import '../screens/question_detail/question_detail_screen.dart';
import '../screens/exam_builder/exam_builder_screen.dart';
import '../screens/exam_preparation/exam_preparation_screen.dart';
import '../screens/exam/exam_screen.dart';
import '../screens/question_navigator/question_navigator_screen.dart';
import '../screens/submit_confirmation/submit_confirmation_screen.dart';
import '../screens/results/results_screen.dart';
import '../screens/results_review/results_review_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/mistake_notebook/mistake_notebook_screen.dart';
import '../screens/review_session/review_session_screen.dart';
import '../screens/backup_restore/backup_restore_screen.dart';
import '../screens/settings/settings_screen.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.importPdf,
        builder: (context, state) => const ImportPdfScreen(),
      ),
      GoRoute(
        path: AppRoutes.processing,
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>?;
          return ProcessingScreen(params: params ?? {});
        },
      ),
      GoRoute(
        path: AppRoutes.pdfReview,
        builder: (context, state) => const PdfReviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.questionReview,
        builder: (context, state) {
          final questionId = state.pathParameters['questionId'];
          return QuestionReviewScreen(questionId: questionId);
        },
      ),
      GoRoute(
        path: AppRoutes.questionEditor,
        builder: (context, state) {
          final questionId = state.pathParameters['questionId'];
          return QuestionEditorScreen(questionId: questionId);
        },
      ),
      GoRoute(
        path: AppRoutes.questionBank,
        builder: (context, state) => const QuestionBankScreen(),
      ),
      GoRoute(
        path: AppRoutes.questionDetail,
        builder: (context, state) {
          final questionId = state.pathParameters['questionId'];
          return QuestionDetailScreen(questionId: questionId);
        },
      ),
      GoRoute(
        path: AppRoutes.examBuilder,
        builder: (context, state) => const ExamBuilderScreen(),
      ),
      GoRoute(
        path: AppRoutes.examPreparation,
        builder: (context, state) {
          final examId = state.pathParameters['examId'];
          return ExamPreparationScreen(examId: examId);
        },
      ),
      GoRoute(
        path: AppRoutes.exam,
        builder: (context, state) {
          final examId = state.pathParameters['examId'];
          return ExamScreen(examId: examId);
        },
      ),
      GoRoute(
        path: AppRoutes.questionNavigator,
        builder: (context, state) {
          final examId = state.pathParameters['examId'];
          return QuestionNavigatorScreen(examId: examId);
        },
      ),
      GoRoute(
        path: AppRoutes.submitConfirmation,
        builder: (context, state) {
          final examId = state.pathParameters['examId'];
          return SubmitConfirmationScreen(examId: examId);
        },
      ),
      GoRoute(
        path: AppRoutes.results,
        builder: (context, state) {
          final resultId = state.pathParameters['resultId'];
          return ResultsScreen(resultId: resultId);
        },
      ),
      GoRoute(
        path: AppRoutes.resultsReview,
        builder: (context, state) {
          final resultId = state.pathParameters['resultId'];
          return ResultsReviewScreen(resultId: resultId);
        },
      ),
      GoRoute(
        path: AppRoutes.analytics,
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.mistakeNotebook,
        builder: (context, state) => const MistakeNotebookScreen(),
      ),
      GoRoute(
        path: AppRoutes.reviewSession,
        builder: (context, state) => const ReviewSessionScreen(),
      ),
      GoRoute(
        path: AppRoutes.backupRestore,
        builder: (context, state) => const BackupRestoreScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('خطا')),
      body: Center(child: Text('صفحه یافت نشد: ${state.uri}')),
    ),
  );
});

/// All route paths in the application
/// Stage 04 — Project Foundation
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String home = '/home';
  static const String importPdf = '/import-pdf';
  static const String processing = '/processing';
  static const String pdfReview = '/pdf-review';
  static const String questionReview = '/question-review/:questionId';
  static const String questionEditor = '/question-editor/:questionId';
  static const String questionBank = '/question-bank';
  static const String questionDetail = '/question-detail/:questionId';
  static const String examBuilder = '/exam-builder';
  static const String examPreparation = '/exam-preparation/:examId';
  static const String exam = '/exam/:examId';
  static const String questionNavigator = '/question-navigator/:examId';
  static const String submitConfirmation = '/submit-confirmation/:examId';
  static const String results = '/results/:resultId';
  static const String resultsReview = '/results-review/:resultId';
  static const String analytics = '/analytics';
  static const String mistakeNotebook = '/mistakes';
  static const String reviewSession = '/review';
  static const String backupRestore = '/backup';
  static const String settings = '/settings';
}

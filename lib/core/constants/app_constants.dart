/// App-wide constants
/// Stage 04 — Project Foundation
class AppConstants {
  AppConstants._();

  static const String appName = 'آزمون PDF';
  static const String appNameEn = 'Persian PDF Exam';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  // Storage
  static const String permanentDir = 'permanent';
  static const String tempDir = 'temp';
  static const String cacheDir = 'cache';
  static const String backupDir = 'backups';

  // Database
  static const String dbName = 'persian_pdf_exam.db';

  // Backup
  static const String backupExtension = '.pexam';
  static const int backupFormatVersion = 1;

  // Exam
  static const int autoSaveIntervalSeconds = 30;
  static const int defaultExamTimePerQuestionSeconds = 60;
  static const double defaultNegativeMarkingRatio = 0.25; // 25% of positive

  // PDF
  static const int pdfRenderDpi = 150;
  static const int pdfRenderCacheLimit = 200; // max page renders to cache

  // UI
  static const double minTouchTarget = 48.0;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 250);
}

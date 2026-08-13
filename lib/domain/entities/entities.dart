/// Domain entities — pure data classes, no dependencies
/// Stage 05 — Architecture
/// Stage 09 — Local Database (mirrors schema)

import 'package:freezed_annotation/freezed_annotation.dart';

part 'entities.freezed.dart';
part 'entities.g.dart';

// === Subject & Topic ===

@freezed
class Subject with _$Subject {
  const factory Subject({
    required String id,
    required String name,
    String? color,
    @Default(0) int questionCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Subject;

  factory Subject.fromJson(Map<String, dynamic> json) => _$SubjectFromJson(json);
}

@freezed
class Topic with _$Topic {
  const factory Topic({
    required String id,
    required String subjectId,
    required String name,
    @Default(0) int questionCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Topic;

  factory Topic.fromJson(Map<String, dynamic> json) => _$TopicFromJson(json);
}

// === PDF Source ===

@freezed
class PdfSource with _$PdfSource {
  const factory PdfSource({
    required String id,
    required String originalFileName,
    required String storedFilePath,
    required int pageCount,
    String? title,
    String? subjectId,
    @Default(0) int questionCount,
    required DateTime importedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _PdfSource;

  factory PdfSource.fromJson(Map<String, dynamic> json) => _$PdfSourceFromJson(json);
}

@freezed
class PdfPage with _$PdfPage {
  const factory PdfPage({
    required String id,
    required String pdfId,
    required int pageNumber,
    required double width,
    required double height,
    String? renderedImagePath,
    required DateTime createdAt,
  }) = _PdfPage;

  factory PdfPage.fromJson(Map<String, dynamic> json) => _$PdfPageFromJson(json);
}

// === Question & Options ===

/// Difficulty levels
enum Difficulty { easy, medium, hard, unknown }

/// Question status after extraction
enum QuestionStatus {
  valid,        // successfully parsed
  suspicious,   // parsed but with warnings
  needsReview,  // user flagged
  invalid,      // could not parse
}

/// A question extracted from PDF or created by user
@freezed
class Question with _$Question {
  const factory Question({
    required String id,
    required String pdfId,
    required int? sourcePageNumber,
    required String body,
    @Default([]) List<QuestionOption> options,
    String? correctOptionId,
    String? subjectId,
    String? topicId,
    @Default([]) List<String> tagIds,
    @Default(Difficulty.unknown) Difficulty difficulty,
    @Default(QuestionStatus.valid) QuestionStatus status,
    @Default([]) List<String> warnings,
    /// PDF region bounding box (x, y, w, h) in PDF coordinates
    PdfRegion? region,
    String? notes,
    @Default(false) bool isBookmarked,
    @Default(false) bool isArchived,
    @Default(0) int timesAnswered,
    @Default(0) int timesCorrect,
    @Default(0) int timesIncorrect,
    DateTime? lastAnsweredAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Question;

  factory Question.fromJson(Map<String, dynamic> json) => _$QuestionFromJson(json);
}

@freezed
class QuestionOption with _$QuestionOption {
  const factory QuestionOption({
    required String id,
    required String label,    // e.g. "الف", "۱", "A"
    required String text,
    @Default(0) int order,
    PdfRegion? region,
  }) = _QuestionOption;

  factory QuestionOption.fromJson(Map<String, dynamic> json) => _$QuestionOptionFromJson(json);
}

/// Bounding box for a region in the PDF page
@freezed
class PdfRegion with _$PdfRegion {
  const factory PdfRegion({
    required int pageNumber,
    required double x,
    required double y,
    required double width,
    required double height,
    String? croppedImagePath,  // path to cropped image if needed
  }) = _PdfRegion;

  factory PdfRegion.fromJson(Map<String, dynamic> json) => _$PdfRegionFromJson(json);
}

// === Tags ===

@freezed
class Tag with _$Tag {
  const factory Tag({
    required String id,
    required String name,
    String? color,
    @Default(0) int questionCount,
    required DateTime createdAt,
  }) = _Tag;

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);
}

// === Exam ===

/// Selection strategy for exam builder
enum ExamSelectionStrategy {
  random,
  manual,
  fromMistakes,
  fromBookmarks,
  newOnly,
  mixed,
}

@freezed
class Exam with _$Exam {
  const factory Exam({
    required String id,
    required String name,
    required List<String> questionIds,
    required int timeLimitSeconds,
    @Default(false) bool negativeMarkingEnabled,
    @Default(0.25) double negativeMarkingRatio,
    @Default(false) bool shuffleQuestions,
    @Default(false) bool shuffleOptions,
    String? subjectId,
    String? topicId,
    Map<String, dynamic>? filters,
    /// Seed for reproducible shuffles (immutable exam)
    int? randomSeed,
    required ExamStatus status,
    DateTime? startedAt,
    DateTime? submittedAt,
    required DateTime createdAt,
  }) = _Exam;

  factory Exam.fromJson(Map<String, dynamic> json) => _$ExamFromJson(json);
}

enum ExamStatus { draft, ready, inProgress, submitted, cancelled }

@freezed
class ExamAnswer with _$ExamAnswer {
  const factory ExamAnswer({
    required String examId,
    required String questionId,
    String? selectedOptionId,
    @Default(false) bool isBookmarked,
    Duration? timeSpent,
    required DateTime updatedAt,
  }) = _ExamAnswer;

  factory ExamAnswer.fromJson(Map<String, dynamic> json) => _$ExamAnswerFromJson(json);
}

// === Result & Grading ===

@freezed
class ExamResult with _$ExamResult {
  const factory ExamResult({
    required String id,
    required String examId,
    required int totalQuestions,
    required int correctCount,
    required int incorrectCount,
    required int unansweredCount,
    required double rawScore,
    required double percentage,
    required double accuracy,
    required double answeredAccuracy,
    required Duration totalTime,
    required Duration averageTimePerQuestion,
    required Map<String, dynamic> gradingConfig,
    required List<ResultQuestion> questions,
    required DateTime submittedAt,
  }) = _ExamResult;

  factory ExamResult.fromJson(Map<String, dynamic> json) => _$ExamResultFromJson(json);
}

@freezed
class ResultQuestion with _$ResultQuestion {
  const factory ResultQuestion({
    required String questionId,
    String? selectedOptionId,
    required String correctOptionId,
    required bool isCorrect,
    required bool isUnanswered,
    required double score,
    required Duration timeSpent,
  }) = _ResultQuestion;

  factory ResultQuestion.fromJson(Map<String, dynamic> json) => _$ResultQuestionFromJson(json);
}

// === Mistakes ===

enum MistakeReason {
  didntKnow,
  forgotFormula,
  careless,
  misread,
  timePressure,
  betweenTwoOptions,
  other,
}

@freezed
class Mistake with _$Mistake {
  const factory Mistake({
    required String id,
    required String questionId,
    required String examResultId,
    MistakeReason? reason,
    String? note,
    @Default(1) int mistakeCount,
    DateTime? lastMistakeAt,
    @Default(0) int correctStreak,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Mistake;

  factory Mistake.fromJson(Map<String, dynamic> json) => _$MistakeFromJson(json);
}

// === Review (Spaced Repetition) ===

enum ReviewStatus { needsReview, learning, mastered, difficult }

@freezed
class ReviewSchedule with _$ReviewSchedule {
  const factory ReviewSchedule({
    required String id,
    required String questionId,
    @Default(2.5) double easeFactor,    // SM-2 default
    @Default(0) int interval,           // days
    @Default(1) int repetitions,
    required DateTime nextReviewAt,
    required DateTime lastReviewedAt,
    @Default(ReviewStatus.needsReview) ReviewStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ReviewSchedule;

  factory ReviewSchedule.fromJson(Map<String, dynamic> json) => _$ReviewScheduleFromJson(json);
}

// === Notes ===

@freezed
class Note with _$Note {
  const factory Note({
    required String id,
    required String questionId,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Note;

  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);
}

// === Backup ===

@freezed
class BackupMetadata with _$BackupMetadata {
  const factory BackupMetadata({
    required String id,
    required String filePath,
    required int fileSizeBytes,
    required String checksum,
    required int formatVersion,
    required String appVersion,
    required bool includePdfs,
    required int questionCount,
    required int examCount,
    required DateTime createdAt,
  }) = _BackupMetadata;

  factory BackupMetadata.fromJson(Map<String, dynamic> json) => _$BackupMetadataFromJson(json);
}

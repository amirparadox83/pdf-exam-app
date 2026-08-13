/// Mapping helpers between drift row types and domain entities.
///
/// Stage 09 — Local Database
///
/// Drift row types (e.g. `Subject`, `Question`) and domain entities
/// (also `Subject`, `Question`) share the same names but live in different
/// libraries. We map explicitly field-by-field to keep the boundary clean
/// and to apply JSON encoding for nested fields (options, tags, warnings,
/// region) that drift stores as plain text.
library data.repositories.implementations.mappers;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../data/database/app_database.dart' as db;
import '../../../domain/entities/entities.dart';

// ============================================================
// Subject
// ============================================================

db.SubjectsCompanion subjectToCompanion(Subject entity, {bool newRecord = false}) {
  final now = DateTime.now();
  return db.SubjectsCompanion(
    id: newRecord ? Value(entity.id) : Value.absent(),
    name: Value(entity.name),
    color: Value(entity.color),
    questionCount: Value(entity.questionCount),
    createdAt: newRecord ? Value(entity.createdAt) : Value.absent(),
    updatedAt: Value(now),
  );
}

Subject subjectFromRow(db.Subject row) => Subject(
      id: row.id,
      name: row.name,
      color: row.color,
      questionCount: row.questionCount,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );

// ============================================================
// Topic
// ============================================================

db.TopicsCompanion topicToCompanion(Topic entity, {bool newRecord = false}) =>
    db.TopicsCompanion(
      id: newRecord ? Value(entity.id) : Value.absent(),
      subjectId: Value(entity.subjectId),
      name: Value(entity.name),
      questionCount: Value(entity.questionCount),
      createdAt: newRecord ? Value(entity.createdAt) : Value.absent(),
      updatedAt: Value(DateTime.now()),
    );

Topic topicFromRow(db.Topic row) => Topic(
      id: row.id,
      subjectId: row.subjectId,
      name: row.name,
      questionCount: row.questionCount,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );

// ============================================================
// Tag
// ============================================================

db.TagsCompanion tagToCompanion(Tag entity, {bool newRecord = false}) => db.TagsCompanion(
      id: newRecord ? Value(entity.id) : Value.absent(),
      name: Value(entity.name),
      color: Value(entity.color),
      questionCount: Value(entity.questionCount),
      createdAt: newRecord ? Value(entity.createdAt) : Value.absent(),
    );

Tag tagFromRow(db.Tag row) => Tag(
      id: row.id,
      name: row.name,
      color: row.color,
      questionCount: row.questionCount,
      createdAt: row.createdAt,
    );

// ============================================================
// PdfSource / PdfPage
// ============================================================

db.PdfSourcesCompanion pdfSourceToCompanion(PdfSource entity, {bool newRecord = false}) =>
    db.PdfSourcesCompanion(
      id: newRecord ? Value(entity.id) : Value.absent(),
      originalFileName: Value(entity.originalFileName),
      storedFilePath: Value(entity.storedFilePath),
      pageCount: Value(entity.pageCount),
      title: Value(entity.title),
      subjectId: Value(entity.subjectId),
      questionCount: Value(entity.questionCount),
      importedAt: newRecord ? Value(entity.importedAt) : Value.absent(),
      createdAt: newRecord ? Value(entity.createdAt) : Value.absent(),
      updatedAt: Value(DateTime.now()),
    );

PdfSource pdfSourceFromRow(db.PdfSource row) => PdfSource(
      id: row.id,
      originalFileName: row.originalFileName,
      storedFilePath: row.storedFilePath,
      pageCount: row.pageCount,
      title: row.title,
      subjectId: row.subjectId,
      questionCount: row.questionCount,
      importedAt: row.importedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );

db.PdfPagesCompanion pdfPageToCompanion(PdfPage entity, {bool newRecord = false}) =>
    db.PdfPagesCompanion(
      id: newRecord ? Value(entity.id) : Value.absent(),
      pdfId: Value(entity.pdfId),
      pageNumber: Value(entity.pageNumber),
      width: Value(entity.width),
      height: Value(entity.height),
      renderedImagePath: Value(entity.renderedImagePath),
      createdAt: newRecord ? Value(entity.createdAt) : Value.absent(),
    );

PdfPage pdfPageFromRow(db.PdfPage row) => PdfPage(
      id: row.id,
      pdfId: row.pdfId,
      pageNumber: row.pageNumber,
      width: row.width,
      height: row.height,
      renderedImagePath: row.renderedImagePath,
      createdAt: row.createdAt,
    );

// ============================================================
// Question + Options + Tags
// ============================================================

String _difficultyToString(Difficulty d) {
  switch (d) {
    case Difficulty.easy:
      return 'easy';
    case Difficulty.medium:
      return 'medium';
    case Difficulty.hard:
      return 'hard';
    case Difficulty.unknown:
      return 'unknown';
  }
}

Difficulty _difficultyFromString(String? s) {
  switch (s) {
    case 'easy':
      return Difficulty.easy;
    case 'medium':
      return Difficulty.medium;
    case 'hard':
      return Difficulty.hard;
    default:
      return Difficulty.unknown;
  }
}

String _statusToString(QuestionStatus s) {
  switch (s) {
    case QuestionStatus.valid:
      return 'valid';
    case QuestionStatus.suspicious:
      return 'suspicious';
    case QuestionStatus.needsReview:
      return 'needsReview';
    case QuestionStatus.invalid:
      return 'invalid';
  }
}

QuestionStatus _statusFromString(String? s) {
  switch (s) {
    case 'suspicious':
      return QuestionStatus.suspicious;
    case 'needsReview':
      return QuestionStatus.needsReview;
    case 'invalid':
      return QuestionStatus.invalid;
    default:
      return QuestionStatus.valid;
  }
}

String? _regionToJson(PdfRegion? r) {
  if (r == null) return null;
  return jsonEncode({
    'pageNumber': r.pageNumber,
    'x': r.x,
    'y': r.y,
    'width': r.width,
    'height': r.height,
    'croppedImagePath': r.croppedImagePath,
  });
}

PdfRegion? _regionFromJson(String? json) {
  if (json == null || json.isEmpty) return null;
  final m = jsonDecode(json) as Map<String, dynamic>;
  return PdfRegion(
    pageNumber: (m['pageNumber'] as num).toInt(),
    x: (m['x'] as num).toDouble(),
    y: (m['y'] as num).toDouble(),
    width: (m['width'] as num).toDouble(),
    height: (m['height'] as num).toDouble(),
    croppedImagePath: m['croppedImagePath'] as String?,
  );
}

db.QuestionsCompanion questionToCompanion(Question entity, {bool newRecord = false}) =>
    db.QuestionsCompanion(
      id: newRecord ? Value(entity.id) : Value.absent(),
      pdfId: Value(entity.pdfId.isEmpty ? null : entity.pdfId),
      sourcePageNumber: Value(entity.sourcePageNumber),
      body: Value(entity.body),
      correctOptionId: Value(entity.correctOptionId),
      subjectId: Value(entity.subjectId),
      topicId: Value(entity.topicId),
      difficulty: Value(_difficultyToString(entity.difficulty)),
      status: Value(_statusToString(entity.status)),
      warningsJson: Value(jsonEncode(entity.warnings)),
      regionJson: Value(_regionToJson(entity.region)),
      notes: Value(entity.notes),
      isBookmarked: Value(entity.isBookmarked),
      isArchived: Value(entity.isArchived),
      timesAnswered: Value(entity.timesAnswered),
      timesCorrect: Value(entity.timesCorrect),
      timesIncorrect: Value(entity.timesIncorrect),
      lastAnsweredAt: Value(entity.lastAnsweredAt),
      createdAt: newRecord ? Value(entity.createdAt) : Value.absent(),
      updatedAt: Value(DateTime.now()),
    );

Question questionFromRow(
  db.Question row, {
  List<QuestionOption> options = const [],
  List<String> tagIds = const [],
}) =>
    Question(
      id: row.id,
      pdfId: row.pdfId ?? '',
      sourcePageNumber: row.sourcePageNumber,
      body: row.body,
      options: options,
      correctOptionId: row.correctOptionId,
      subjectId: row.subjectId,
      topicId: row.topicId,
      tagIds: tagIds,
      difficulty: _difficultyFromString(row.difficulty),
      status: _statusFromString(row.status),
      warnings: (jsonDecode(row.warningsJson) as List<dynamic>).cast<String>(),
      region: _regionFromJson(row.regionJson),
      notes: row.notes,
      isBookmarked: row.isBookmarked,
      isArchived: row.isArchived,
      timesAnswered: row.timesAnswered,
      timesCorrect: row.timesCorrect,
      timesIncorrect: row.timesIncorrect,
      lastAnsweredAt: row.lastAnsweredAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );

db.QuestionOptionsCompanion optionToCompanion(
  QuestionOption entity, {
  required String questionId,
  bool newRecord = false,
}) =>
    db.QuestionOptionsCompanion(
      id: newRecord ? Value(entity.id) : Value.absent(),
      questionId: Value(questionId),
      label: Value(entity.label),
      optionText: Value(entity.text),
      order: Value(entity.order),
      regionJson: Value(_regionToJson(entity.region)),
    );

QuestionOption optionFromRow(db.QuestionOption row) => QuestionOption(
      id: row.id,
      label: row.label,
      text: row.optionText,
      order: row.order,
      region: _regionFromJson(row.regionJson),
    );

// ============================================================
// Exam + ExamAnswer
// ============================================================

String _examStatusToString(ExamStatus s) {
  switch (s) {
    case ExamStatus.draft:
      return 'draft';
    case ExamStatus.ready:
      return 'ready';
    case ExamStatus.inProgress:
      return 'inProgress';
    case ExamStatus.submitted:
      return 'submitted';
    case ExamStatus.cancelled:
      return 'cancelled';
  }
}

ExamStatus _examStatusFromString(String? s) {
  switch (s) {
    case 'ready':
      return ExamStatus.ready;
    case 'inProgress':
      return ExamStatus.inProgress;
    case 'submitted':
      return ExamStatus.submitted;
    case 'cancelled':
      return ExamStatus.cancelled;
    default:
      return ExamStatus.draft;
  }
}

db.ExamsCompanion examToCompanion(Exam entity, {bool newRecord = false}) => db.ExamsCompanion(
      id: newRecord ? Value(entity.id) : Value.absent(),
      name: Value(entity.name),
      questionIdsJson: Value(jsonEncode(entity.questionIds)),
      timeLimitSeconds: Value(entity.timeLimitSeconds),
      negativeMarkingEnabled: Value(entity.negativeMarkingEnabled),
      negativeMarkingRatio: Value(entity.negativeMarkingRatio),
      shuffleQuestions: Value(entity.shuffleQuestions),
      shuffleOptions: Value(entity.shuffleOptions),
      subjectId: Value(entity.subjectId),
      topicId: Value(entity.topicId),
      filtersJson: Value(entity.filters == null ? null : jsonEncode(entity.filters)),
      randomSeed: Value(entity.randomSeed),
      status: Value(_examStatusToString(entity.status)),
      startedAt: Value(entity.startedAt),
      submittedAt: Value(entity.submittedAt),
      createdAt: newRecord ? Value(entity.createdAt) : Value.absent(),
    );

Exam examFromRow(db.Exam row) => Exam(
      id: row.id,
      name: row.name,
      questionIds: (jsonDecode(row.questionIdsJson) as List<dynamic>).cast<String>(),
      timeLimitSeconds: row.timeLimitSeconds,
      negativeMarkingEnabled: row.negativeMarkingEnabled,
      negativeMarkingRatio: row.negativeMarkingRatio,
      shuffleQuestions: row.shuffleQuestions,
      shuffleOptions: row.shuffleOptions,
      subjectId: row.subjectId,
      topicId: row.topicId,
      filters: row.filtersJson == null ? null : jsonDecode(row.filtersJson!) as Map<String, dynamic>,
      randomSeed: row.randomSeed,
      status: _examStatusFromString(row.status),
      startedAt: row.startedAt,
      submittedAt: row.submittedAt,
      createdAt: row.createdAt,
    );

db.ExamAnswersCompanion examAnswerToCompanion(ExamAnswer entity) => db.ExamAnswersCompanion(
      examId: Value(entity.examId),
      questionId: Value(entity.questionId),
      selectedOptionId: Value(entity.selectedOptionId),
      isBookmarked: Value(entity.isBookmarked),
      timeSpentMs: Value(entity.timeSpent?.inMilliseconds),
      updatedAt: Value(entity.updatedAt),
    );

ExamAnswer examAnswerFromRow(db.ExamAnswer row) => ExamAnswer(
      examId: row.examId,
      questionId: row.questionId,
      selectedOptionId: row.selectedOptionId,
      isBookmarked: row.isBookmarked,
      timeSpent: row.timeSpentMs == null ? null : Duration(milliseconds: row.timeSpentMs!),
      updatedAt: row.updatedAt,
    );

// ============================================================
// ExamResult
// ============================================================

db.ExamResultsCompanion examResultToCompanion(ExamResult entity, {bool newRecord = false}) =>
    db.ExamResultsCompanion(
      id: newRecord ? Value(entity.id) : Value.absent(),
      examId: Value(entity.examId),
      totalQuestions: Value(entity.totalQuestions),
      correctCount: Value(entity.correctCount),
      incorrectCount: Value(entity.incorrectCount),
      unansweredCount: Value(entity.unansweredCount),
      rawScore: Value(entity.rawScore),
      percentage: Value(entity.percentage),
      accuracy: Value(entity.accuracy),
      answeredAccuracy: Value(entity.answeredAccuracy),
      totalTimeMs: Value(entity.totalTime.inMilliseconds),
      gradingConfigJson: Value(jsonEncode(entity.gradingConfig)),
      questionsJson: Value(jsonEncode(entity.questions.map((q) => q.toJson()).toList())),
      submittedAt: newRecord ? Value(entity.submittedAt) : Value.absent(),
    );

ExamResult examResultFromRow(db.ExamResult row) => ExamResult(
      id: row.id,
      examId: row.examId,
      totalQuestions: row.totalQuestions,
      correctCount: row.correctCount,
      incorrectCount: row.incorrectCount,
      unansweredCount: row.unansweredCount,
      rawScore: row.rawScore,
      percentage: row.percentage,
      accuracy: row.accuracy,
      answeredAccuracy: row.answeredAccuracy,
      totalTime: Duration(milliseconds: row.totalTimeMs),
      averageTimePerQuestion: Duration(
        milliseconds: row.totalQuestions == 0 ? 0 : row.totalTimeMs ~/ row.totalQuestions,
      ),
      gradingConfig: jsonDecode(row.gradingConfigJson) as Map<String, dynamic>,
      questions: (jsonDecode(row.questionsJson) as List<dynamic>)
          .map((e) => ResultQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      submittedAt: row.submittedAt,
    );

// ============================================================
// Mistake
// ============================================================

String _mistakeReasonToString(MistakeReason? r) {
  if (r == null) return 'other';
  switch (r) {
    case MistakeReason.didntKnow:
      return 'didntKnow';
    case MistakeReason.forgotFormula:
      return 'forgotFormula';
    case MistakeReason.careless:
      return 'careless';
    case MistakeReason.misread:
      return 'misread';
    case MistakeReason.timePressure:
      return 'timePressure';
    case MistakeReason.betweenTwoOptions:
      return 'betweenTwoOptions';
    case MistakeReason.other:
      return 'other';
  }
}

MistakeReason _mistakeReasonFromString(String? s) {
  switch (s) {
    case 'didntKnow':
      return MistakeReason.didntKnow;
    case 'forgotFormula':
      return MistakeReason.forgotFormula;
    case 'careless':
      return MistakeReason.careless;
    case 'misread':
      return MistakeReason.misread;
    case 'timePressure':
      return MistakeReason.timePressure;
    case 'betweenTwoOptions':
      return MistakeReason.betweenTwoOptions;
    default:
      return MistakeReason.other;
  }
}

db.MistakesCompanion mistakeToCompanion(Mistake entity, {bool newRecord = false}) =>
    db.MistakesCompanion(
      id: newRecord ? Value(entity.id) : Value.absent(),
      questionId: Value(entity.questionId),
      examResultId: Value(entity.examResultId),
      reason: Value(_mistakeReasonToString(entity.reason)),
      note: Value(entity.note),
      mistakeCount: Value(entity.mistakeCount),
      lastMistakeAt: Value(entity.lastMistakeAt),
      correctStreak: Value(entity.correctStreak),
      createdAt: newRecord ? Value(entity.createdAt) : Value.absent(),
      updatedAt: Value(DateTime.now()),
    );

Mistake mistakeFromRow(db.Mistake row) => Mistake(
      id: row.id,
      questionId: row.questionId,
      examResultId: row.examResultId ?? '',
      reason: _mistakeReasonFromString(row.reason),
      note: row.note,
      mistakeCount: row.mistakeCount,
      lastMistakeAt: row.lastMistakeAt,
      correctStreak: row.correctStreak,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );

// ============================================================
// ReviewSchedule
// ============================================================

String _reviewStatusToString(ReviewStatus s) {
  switch (s) {
    case ReviewStatus.needsReview:
      return 'needsReview';
    case ReviewStatus.learning:
      return 'learning';
    case ReviewStatus.mastered:
      return 'mastered';
    case ReviewStatus.difficult:
      return 'difficult';
  }
}

ReviewStatus _reviewStatusFromString(String? s) {
  switch (s) {
    case 'learning':
      return ReviewStatus.learning;
    case 'mastered':
      return ReviewStatus.mastered;
    case 'difficult':
      return ReviewStatus.difficult;
    default:
      return ReviewStatus.needsReview;
  }
}

db.ReviewSchedulesCompanion reviewScheduleToCompanion(
  ReviewSchedule entity, {
  bool newRecord = false,
}) =>
    db.ReviewSchedulesCompanion(
      id: newRecord ? Value(entity.id) : Value.absent(),
      questionId: Value(entity.questionId),
      easeFactor: Value(entity.easeFactor),
      intervalDays: Value(entity.interval),
      repetitions: Value(entity.repetitions),
      nextReviewAt: Value(entity.nextReviewAt),
      lastReviewedAt: Value(entity.lastReviewedAt),
      status: Value(_reviewStatusToString(entity.status)),
      createdAt: newRecord ? Value(entity.createdAt) : Value.absent(),
      updatedAt: Value(DateTime.now()),
    );

ReviewSchedule reviewScheduleFromRow(db.ReviewSchedule row) => ReviewSchedule(
      id: row.id,
      questionId: row.questionId,
      easeFactor: row.easeFactor,
      interval: row.intervalDays,
      repetitions: row.repetitions,
      nextReviewAt: row.nextReviewAt,
      lastReviewedAt: row.lastReviewedAt,
      status: _reviewStatusFromString(row.status),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );

// ============================================================
// Note
// ============================================================

db.NotesCompanion noteToCompanion(Note entity, {bool newRecord = false}) => db.NotesCompanion(
      id: newRecord ? Value(entity.id) : Value.absent(),
      questionId: Value(entity.questionId),
      content: Value(entity.content),
      createdAt: newRecord ? Value(entity.createdAt) : Value.absent(),
      updatedAt: Value(DateTime.now()),
    );

Note noteFromRow(db.Note row) => Note(
      id: row.id,
      questionId: row.questionId,
      content: row.content,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );

// ============================================================
// BackupMetadata
// ============================================================

db.BackupMetadataTableCompanion backupMetadataToCompanion(
  BackupMetadata entity, {
  bool newRecord = false,
}) =>
    db.BackupMetadataTableCompanion(
      id: newRecord ? Value(entity.id) : Value.absent(),
      filePath: Value(entity.filePath),
      fileSizeBytes: Value(entity.fileSizeBytes),
      checksum: Value(entity.checksum),
      formatVersion: Value(entity.formatVersion),
      appVersion: Value(entity.appVersion),
      includePdfs: Value(entity.includePdfs),
      questionCount: Value(entity.questionCount),
      examCount: Value(entity.examCount),
      createdAt: newRecord ? Value(entity.createdAt) : Value.absent(),
    );

BackupMetadata backupMetadataFromRow(db.BackupMetadataTableData row) => BackupMetadata(
      id: row.id,
      filePath: row.filePath,
      fileSizeBytes: row.fileSizeBytes,
      checksum: row.checksum,
      formatVersion: row.formatVersion,
      appVersion: row.appVersion,
      includePdfs: row.includePdfs,
      questionCount: row.questionCount,
      examCount: row.examCount,
      createdAt: row.createdAt,
    );

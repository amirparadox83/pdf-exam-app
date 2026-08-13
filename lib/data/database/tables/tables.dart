/// Drift database definition — Stage 09
/// All tables for the Persian PDF Exam App.
/// This file is the source of truth for the schema.
/// Run `dart run build_runner build` to generate *.g.dart.
///
/// Stage 04 — Project Foundation (database stub)
/// Stage 09 — Local Database (full schema)

import 'package:drift/drift.dart';

// === Tables ===

class Subjects extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get color => text().nullable()();
  IntColumn get questionCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Topics extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get subjectId => text().customConstraint('REFERENCES subjects(id) ON DELETE CASCADE')();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  IntColumn get questionCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Tags extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get color => text().nullable()();
  IntColumn get questionCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class PdfSources extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get originalFileName => text()();
  TextColumn get storedFilePath => text()();
  IntColumn get pageCount => integer().withDefault(const Constant(0))();
  TextColumn get title => text().nullable()();
  TextColumn get subjectId => text().nullable()();
  IntColumn get questionCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get importedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class PdfPages extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get pdfId => text().customConstraint('REFERENCES pdf_sources(id) ON DELETE CASCADE')();
  IntColumn get pageNumber => integer()();
  RealColumn get width => real()();
  RealColumn get height => real()();
  TextColumn get renderedImagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Questions extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get pdfId => text().nullable().customConstraint('REFERENCES pdf_sources(id) ON DELETE SET NULL')();
  IntColumn get sourcePageNumber => integer().nullable()();
  TextColumn get body => text()();
  TextColumn get correctOptionId => text().nullable()();
  TextColumn get subjectId => text().nullable()();
  TextColumn get topicId => text().nullable()();
  TextColumn get difficulty => text().withDefault(const Constant('unknown'))();
  TextColumn get status => text().withDefault(const Constant('valid'))();
  TextColumn get warningsJson => text().withDefault(const Constant('[]'))();
  TextColumn get regionJson => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isBookmarked => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get timesAnswered => integer().withDefault(const Constant(0))();
  IntColumn get timesCorrect => integer().withDefault(const Constant(0))();
  IntColumn get timesIncorrect => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAnsweredAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class QuestionOptions extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get questionId => text().customConstraint('REFERENCES questions(id) ON DELETE CASCADE')();
  TextColumn get label => text()();
  TextColumn get optionText => text()();
  IntColumn get order => integer().withDefault(const Constant(0))();
  TextColumn get regionJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class QuestionTags extends Table {
  TextColumn get questionId => text().customConstraint('REFERENCES questions(id) ON DELETE CASCADE')();
  TextColumn get tagId => text().customConstraint('REFERENCES tags(id) ON DELETE CASCADE')();

  @override
  Set<Column> get primaryKey => {questionId, tagId};
}

class Exams extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get name => text()();
  TextColumn get questionIdsJson => text().withDefault(const Constant('[]'))();
  IntColumn get timeLimitSeconds => integer()();
  BoolColumn get negativeMarkingEnabled => boolean().withDefault(const Constant(false))();
  RealColumn get negativeMarkingRatio => real().withDefault(const Constant(0.25))();
  BoolColumn get shuffleQuestions => boolean().withDefault(const Constant(false))();
  BoolColumn get shuffleOptions => boolean().withDefault(const Constant(false))();
  TextColumn get subjectId => text().nullable()();
  TextColumn get topicId => text().nullable()();
  TextColumn get filtersJson => text().nullable()();
  IntColumn get randomSeed => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get submittedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class ExamAnswers extends Table {
  TextColumn get examId => text().customConstraint('REFERENCES exams(id) ON DELETE CASCADE')();
  TextColumn get questionId => text()();
  TextColumn get selectedOptionId => text().nullable()();
  BoolColumn get isBookmarked => boolean().withDefault(const Constant(false))();
  IntColumn get timeSpentMs => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {examId, questionId};
}

class ExamResults extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get examId => text().customConstraint('REFERENCES exams(id) ON DELETE CASCADE')();
  IntColumn get totalQuestions => integer()();
  IntColumn get correctCount => integer()();
  IntColumn get incorrectCount => integer()();
  IntColumn get unansweredCount => integer()();
  RealColumn get rawScore => real()();
  RealColumn get percentage => real()();
  RealColumn get accuracy => real()();
  RealColumn get answeredAccuracy => real()();
  IntColumn get totalTimeMs => integer()();
  TextColumn get gradingConfigJson => text()();
  TextColumn get questionsJson => text()();
  DateTimeColumn get submittedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Mistakes extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get questionId => text().customConstraint('REFERENCES questions(id) ON DELETE CASCADE')();
  TextColumn get examResultId => text().nullable()();
  TextColumn get reason => text().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get mistakeCount => integer().withDefault(const Constant(1))();
  DateTimeColumn get lastMistakeAt => dateTime().nullable()();
  IntColumn get correctStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class ReviewSchedules extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get questionId => text().customConstraint('REFERENCES questions(id) ON DELETE CASCADE')();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  IntColumn get repetitions => integer().withDefault(const Constant(1))();
  DateTimeColumn get nextReviewAt => dateTime()();
  DateTimeColumn get lastReviewedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text().withDefault(const Constant('needsReview'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Notes extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get questionId => text().customConstraint('REFERENCES questions(id) ON DELETE CASCADE')();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class BackupMetadataTable extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get filePath => text()();
  IntColumn get fileSizeBytes => integer()();
  TextColumn get checksum => text()();
  IntColumn get formatVersion => integer()();
  TextColumn get appVersion => text()();
  BoolColumn get includePdfs => boolean().withDefault(const Constant(false))();
  IntColumn get questionCount => integer().withDefault(const Constant(0))();
  IntColumn get examCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'backup_metadata';

  @override
  Set<Column> get primaryKey => {id};
}

/// FTS5 virtual table for full-text question search
class QuestionsFts extends Table {
  TextColumn get content => text()();
  TextColumn get questionId => text()();

  @override
  String get tableName => 'questions_fts';
}

String _uuid() {
  // Simple UUID v4 generator (avoids extra dependency in this stub).
  // In production we use the uuid package.
  final now = DateTime.now().microsecondsSinceEpoch;
  return 'id-${now.toRadixString(36)}-${_counter++}';
}

int _counter = 0;

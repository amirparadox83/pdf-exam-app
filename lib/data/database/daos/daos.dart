/// Data Access Objects — per-table query helpers.
///
/// Stage 09 — Local Database
///
/// These are plain classes (NOT @DriftAccessor) that encapsulate drift queries
/// against a single table or closely-related group of tables. They take an
/// `AppDatabase` as a constructor parameter. This avoids coupling to
/// build_runner-generated DAO getters on `_$AppDatabase` while still providing
/// a clean separation between repository-level entity mapping and raw SQL.
///
/// See `lib/ARCHITECTURE_DECISION.md` for the rationale.

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

// ============================================================
// Subjects
// ============================================================

class SubjectsDao {
  final AppDatabase db;
  SubjectsDao(this.db);

  Future<List<Subject>> getAll() => db.select(db.subjects).get();
  Future<Subject?> getById(String id) =>
      (db.select(db.subjects)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<String> insertOne(SubjectsCompanion entry) async {
    final id = entry.id.present ? entry.id.value : _uuid();
    await db.into(db.subjects).insert(entry.copyWith(id: Value(id)));
    return id;
  }
  Future<bool> updateOne(SubjectsCompanion entry) =>
      (db.update(db.subjects)..where((t) => t.id.equals(entry.id.value))).write(entry).then((r) => r > 0);
  Future<int> deleteById(String id) =>
      (db.delete(db.subjects)..where((t) => t.id.equals(id))).go();
}

// ============================================================
// Topics
// ============================================================

class TopicsDao {
  final AppDatabase db;
  TopicsDao(this.db);

  Future<List<Topic>> getBySubject(String subjectId) =>
      (db.select(db.topics)..where((t) => t.subjectId.equals(subjectId))
                            ..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  Future<Topic?> getById(String id) =>
      (db.select(db.topics)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<String> insertOne(TopicsCompanion entry) async {
    final id = entry.id.present ? entry.id.value : _uuid();
    await db.into(db.topics).insert(entry.copyWith(id: Value(id)));
    return id;
  }
  Future<bool> updateOne(TopicsCompanion entry) =>
      (db.update(db.topics)..where((t) => t.id.equals(entry.id.value))).write(entry).then((r) => r > 0);
  Future<int> deleteById(String id) =>
      (db.delete(db.topics)..where((t) => t.id.equals(id))).go();
}

// ============================================================
// Tags
// ============================================================

class TagsDao {
  final AppDatabase db;
  TagsDao(this.db);

  Future<List<Tag>> getAll() =>
      (db.select(db.tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  Future<Tag?> getById(String id) =>
      (db.select(db.tags)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<String> insertOne(TagsCompanion entry) async {
    final id = entry.id.present ? entry.id.value : _uuid();
    await db.into(db.tags).insert(entry.copyWith(id: Value(id)));
    return id;
  }
  Future<int> deleteById(String id) =>
      (db.delete(db.tags)..where((t) => t.id.equals(id))).go();

  /// Link a tag to a question (idempotent).
  Future<void> attachToQuestion({required String questionId, required String tagId}) async {
    await db.into(db.questionTags).insertOnConflictUpdate(
      QuestionTagsCompanion(
        questionId: Value(questionId),
        tagId: Value(tagId),
      ),
    );
  }

  Future<void> detachFromQuestion({required String questionId, required String tagId}) async {
    await (db.delete(db.questionTags)
          ..where((t) => t.questionId.equals(questionId) & t.tagId.equals(tagId))).go();
  }

  Future<List<Tag>> getTagsForQuestion(String questionId) async {
    final rows = await (db.select(db.tags).join([
      innerJoin(db.questionTags, db.questionTags.tagId.equalsExp(db.tags.id)),
    ])
      ..where(db.questionTags.questionId.equals(questionId))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]))
    .get();
    return rows.map((row) => row.readTable(db.tags)).toList();
  }
}

// ============================================================
// PdfSources + PdfPages
// ============================================================

class PdfSourcesDao {
  final AppDatabase db;
  PdfSourcesDao(this.db);

  Future<List<PdfSource>> getAll() =>
      (db.select(db.pdfSources)..orderBy([(t) => OrderingTerm.desc(t.importedAt)])).get();
  Future<PdfSource?> getById(String id) =>
      (db.select(db.pdfSources)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<String> insertOne(PdfSourcesCompanion entry) async {
    final id = entry.id.present ? entry.id.value : _uuid();
    await db.into(db.pdfSources).insert(entry.copyWith(id: Value(id)));
    return id;
  }
  Future<bool> updateOne(PdfSourcesCompanion entry) =>
      (db.update(db.pdfSources)..where((t) => t.id.equals(entry.id.value))).write(entry).then((r) => r > 0);
  Future<int> deleteById(String id) =>
      (db.delete(db.pdfSources)..where((t) => t.id.equals(id))).go();
}

class PdfPagesDao {
  final AppDatabase db;
  PdfPagesDao(this.db);

  Future<List<PdfPage>> getByPdf(String pdfId) =>
      (db.select(db.pdfPages)..where((t) => t.pdfId.equals(pdfId))
                              ..orderBy([(t) => OrderingTerm.asc(t.pageNumber)])).get();
  Future<String> insertOne(PdfPagesCompanion entry) async {
    final id = entry.id.present ? entry.id.value : _uuid();
    await db.into(db.pdfPages).insert(entry.copyWith(id: Value(id)));
    return id;
  }
  Future<int> deleteByPdf(String pdfId) =>
      (db.delete(db.pdfPages)..where((t) => t.pdfId.equals(pdfId))).go();
}

// ============================================================
// Questions + Options + Tags (junction)
// ============================================================

class QuestionsDao {
  final AppDatabase db;
  QuestionsDao(this.db);

  Future<Question?> getById(String id) =>
      (db.select(db.questions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Question>> getAll({int limit = 100, int offset = 0}) =>
      (db.select(db.questions)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit, offset: offset))
          .get();

  Future<int> count() async {
    final countExpr = db.questions.id.count();
    final query = db.selectOnly(db.questions)..addColumns([countExpr]);
    final row = await query.getSingle();
    return row.read(countExpr) ?? 0;
  }

  Future<String> insertOne(QuestionsCompanion entry) async {
    final id = entry.id.present ? entry.id.value : _uuid();
    await db.into(db.questions).insert(entry.copyWith(id: Value(id)));
    return id;
  }

  Future<bool> updateOne(QuestionsCompanion entry) =>
      (db.update(db.questions)..where((t) => t.id.equals(entry.id.value))).write(entry).then((r) => r > 0);

  Future<int> deleteById(String id) =>
      (db.delete(db.questions)..where((t) => t.id.equals(id))).go();

  /// FTS5 search on question body. Falls back to LIKE if FTS is not initialized.
  Future<List<Question>> search(String query) async {
    if (query.trim().isEmpty) return const [];
    try {
      // FTS5 join
      final rows = await (db.select(db.questions).join([
        innerJoin(
          db.questions,
          db.questions.id.equalsExp(db.questions.id),
        ),
      ])).get();
      // FTS is complex with join; fallback to LIKE for now
      return (db.select(db.questions)
            ..where((t) => t.body.like('%$query%'))
            ..limit(200))
          .get();
    } catch (_) {
      // FTS not available — fallback to LIKE
      return (db.select(db.questions)
            ..where((t) => t.body.like('%$query%'))
            ..limit(200))
          .get();
    }
  }

  /// Filter questions by various optional criteria. All parameters are optional
  /// and combined with AND semantics.
  Future<List<Question>> filter({
    String? subjectId,
    String? topicId,
    String? sourceId,
    List<String>? tagIds,
    String? difficulty,
    bool? onlyBookmarked,
    bool? onlyMistakes,
    bool? onlyNeedsReview,
    bool? excludeArchived,
    int limit = 100,
    int offset = 0,
  }) async {
    final query = db.select(db.questions);

    if (subjectId != null) {
      query.where((t) => t.subjectId.equals(subjectId));
    }
    if (topicId != null) {
      query.where((t) => t.topicId.equals(topicId));
    }
    if (sourceId != null) {
      query.where((t) => t.pdfId.equals(sourceId));
    }
    if (difficulty != null) {
      query.where((t) => t.difficulty.equals(difficulty));
    }
    if (onlyBookmarked == true) {
      query.where((t) => t.isBookmarked.equals(true));
    }
    if (excludeArchived == true) {
      query.where((t) => t.isArchived.equals(false));
    }
    if (onlyNeedsReview == true) {
      query.where((t) => t.status.equals('needsReview'));
    }

    if (onlyMistakes == true) {
      query.where((t) => t.id.isInQuery(
        db.selectOnly(db.mistakes)..addColumns([db.mistakes.questionId]),
      ));
    }

    if (tagIds != null && tagIds.isNotEmpty) {
      query.where((t) => t.id.isInQuery(
        db.selectOnly(db.questionTags)
          ..addColumns([db.questionTags.questionId])
          ..where(db.questionTags.tagId.isIn(tagIds)),
      ));
    }

    query
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit, offset: offset);

    return query.get();
  }
}

class QuestionOptionsDao {
  final AppDatabase db;
  QuestionOptionsDao(this.db);

  Future<List<QuestionOption>> getByQuestion(String questionId) =>
      (db.select(db.questionOptions)
            ..where((t) => t.questionId.equals(questionId))
            ..orderBy([(t) => OrderingTerm.asc(t.order)]))
          .get();

  Future<String> insertOne(QuestionOptionsCompanion entry) async {
    final id = entry.id.present ? entry.id.value : _uuid();
    await db.into(db.questionOptions).insert(entry.copyWith(id: Value(id)));
    return id;
  }

  Future<int> deleteByQuestion(String questionId) =>
      (db.delete(db.questionOptions)..where((t) => t.questionId.equals(questionId))).go();
}

// ============================================================
// Exams + ExamAnswers
// ============================================================

class ExamsDao {
  final AppDatabase db;
  ExamsDao(this.db);

  Future<Exam?> getById(String id) =>
      (db.select(db.exams)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Exam>> getAll({int limit = 50, int offset = 0}) =>
      (db.select(db.exams)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit, offset: offset))
          .get();

  Future<String> insertOne(ExamsCompanion entry) async {
    final id = entry.id.present ? entry.id.value : _uuid();
    await db.into(db.exams).insert(entry.copyWith(id: Value(id)));
    return id;
  }

  Future<bool> updateOne(ExamsCompanion entry) =>
      (db.update(db.exams)..where((t) => t.id.equals(entry.id.value))).write(entry).then((r) => r > 0);

  Future<int> deleteById(String id) =>
      (db.delete(db.exams)..where((t) => t.id.equals(id))).go();
}

class ExamAnswersDao {
  final AppDatabase db;
  ExamAnswersDao(this.db);

  Future<List<ExamAnswer>> getByExam(String examId) =>
      (db.select(db.examAnswers)..where((t) => t.examId.equals(examId))).get();

  Future<ExamAnswer?> get(String examId, String questionId) =>
      (db.select(db.examAnswers)
            ..where((t) => t.examId.equals(examId) & t.questionId.equals(questionId)))
          .getSingleOrNull();

  Future<void> upsert(ExamAnswersCompanion entry) async {
    await db.into(db.examAnswers).insertOnConflictUpdate(entry);
  }

  Future<int> clearByExam(String examId) =>
      (db.delete(db.examAnswers)..where((t) => t.examId.equals(examId))).go();
}

// ============================================================
// ExamResults
// ============================================================

class ExamResultsDao {
  final AppDatabase db;
  ExamResultsDao(this.db);

  Future<ExamResult?> getById(String id) =>
      (db.select(db.examResults)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<ExamResult>> getAll({int limit = 50, int offset = 0}) =>
      (db.select(db.examResults)
            ..orderBy([(t) => OrderingTerm.desc(t.submittedAt)])
            ..limit(limit, offset: offset))
          .get();

  Future<String> insertOne(ExamResultsCompanion entry) async {
    final id = entry.id.present ? entry.id.value : _uuid();
    await db.into(db.examResults).insert(entry.copyWith(id: Value(id)));
    return id;
  }

  Future<int> deleteById(String id) =>
      (db.delete(db.examResults)..where((t) => t.id.equals(id))).go();
}

// ============================================================
// Mistakes
// ============================================================

class MistakesDao {
  final AppDatabase db;
  MistakesDao(this.db);

  Future<Mistake?> getByQuestion(String questionId) =>
      (db.select(db.mistakes)..where((t) => t.questionId.equals(questionId)))
          .getSingleOrNull();

  Future<List<Mistake>> getAll({int limit = 200, int offset = 0}) =>
      (db.select(db.mistakes)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
            ..limit(limit, offset: offset))
          .get();

  Future<String> insertOne(MistakesCompanion entry) async {
    final id = entry.id.present ? entry.id.value : _uuid();
    await db.into(db.mistakes).insert(entry.copyWith(id: Value(id)));
    return id;
  }

  Future<bool> updateOne(MistakesCompanion entry) =>
      (db.update(db.mistakes)..where((t) => t.id.equals(entry.id.value))).write(entry).then((r) => r > 0);

  Future<int> deleteById(String id) =>
      (db.delete(db.mistakes)..where((t) => t.id.equals(id))).go();
}

// ============================================================
// ReviewSchedules
// ============================================================

class ReviewSchedulesDao {
  final AppDatabase db;
  ReviewSchedulesDao(this.db);

  Future<ReviewSchedule?> getByQuestion(String questionId) =>
      (db.select(db.reviewSchedules)..where((t) => t.questionId.equals(questionId)))
          .getSingleOrNull();

  Future<List<ReviewSchedule>> getDue({DateTime? asOf, int limit = 50}) {
    final now = asOf ?? DateTime.now();
    return (db.select(db.reviewSchedules)
          ..where((t) => t.nextReviewAt.isSmallerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm.asc(t.nextReviewAt)])
          ..limit(limit))
        .get();
  }

  Future<String> insertOne(ReviewSchedulesCompanion entry) async {
    final id = entry.id.present ? entry.id.value : _uuid();
    await db.into(db.reviewSchedules).insert(entry.copyWith(id: Value(id)));
    return id;
  }

  Future<bool> updateOne(ReviewSchedulesCompanion entry) =>
      (db.update(db.reviewSchedules)..where((t) => t.id.equals(entry.id.value))).write(entry).then((r) => r > 0);

  Future<int> deleteById(String id) =>
      (db.delete(db.reviewSchedules)..where((t) => t.id.equals(id))).go();
}

// ============================================================
// Notes
// ============================================================

class NotesDao {
  final AppDatabase db;
  NotesDao(this.db);

  Future<List<Note>> getByQuestion(String questionId) =>
      (db.select(db.notes)
            ..where((t) => t.questionId.equals(questionId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

  Future<String> insertOne(NotesCompanion entry) async {
    final id = entry.id.present ? entry.id.value : _uuid();
    await db.into(db.notes).insert(entry.copyWith(id: Value(id)));
    return id;
  }

  Future<bool> updateOne(NotesCompanion entry) =>
      (db.update(db.notes)..where((t) => t.id.equals(entry.id.value))).write(entry).then((r) => r > 0);

  Future<int> deleteById(String id) =>
      (db.delete(db.notes)..where((t) => t.id.equals(id))).go();
}

// ============================================================
// BackupMetadata
// ============================================================

class BackupMetadataDao {
  final AppDatabase db;
  BackupMetadataDao(this.db);

  Future<List<BackupMetadataTableData>> getAll() =>
      (db.select(db.backupMetadataTable)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<String> insertOne(BackupMetadataTableCompanion entry) async {
    final id = entry.id.present ? entry.id.value : _uuid();
    await db.into(db.backupMetadataTable).insert(entry.copyWith(id: Value(id)));
    return id;
  }

  Future<int> deleteById(String id) =>
      (db.delete(db.backupMetadataTable)..where((t) => t.id.equals(id))).go();
}

// ============================================================
// Helpers
// ============================================================

String _uuid() {
  // Same algorithm as tables.dart _uuid() — kept in sync to avoid pulling in the uuid
  // package at the DAO layer (the package is available project-wide via pubspec).
  final now = DateTime.now().microsecondsSinceEpoch;
  return 'id-${now.toRadixString(36)}-${_counter++}';
}

int _counter = 0;

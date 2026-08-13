/// Drift database — AppDatabase
/// Stage 04 — Project Foundation (stub)
/// Stage 09 — Local Database (full schema + migrations + DAOs)
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'dart:io';

import 'tables/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Subjects,
  Topics,
  Tags,
  PdfSources,
  PdfPages,
  Questions,
  QuestionOptions,
  QuestionTags,
  Exams,
  ExamAnswers,
  ExamResults,
  Mistakes,
  ReviewSchedules,
  Notes,
  BackupMetadataTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Create FTS5 virtual table manually
          await customStatement('''
            CREATE VIRTUAL TABLE IF NOT EXISTS questions_fts
            USING fts5(
              content,
              question_id UNINDEXED,
              tokenize='unicode61 remove_diacritics 2'
            );
          ''');
          // Indexes for performance
          await customStatement('CREATE INDEX IF NOT EXISTS idx_questions_subject ON questions(subject_id);');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_questions_topic ON questions(topic_id);');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_questions_pdf ON questions(pdf_id);');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_questions_bookmarked ON questions(is_bookmarked) WHERE is_bookmarked = 1;');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_questions_status ON questions(status);');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_options_question ON question_options(question_id);');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_mistakes_question ON mistakes(question_id);');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_review_next ON review_schedules(next_review_at);');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_answers_exam ON exam_answers(exam_id);');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_pages_pdf ON pdf_pages(pdf_id, page_number);');
        },
        onUpgrade: (m, from, to) async {
          // Future migrations will go here
          // For now, only version 1 exists.
        },
        beforeOpen: (details) async {
          // Enable foreign keys
          await customStatement('PRAGMA foreign_keys = ON;');
          // Enable WAL mode for better concurrency
          await customStatement('PRAGMA journal_mode = WAL;');
        },
      );
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'persian_pdf_exam.db'));
    // Also apply workarounds for older Android versions
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        db.execute('PRAGMA foreign_keys = ON;');
      },
    );
  });
}

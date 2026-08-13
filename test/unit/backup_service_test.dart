// Stage 25 — BackupService real-DB integration tests.
//
// Verifies that export pulls real rows from every repository (no empty
// `dataMap['...'] = []`) and that restore re-inserts them.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:persian_pdf_exam/data/database/app_database.dart';
import 'package:persian_pdf_exam/data/file_storage/file_storage_service.dart';
import 'package:persian_pdf_exam/data/repositories/implementations/implementations.dart';
import 'package:persian_pdf_exam/domain/entities/entities.dart';
import 'package:persian_pdf_exam/features/backup/backup_service.dart';

import 'repositories/helpers.dart';

/// Stub PathProvider that returns a tmp dir we control.
class _TmpPathProvider extends PathProviderPlatform {
  final String root;
  _TmpPathProvider(this.root);

  @override
  Future<String?> getApplicationDocumentsPath() async => root;
  @override
  Future<String?> getTemporaryPath() async => p.join(root, 'tmp');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late AppDatabase db;
  late BackupServiceImpl backupService;
  late FileStorageService fileStorage;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('pexam_backup_test_');
    PathProviderPlatform.instance = _TmpPathProvider(tmpDir.path);
    fileStorage = FileStorageService();
    db = createInMemoryDb();

    backupService = BackupServiceImpl(
      subjectRepository: SubjectRepositoryImpl(database: db),
      topicRepository: TopicRepositoryImpl(database: db),
      tagRepository: TagRepositoryImpl(database: db),
      pdfRepository: PdfRepositoryImpl(database: db),
      questionRepository: QuestionRepositoryImpl(database: db),
      examRepository: ExamRepositoryImpl(database: db),
      resultRepository: ResultRepositoryImpl(database: db),
      mistakeRepository: MistakeRepositoryImpl(database: db),
      reviewRepository: ReviewRepositoryImpl(database: db),
      noteRepository: NoteRepositoryImpl(database: db),
      backupRepository: BackupRepositoryImpl(database: db),
      fileStorage: fileStorage,
    );
  });

  tearDown(() async {
    await db.close();
    if (tmpDir.existsSync()) {
      await tmpDir.delete(recursive: true);
    }
  });

  Future<void> seedSampleData() async {
    final sRepo = SubjectRepositoryImpl(database: db);
    final qRepo = QuestionRepositoryImpl(database: db);
    final eRepo = ExamRepositoryImpl(database: db);

    await sRepo.insert(Subject(
      id: 's1',
      name: 'ریاضی',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ));
    await qRepo.insert(Question(
      id: 'q1',
      pdfId: '',
      sourcePageNumber: 1,
      body: '۲+۲؟',
      correctOptionId: 'opt-1',
      options: [
        QuestionOption(id: 'opt-1', label: '۱', text: '۴'),
        QuestionOption(id: 'opt-2', label: '۲', text: '۵'),
      ],
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ));
    await eRepo.insert(Exam(
      id: 'e1',
      name: 'آزمون',
      questionIds: ['q1'],
      timeLimitSeconds: 300,
      status: ExamStatus.ready,
      createdAt: DateTime(2024),
    ));
  }

  test('create writes a real ZIP with non-zero size', () async {
    await seedSampleData();
    final result = await backupService.create(outputFileName: 'test-backup.pexam');
    expect(result.fileSizeBytes, greaterThan(100),
        reason: 'ZIP must contain real data, not be empty');
    expect(result.questionCount, 1);
    expect(result.examCount, 1);
    expect(result.checksum, hasLength(64), reason: 'SHA-256 hex');
    expect(File(result.filePath).existsSync(), isTrue);
  });

  test('create records backup metadata to BackupRepository', () async {
    await seedSampleData();
    await backupService.create(outputFileName: 'test-backup.pexam');
    final backups = await BackupRepositoryImpl(database: db).getAll();
    expect(backups, hasLength(1));
    expect(backups.first.questionCount, 1);
  });

  test('validate accepts a real backup file', () async {
    await seedSampleData();
    final result = await backupService.create(outputFileName: 'v.pexam');
    final validation = await backupService.validate(result.filePath);
    expect(validation.isValid, isTrue);
    expect(validation.questionCount, 1);
    expect(validation.examCount, 1);
  });

  test('restore re-inserts rows into a fresh DB', () async {
    await seedSampleData();
    final result = await backupService.create(outputFileName: 'r.pexam');

    // Close the current DB and open a fresh in-memory one.
    await db.close();
    db = createInMemoryDb();
    backupService = BackupServiceImpl(
      subjectRepository: SubjectRepositoryImpl(database: db),
      topicRepository: TopicRepositoryImpl(database: db),
      tagRepository: TagRepositoryImpl(database: db),
      pdfRepository: PdfRepositoryImpl(database: db),
      questionRepository: QuestionRepositoryImpl(database: db),
      examRepository: ExamRepositoryImpl(database: db),
      resultRepository: ResultRepositoryImpl(database: db),
      mistakeRepository: MistakeRepositoryImpl(database: db),
      reviewRepository: ReviewRepositoryImpl(database: db),
      noteRepository: NoteRepositoryImpl(database: db),
      backupRepository: BackupRepositoryImpl(database: db),
      fileStorage: fileStorage,
    );

    final restoreResult = await backupService.restore(backupFilePath: result.filePath);
    expect(restoreResult.success, isTrue, reason: restoreResult.error ?? '');
    expect(restoreResult.questionsRestored, 1);
    expect(restoreResult.examsRestored, 1);

    // Verify the question is actually in the new DB.
    final qs = await QuestionRepositoryImpl(database: db).getAll();
    expect(qs, hasLength(1));
    expect(qs.first.body, '۲+۲؟');
  });

  test('restore returns failure on corrupt file', () async {
    final path = await fileStorage.saveBackup('corrupt.pexam', Uint8List.fromList([1, 2, 3]));
    final restoreResult = await backupService.restore(backupFilePath: path);
    expect(restoreResult.success, isFalse);
  });
}

/// Service container — wires up all feature services and repositories.
/// Stage 05 — Architecture
/// Stage 09 — Repository layer wired in
/// Stage 19/22/23/24/25/26 — Engines wired to repositories (real, not stubs)
import '../data/database/app_database.dart';
import '../data/file_storage/file_storage_service.dart';
import '../data/repositories/implementations/implementations.dart';
import '../domain/repositories/repositories.dart';
import '../features/pdf_engine/pdf_engine.dart';
import '../features/pdf_extraction/pdf_extractor.dart';
import '../features/question_parser/question_parser.dart';
import '../features/answer_key_parser/answer_key_parser.dart';
import '../features/exam_engine/exam_engine.dart';
import '../features/grading/grading_engine.dart';
import '../features/analytics_engine/analytics_engine.dart';
import '../features/mistake_system/mistake_manager.dart';
import '../features/review_system/review_scheduler.dart';
import '../features/backup/backup_service.dart';
import '../features/settings_engine/settings_service.dart';

/// Central wiring for the application.
///
/// Architecture (see `lib/ARCHITECTURE_DECISION.md`):
/// - Repositories are the data-access layer for UI-facing CRUD on domain entities.
/// - Engines sit ABOVE repositories — they use them for persistence but
///   also implement non-trivial business logic (SM-2 math, grading math,
///   ZIP/SHA-256 archiving) that doesn't belong in a repository.
/// - UI screens depend on either repositories (pure CRUD) or engines
///   (business workflows), depending on the operation.
class ServiceContainer {
  final AppDatabase database;
  final FileStorageService fileStorage;

  // === Repositories (Stage 09) ===
  late final QuestionRepository questionRepository;
  late final SubjectRepository subjectRepository;
  late final TopicRepository topicRepository;
  late final TagRepository tagRepository;
  late final PdfRepository pdfRepository;
  late final ExamRepository examRepository;
  late final ResultRepository resultRepository;
  late final MistakeRepository mistakeRepository;
  late final ReviewRepository reviewRepository;
  late final NoteRepository noteRepository;
  late final BackupRepository backupRepository;

  // === Engines (Stages 11..26) ===
  late final PdfEngine pdfEngine;
  late final PdfExtractor pdfExtractor;
  late final QuestionParser questionParser;
  late final AnswerKeyParser answerKeyParser;
  late final ExamEngine examEngine;
  late final GradingEngine gradingEngine;
  late final AnalyticsEngine analyticsEngine;
  late final MistakeManager mistakeManager;
  late final ReviewScheduler reviewScheduler;
  late final BackupService backupService;
  late final SettingsService settingsService;

  ServiceContainer({
    required this.database,
    required this.fileStorage,
  }) {
    // Repositories
    questionRepository = QuestionRepositoryImpl(database: database);
    subjectRepository = SubjectRepositoryImpl(database: database);
    topicRepository = TopicRepositoryImpl(database: database);
    tagRepository = TagRepositoryImpl(database: database);
    pdfRepository = PdfRepositoryImpl(database: database);
    examRepository = ExamRepositoryImpl(database: database);
    resultRepository = ResultRepositoryImpl(database: database);
    mistakeRepository = MistakeRepositoryImpl(database: database);
    reviewRepository = ReviewRepositoryImpl(database: database);
    noteRepository = NoteRepositoryImpl(database: database);
    backupRepository = BackupRepositoryImpl(database: database);

    // Engines — Stage 19/22/23/24/25/26 wired to repositories.
    pdfEngine = PdfrxPdfEngine(fileStorage: fileStorage);
    pdfExtractor = PdfExtractor(pdfEngine: pdfEngine);
    questionParser = RuleBasedQuestionParser();
    answerKeyParser = RuleBasedAnswerKeyParser();
    examEngine = ExamEngineImpl(
      examRepository: examRepository,
      resultRepository: resultRepository,
    );
    gradingEngine = GradingEngineImpl();
    analyticsEngine = AnalyticsEngineImpl(
      resultRepository: resultRepository,
      questionRepository: questionRepository,
      mistakeRepository: mistakeRepository,
      subjectRepository: subjectRepository,
    );
    mistakeManager = MistakeManagerImpl(
      mistakeRepository: mistakeRepository,
      questionRepository: questionRepository,
    );
    reviewScheduler = Sm2ReviewScheduler(reviewRepository: reviewRepository);
    backupService = BackupServiceImpl(
      subjectRepository: subjectRepository,
      topicRepository: topicRepository,
      tagRepository: tagRepository,
      pdfRepository: pdfRepository,
      questionRepository: questionRepository,
      examRepository: examRepository,
      resultRepository: resultRepository,
      mistakeRepository: mistakeRepository,
      reviewRepository: reviewRepository,
      noteRepository: noteRepository,
      backupRepository: backupRepository,
      fileStorage: fileStorage,
    );
    settingsService = SettingsService(fileStorage: fileStorage);
  }

  void dispose() {
    pdfEngine.dispose();
    settingsService.dispose();
  }
}

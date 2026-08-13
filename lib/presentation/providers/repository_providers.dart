/// Repository providers — exposes each of the 10 repositories via Riverpod.
/// Stage 09 — Local Database
///
/// UI widgets depend on these abstract interfaces, never on concrete impls.
library presentation.providers.repository_providers;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/repositories.dart';
import 'core_providers.dart';

final questionRepositoryProvider = Provider<QuestionRepository>(
  (ref) => ref.watch(serviceContainerProvider).questionRepository,
);

final subjectRepositoryProvider = Provider<SubjectRepository>(
  (ref) => ref.watch(serviceContainerProvider).subjectRepository,
);

final topicRepositoryProvider = Provider<TopicRepository>(
  (ref) => ref.watch(serviceContainerProvider).topicRepository,
);

final tagRepositoryProvider = Provider<TagRepository>(
  (ref) => ref.watch(serviceContainerProvider).tagRepository,
);

final pdfRepositoryProvider = Provider<PdfRepository>(
  (ref) => ref.watch(serviceContainerProvider).pdfRepository,
);

final examRepositoryProvider = Provider<ExamRepository>(
  (ref) => ref.watch(serviceContainerProvider).examRepository,
);

final resultRepositoryProvider = Provider<ResultRepository>(
  (ref) => ref.watch(serviceContainerProvider).resultRepository,
);

final mistakeRepositoryProvider = Provider<MistakeRepository>(
  (ref) => ref.watch(serviceContainerProvider).mistakeRepository,
);

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => ref.watch(serviceContainerProvider).reviewRepository,
);

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => ref.watch(serviceContainerProvider).noteRepository,
);

final backupRepositoryProvider = Provider<BackupRepository>(
  (ref) => ref.watch(serviceContainerProvider).backupRepository,
);

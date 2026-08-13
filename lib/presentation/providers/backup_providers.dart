/// Backup & restore providers.
/// Stage 07 / 25 — Backup/Restore
library presentation.providers.backup_providers;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_notifier_compat.dart';

import '../../domain/entities/entities.dart';
import 'repository_providers.dart';
import 'core_providers.dart';

/// Async list of backup metadata rows.
final backupListProvider = FutureProvider<List<BackupMetadata>>(
  (ref) => ref.watch(backupRepositoryProvider).getAll(),
);

/// State for the create-backup form.
class BackupCreateState {
  final bool includePdfs;
  final bool encrypt;
  final bool isCreating;
  final double progress;
  final String? error;
  final BackupMetadata? lastCreated;

  const BackupCreateState({
    this.includePdfs = false,
    this.encrypt = false,
    this.isCreating = false,
    this.progress = 0,
    this.error,
    this.lastCreated,
  });

  BackupCreateState copyWith({
    bool? includePdfs,
    bool? encrypt,
    bool? isCreating,
    double? progress,
    String? error,
    BackupMetadata? lastCreated,
    bool clearError = false,
    bool clearLastCreated = false,
  }) {
    return BackupCreateState(
      includePdfs: includePdfs ?? this.includePdfs,
      encrypt: encrypt ?? this.encrypt,
      isCreating: isCreating ?? this.isCreating,
      progress: progress ?? this.progress,
      error: clearError ? null : (error ?? this.error),
      lastCreated: clearLastCreated ? null : (lastCreated ?? this.lastCreated),
    );
  }
}

class BackupCreateNotifier extends StateNotifier<BackupCreateState> {
  final Ref ref;
  BackupCreateNotifier(this.ref) : super(const BackupCreateState());

  void setIncludePdfs(bool v) => state = state.copyWith(includePdfs: v);
  void setEncrypt(bool v) => state = state.copyWith(encrypt: v);

  Future<void> create() async {
    state = state.copyWith(isCreating: true, progress: 0, clearError: true, clearLastCreated: true);
    try {
      final backupService = ref.read(serviceContainerProvider).backupService;
      final fileName = 'backup-${DateTime.now().toIso8601String().replaceAll(':', '-')}.pexam';
      final result = await backupService.create(
        outputFileName: fileName,
        includePdfs: state.includePdfs,
        encryptWithPassword: state.encrypt,
        password: state.encrypt ? 'default-mvp-password' : null,
      );
      // BackupServiceImpl.create() already persists the BackupMetadata row to
      // the BackupRepository — we just need to refresh the list.
      final metadata = BackupMetadata(
        id: '',
        filePath: result.filePath,
        fileSizeBytes: result.fileSizeBytes,
        checksum: result.checksum,
        formatVersion: 1,
        appVersion: '1.0.0',
        includePdfs: state.includePdfs,
        questionCount: result.questionCount,
        examCount: result.examCount,
        createdAt: result.createdAt,
      );
      state = state.copyWith(
        isCreating: false,
        progress: 1,
        lastCreated: metadata,
      );
      // Refresh the list
      ref.invalidate(backupListProvider);
    } catch (e) {
      state = state.copyWith(isCreating: false, error: e.toString());
    }
  }
}

final backupCreateProvider =
    StateNotifierProvider<BackupCreateNotifier, BackupCreateState>(
  (ref) => BackupCreateNotifier(ref),
);

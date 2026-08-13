/// Concrete BackupRepository implementation.
/// Stage 09 — Local Database
///
/// Stores metadata about each locally-created backup file. The actual
/// ZIP creation is performed by BackupService (Stage 25); this repository
/// only persists the metadata row so the UI can list backups.
library data.repositories.implementations.backup_repository_impl;

import '../../../data/database/app_database.dart';
import '../../../data/database/daos/daos.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/repositories.dart';
import 'mappers.dart';

class BackupRepositoryImpl implements BackupRepository {
  final AppDatabase database;
  late final BackupMetadataDao _dao;

  BackupRepositoryImpl({required this.database}) {
    _dao = BackupMetadataDao(database);
  }

  @override
  Future<List<BackupMetadata>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(backupMetadataFromRow).toList();
  }

  @override
  Future<String> insert(BackupMetadata metadata) =>
      _dao.insertOne(backupMetadataToCompanion(metadata, newRecord: true));

  @override
  Future<void> delete(String id) => _dao.deleteById(id);
}

/// Concrete ResultRepository implementation.
/// Stage 09 — Local Database
library data.repositories.implementations.result_repository_impl;

import '../../../data/database/app_database.dart' hide ExamResult;
import '../../../data/database/daos/daos.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/repositories.dart';
import 'mappers.dart';

class ResultRepositoryImpl implements ResultRepository {
  final AppDatabase database;
  late final ExamResultsDao _dao;

  ResultRepositoryImpl({required this.database}) {
    _dao = ExamResultsDao(database);
  }

  @override
  Future<ExamResult?> getById(String id) async {
    final row = await _dao.getById(id);
    return row == null ? null : examResultFromRow(row);
  }

  @override
  Future<List<ExamResult>> getAll({int limit = 50, int offset = 0}) async {
    final rows = await _dao.getAll(limit: limit, offset: offset);
    return rows.map(examResultFromRow).toList();
  }

  @override
  Future<String> insert(ExamResult result) =>
      _dao.insertOne(examResultToCompanion(result, newRecord: true));

  @override
  Future<void> delete(String id) => _dao.deleteById(id);
}

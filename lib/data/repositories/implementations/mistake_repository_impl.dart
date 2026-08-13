/// Concrete MistakeRepository implementation.
/// Stage 09 — Local Database
library data.repositories.implementations.mistake_repository_impl;

import 'package:drift/drift.dart' show Value;

import '../../../data/database/app_database.dart' hide Mistake;
import '../../../data/database/daos/daos.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/repositories.dart';
import 'mappers.dart';

class MistakeRepositoryImpl implements MistakeRepository {
  final AppDatabase database;
  late final MistakesDao _dao;

  MistakeRepositoryImpl({required this.database}) {
    _dao = MistakesDao(database);
  }

  @override
  Future<Mistake?> getByQuestion(String questionId) async {
    final row = await _dao.getByQuestion(questionId);
    return row == null ? null : mistakeFromRow(row);
  }

  @override
  Future<List<Mistake>> getAll({int limit = 200, int offset = 0}) async {
    final rows = await _dao.getAll(limit: limit, offset: offset);
    return rows.map(mistakeFromRow).toList();
  }

  @override
  Future<String> create(Mistake mistake) =>
      _dao.insertOne(mistakeToCompanion(mistake, newRecord: true));

  @override
  Future<void> update(Mistake mistake) async {
    await _dao.updateOne(mistakeToCompanion(mistake, newRecord: false));
  }

  @override
  Future<void> deleteById(String id) async {
    await _dao.deleteById(id);
  }
}

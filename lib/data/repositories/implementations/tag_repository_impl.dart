/// Concrete TagRepository implementation.
/// Stage 09 — Local Database
library data.repositories.implementations.tag_repository_impl;

import '../../../data/database/app_database.dart';
import '../../../data/database/daos/daos.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/repositories.dart';
import 'mappers.dart';

class TagRepositoryImpl implements TagRepository {
  final AppDatabase database;
  late final TagsDao _dao;

  TagRepositoryImpl({required this.database}) {
    _dao = TagsDao(database);
  }

  @override
  Future<List<Tag>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(tagFromRow).toList();
  }

  @override
  Future<String> insert(Tag tag) =>
      _dao.insertOne(tagToCompanion(tag, newRecord: true));

  @override
  Future<void> delete(String id) async {
    await _dao.deleteById(id);
  }
}

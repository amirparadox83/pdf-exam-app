/// Concrete TopicRepository implementation.
/// Stage 09 — Local Database
library data.repositories.implementations.topic_repository_impl;

import '../../../data/database/app_database.dart';
import '../../../data/database/daos/daos.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/repositories.dart';
import 'mappers.dart';

class TopicRepositoryImpl implements TopicRepository {
  final AppDatabase database;
  late final TopicsDao _dao;

  TopicRepositoryImpl({required this.database}) {
    _dao = TopicsDao(database);
  }

  @override
  Future<Topic?> getById(String id) async {
    final row = await _dao.getById(id);
    return row == null ? null : topicFromRow(row);
  }

  @override
  Future<List<Topic>> getBySubject(String subjectId) async {
    final rows = await _dao.getBySubject(subjectId);
    return rows.map(topicFromRow).toList();
  }

  @override
  Future<String> insert(Topic topic) =>
      _dao.insertOne(topicToCompanion(topic, newRecord: true));

  @override
  Future<void> update(Topic topic) async {
    await _dao.updateOne(topicToCompanion(topic, newRecord: false));
  }

  @override
  Future<void> delete(String id) async {
    await _dao.deleteById(id);
  }
}

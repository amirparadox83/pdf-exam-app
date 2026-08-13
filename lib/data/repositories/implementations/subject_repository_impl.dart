/// Concrete SubjectRepository implementation.
/// Stage 09 — Local Database
library data.repositories.implementations.subject_repository_impl;

import '../../../data/database/app_database.dart' hide Subject;
import '../../../data/database/daos/daos.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/repositories.dart';
import 'mappers.dart';

class SubjectRepositoryImpl implements SubjectRepository {
  final AppDatabase database;
  late final SubjectsDao _dao;

  SubjectRepositoryImpl({required this.database}) {
    _dao = SubjectsDao(database);
  }

  @override
  Future<Subject?> getById(String id) async {
    final row = await _dao.getById(id);
    return row == null ? null : subjectFromRow(row);
  }

  @override
  Future<List<Subject>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(subjectFromRow).toList();
  }

  @override
  Future<String> insert(Subject subject) =>
      _dao.insertOne(subjectToCompanion(subject, newRecord: true));

  @override
  Future<void> update(Subject subject) async {
    await _dao.updateOne(subjectToCompanion(subject, newRecord: false));
  }

  @override
  Future<void> delete(String id) async {
    await _dao.deleteById(id);
  }
}

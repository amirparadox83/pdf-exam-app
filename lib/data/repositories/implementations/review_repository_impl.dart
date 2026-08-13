/// Concrete ReviewRepository implementation.
/// Stage 09 — Local Database
library data.repositories.implementations.review_repository_impl;

import '../../../data/database/app_database.dart' hide ReviewSchedule;
import '../../../data/database/daos/daos.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/repositories.dart';
import 'mappers.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final AppDatabase database;
  late final ReviewSchedulesDao _dao;

  ReviewRepositoryImpl({required this.database}) {
    _dao = ReviewSchedulesDao(database);
  }

  @override
  Future<ReviewSchedule?> getByQuestion(String questionId) async {
    final row = await _dao.getByQuestion(questionId);
    return row == null ? null : reviewScheduleFromRow(row);
  }

  @override
  Future<List<ReviewSchedule>> getDue({DateTime? asOf, int limit = 50}) async {
    final rows = await _dao.getDue(asOf: asOf, limit: limit);
    return rows.map(reviewScheduleFromRow).toList();
  }

  @override
  Future<String> insert(ReviewSchedule schedule) =>
      _dao.insertOne(reviewScheduleToCompanion(schedule, newRecord: true));

  @override
  Future<void> update(ReviewSchedule schedule) async {
    await _dao.updateOne(reviewScheduleToCompanion(schedule, newRecord: false));
  }

  @override
  Future<void> delete(String id) => _dao.deleteById(id);
}

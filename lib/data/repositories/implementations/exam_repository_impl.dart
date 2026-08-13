/// Concrete ExamRepository implementation.
/// Stage 09 — Local Database
library data.repositories.implementations.exam_repository_impl;

import '../../../data/database/app_database.dart' hide Exam, ExamAnswer, ExamResult;
import '../../../data/database/daos/daos.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/repositories.dart';
import 'mappers.dart';

class ExamRepositoryImpl implements ExamRepository {
  final AppDatabase database;
  late final ExamsDao _examsDao;
  late final ExamAnswersDao _answersDao;

  ExamRepositoryImpl({required this.database}) {
    _examsDao = ExamsDao(database);
    _answersDao = ExamAnswersDao(database);
  }

  @override
  Future<Exam?> getById(String id) async {
    final row = await _examsDao.getById(id);
    return row == null ? null : examFromRow(row);
  }

  @override
  Future<List<Exam>> getAll({int limit = 50, int offset = 0}) async {
    final rows = await _examsDao.getAll(limit: limit, offset: offset);
    return rows.map(examFromRow).toList();
  }

  @override
  Future<String> create(Exam exam) =>
      _examsDao.insertOne(examToCompanion(exam, newRecord: true));

  @override
  Future<void> update(Exam exam) async {
    await _examsDao.updateOne(examToCompanion(exam, newRecord: false));
  }

  @override
  Future<void> deleteById(String id) async {
    await _examsDao.deleteById(id);
  }

  @override
  Future<List<ExamAnswer>> getAnswers(String examId) =>
      _answersDao.getByExam(examId).then((rows) => rows.map(examAnswerFromRow).toList());

  @override
  Future<void> upsertAnswer(ExamAnswer answer) =>
      _answersDao.upsert(examAnswerToCompanion(answer));

  @override
  Future<void> clearAnswers(String examId) =>
      _answersDao.clearByExam(examId);
}

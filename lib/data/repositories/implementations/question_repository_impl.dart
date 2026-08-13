/// Concrete QuestionRepository implementation.
/// Stage 09 — Local Database
///
/// Implements all QuestionRepository contract methods using QuestionsDao,
/// QuestionOptionsDao, and TagsDao. Handles entity↔row mapping including
/// nested fields (options, tagIds, warnings, region) which are stored as
/// JSON-encoded text columns in drift.
library data.repositories.implementations.question_repository_impl;

import 'package:drift/drift.dart';

import '../../../data/database/app_database.dart' as db;
import '../../../data/database/daos/daos.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/repositories.dart';
import 'mappers.dart';

class QuestionRepositoryImpl implements QuestionRepository {
  final db.AppDatabase database;
  late final QuestionsDao _dao;
  late final QuestionOptionsDao _optionsDao;
  late final TagsDao _tagsDao;

  QuestionRepositoryImpl({required this.database}) {
    _dao = QuestionsDao(database);
    _optionsDao = QuestionOptionsDao(database);
    _tagsDao = TagsDao(database);
  }

  @override
  Future<Question?> getById(String id) async {
    final row = await _dao.getById(id);
    if (row == null) return null;
    return _hydrate(row);
  }

  @override
  Future<List<Question>> getAll({int limit = 100, int offset = 0}) async {
    final rows = await _dao.getAll(limit: limit, offset: offset);
    return _hydrateAll(rows);
  }

  @override
  Future<List<Question>> search(String query) async {
    final rows = await _dao.search(query);
    return _hydrateAll(rows);
  }

  @override
  Future<List<Question>> filter({
    String? subjectId,
    String? topicId,
    String? sourceId,
    List<String>? tagIds,
    Difficulty? difficulty,
    bool? onlyBookmarked,
    bool? onlyMistakes,
    bool? onlyNeedsReview,
    bool? excludeArchived,
    int limit = 100,
    int offset = 0,
  }) async {
    final rows = await _dao.filter(
      subjectId: subjectId,
      topicId: topicId,
      sourceId: sourceId,
      tagIds: tagIds,
      difficulty: difficulty == null ? null : _difficultyToString(difficulty),
      onlyBookmarked: onlyBookmarked,
      onlyMistakes: onlyMistakes,
      onlyNeedsReview: onlyNeedsReview,
      excludeArchived: excludeArchived,
      limit: limit,
      offset: offset,
    );
    return _hydrateAll(rows);
  }

  @override
  Future<int> count() => _dao.count();

  @override
  Future<String> insert(Question question) async {
    final id = await _dao.insertOne(
      questionToCompanion(question, newRecord: true),
    );
    await _replaceOptions(questionId: id, options: question.options);
    await _replaceTags(questionId: id, tagIds: question.tagIds);
    return id;
  }

  @override
  Future<void> update(Question question) async {
    await _dao.updateOne(questionToCompanion(question, newRecord: false));
    await _replaceOptions(questionId: question.id, options: question.options);
    await _replaceTags(questionId: question.id, tagIds: question.tagIds);
  }

  @override
  Future<void> delete(String id) async {
    await _optionsDao.deleteByQuestion(id);
    await _dao.deleteById(id);
  }

  @override
  Future<void> archive(String id) async {
    await _dao.updateOne(
      db.QuestionsCompanion(id: Value(id), isArchived: Value(true)),
    );
  }

  @override
  Future<void> toggleBookmark(String id) async {
    final current = await _dao.getById(id);
    if (current == null) return;
    await _dao.updateOne(
      db.QuestionsCompanion(
        id: Value(id),
        isBookmarked: Value(!current.isBookmarked),
      ),
    );
  }

  @override
  Future<void> markAnswered(String id, bool correct) async {
    final current = await _dao.getById(id);
    if (current == null) return;
    final timesAnswered = current.timesAnswered + 1;
    final timesCorrect = current.timesCorrect + (correct ? 1 : 0);
    final timesIncorrect = current.timesIncorrect + (correct ? 0 : 1);
    await _dao.updateOne(
      db.QuestionsCompanion(
        id: Value(id),
        timesAnswered: Value(timesAnswered),
        timesCorrect: Value(timesCorrect),
        timesIncorrect: Value(timesIncorrect),
        lastAnsweredAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------- helpers ----------

  Future<Question> _hydrate(db.Question row) async {
    final optionsRows = await _optionsDao.getByQuestion(row.id);
    final tagRows = await _tagsDao.getTagsForQuestion(row.id);
    return questionFromRow(
      row,
      options: optionsRows.map(optionFromRow).toList(),
      tagIds: tagRows.map((t) => t.id).toList(),
    );
  }

  Future<List<Question>> _hydrateAll(List<db.Question> rows) async {
    return Future.wait(rows.map(_hydrate));
  }

  Future<void> _replaceOptions({
    required String questionId,
    required List<QuestionOption> options,
  }) async {
    await _optionsDao.deleteByQuestion(questionId);
    for (var i = 0; i < options.length; i++) {
      final opt = options[i].copyWith(order: i);
      await _optionsDao.insertOne(
        optionToCompanion(opt, questionId: questionId, newRecord: true),
      );
    }
  }

  Future<void> _replaceTags({
    required String questionId,
    required List<String> tagIds,
  }) async {
    // Remove all existing tag links, then re-add the requested ones.
    // Easiest way: fetch current tags and detach each, then attach new ones.
    final existing = await _tagsDao.getTagsForQuestion(questionId);
    for (final t in existing) {
      if (!tagIds.contains(t.id)) {
        await _tagsDao.detachFromQuestion(questionId: questionId, tagId: t.id);
      }
    }
    for (final tagId in tagIds) {
      await _tagsDao.attachToQuestion(questionId: questionId, tagId: tagId);
    }
  }

  String _difficultyToString(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return 'easy';
      case Difficulty.medium:
        return 'medium';
      case Difficulty.hard:
        return 'hard';
      case Difficulty.unknown:
        return 'unknown';
    }
  }
}

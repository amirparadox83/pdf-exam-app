/// Concrete NoteRepository implementation.
/// Stage 09 — Local Database
library data.repositories.implementations.note_repository_impl;

import '../../../data/database/app_database.dart';
import '../../../data/database/daos/daos.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/repositories.dart';
import 'mappers.dart';

class NoteRepositoryImpl implements NoteRepository {
  final AppDatabase database;
  late final NotesDao _dao;

  NoteRepositoryImpl({required this.database}) {
    _dao = NotesDao(database);
  }

  @override
  Future<List<Note>> getByQuestion(String questionId) async {
    final rows = await _dao.getByQuestion(questionId);
    return rows.map(noteFromRow).toList();
  }

  @override
  Future<String> insert(Note note) =>
      _dao.insertOne(noteToCompanion(note, newRecord: true));

  @override
  Future<void> update(Note note) async {
    await _dao.updateOne(noteToCompanion(note, newRecord: false));
  }

  @override
  Future<void> delete(String id) => _dao.deleteById(id);
}

// Stage 09 — NoteRepository tests
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_pdf_exam/data/database/app_database.dart';
import 'package:persian_pdf_exam/data/repositories/implementations/note_repository_impl.dart';
import 'package:persian_pdf_exam/data/repositories/implementations/question_repository_impl.dart';
import 'package:persian_pdf_exam/domain/entities/entities.dart';

import 'helpers.dart';

void main() {
  late AppDatabase db;
  late NoteRepositoryImpl repo;
  late QuestionRepositoryImpl questionRepo;

  setUp(() {
    db = createInMemoryDb();
    repo = NoteRepositoryImpl(database: db);
    questionRepo = QuestionRepositoryImpl(database: db);
  });

  tearDown(() => db.close());

  Future<void> _seedQuestion(String id) async {
    await questionRepo.insert(Question(
      id: id, pdfId: '', sourcePageNumber: 1, body: 'body',
      createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
  }

  Note _makeNote({String id = 'n1', String questionId = 'q1', String content = 'یادآوری'}) {
    return Note(
      id: id,
      questionId: questionId,
      content: content,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );
  }

  test('insert + getByQuestion round-trips', () async {
    await _seedQuestion('q1');
    final id = await repo.insert(_makeNote());
    final notes = await repo.getByQuestion('q1');
    expect(notes.length, 1);
    expect(notes.first.content, 'یادآوری');
  });

  test('getByQuestion returns notes ordered by updatedAt desc', () async {
    await _seedQuestion('q1');
    await repo.insert(_makeNote(
      id: 'n1',
      content: 'قدیمی‌تر',
    ));
    await Future.delayed(const Duration(milliseconds: 10));
    await repo.insert(_makeNote(
      id: 'n2',
      content: 'جدیدتر',
    ));
    final notes = await repo.getByQuestion('q1');
    expect(notes.first.content, 'جدیدتر');
  });

  test('update mutates content', () async {
    await _seedQuestion('q1');
    final id = await repo.insert(_makeNote());
    await repo.update(_makeNote(id: id, content: 'محتوای جدید'));
    final notes = await repo.getByQuestion('q1');
    expect(notes.first.content, 'محتوای جدید');
  });

  test('delete removes the row', () async {
    await _seedQuestion('q1');
    final id = await repo.insert(_makeNote());
    await repo.delete(id);
    expect(await repo.getByQuestion('q1'), isEmpty);
  });
}

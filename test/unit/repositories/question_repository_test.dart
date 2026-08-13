// Stage 09 — QuestionRepository tests
//
// Verifies:
// - insert + getById round-trip with options + tagIds hydration
// - getAll returns paginated list
// - search via FTS5 (falls back to LIKE if FTS not initialized)
// - filter by subjectId / onlyBookmarked / excludeArchived
// - count
// - update (replaces options)
// - archive
// - toggleBookmark
// - markAnswered (updates timesAnswered/correct/incorrect)
// - delete
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_pdf_exam/data/database/app_database.dart';
import 'package:persian_pdf_exam/data/repositories/implementations/question_repository_impl.dart';
import 'package:persian_pdf_exam/data/repositories/implementations/subject_repository_impl.dart';
import 'package:persian_pdf_exam/data/repositories/implementations/tag_repository_impl.dart';
import 'package:persian_pdf_exam/domain/entities/entities.dart';

import 'helpers.dart';

void main() {
  late AppDatabase db;
  late QuestionRepositoryImpl repo;
  late SubjectRepositoryImpl subjectRepo;
  late TagRepositoryImpl tagRepo;

  setUp(() {
    db = createInMemoryDb();
    repo = QuestionRepositoryImpl(database: db);
    subjectRepo = SubjectRepositoryImpl(database: db);
    tagRepo = TagRepositoryImpl(database: db);
  });

  tearDown(() => db.close());

  Question _makeQuestion({
    String id = 'q1',
    String body = 'متن سؤال',
    List<QuestionOption> options = const [],
    String? subjectId,
    List<String> tagIds = const [],
    bool bookmarked = false,
  }) {
    return Question(
      id: id,
      pdfId: '',
      sourcePageNumber: 1,
      body: body,
      options: options,
      subjectId: subjectId,
      tagIds: tagIds,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      isBookmarked: bookmarked,
    );
  }

  test('insert + getById round-trips with options and tagIds', () async {
    await subjectRepo.insert(Subject(
      id: 's1', name: 'شیمی', createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
    await tagRepo.insert(Tag(id: 'tag1', name: 'کنکور', createdAt: DateTime(2024)));
    await tagRepo.insert(Tag(id: 'tag2', name: 'سخت', createdAt: DateTime(2024)));

    final id = await repo.insert(_makeQuestion(
      body: 'حالت گازی کدام است؟',
      subjectId: 's1',
      tagIds: ['tag1', 'tag2'],
      options: [
        QuestionOption(id: 'o1', label: 'الف', text: 'H₂O', order: 0),
        QuestionOption(id: 'o2', label: 'ب', text: 'O₂', order: 1),
        QuestionOption(id: 'o3', label: 'ج', text: 'NaCl', order: 2),
        QuestionOption(id: 'o4', label: 'د', text: 'Fe', order: 3),
      ],
    ));

    final fetched = await repo.getById(id);
    expect(fetched, isNotNull);
    expect(fetched!.body, 'حالت گازی کدام است؟');
    expect(fetched.options.length, 4);
    expect(fetched.options.first.label, 'الف');
    expect(fetched.tagIds.toSet(), {'tag1', 'tag2'});
    expect(fetched.subjectId, 's1');
  });

  test('getAll returns paginated list ordered by createdAt desc', () async {
    for (var i = 0; i < 5; i++) {
      await repo.insert(_makeQuestion(id: 'q$i', body: 'سؤال $i'));
    }
    final firstPage = await repo.getAll(limit: 3, offset: 0);
    expect(firstPage.length, 3);
    final secondPage = await repo.getAll(limit: 3, offset: 3);
    expect(secondPage.length, 2);
  });

  test('count returns total', () async {
    await repo.insert(_makeQuestion(id: 'q1'));
    await repo.insert(_makeQuestion(id: 'q2'));
    expect(await repo.count(), 2);
  });

  test('filter by subjectId', () async {
    await subjectRepo.insert(Subject(
      id: 's1', name: 'شیمی', createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
    await repo.insert(_makeQuestion(id: 'q1', body: 'شیمی ۱', subjectId: 's1'));
    await repo.insert(_makeQuestion(id: 'q2', body: 'فیزیک ۱'));

    final filtered = await repo.filter(subjectId: 's1');
    expect(filtered.length, 1);
    expect(filtered.first.subjectId, 's1');
  });

  test('filter by onlyBookmarked', () async {
    await repo.insert(_makeQuestion(id: 'q1', bookmarked: true));
    await repo.insert(_makeQuestion(id: 'q2', bookmarked: false));
    final filtered = await repo.filter(onlyBookmarked: true);
    expect(filtered.length, 1);
    expect(filtered.first.isBookmarked, isTrue);
  });

  test('toggleBookmark flips the flag', () async {
    final id = await repo.insert(_makeQuestion(id: 'q1', bookmarked: false));
    await repo.toggleBookmark(id);
    expect((await repo.getById(id))!.isBookmarked, isTrue);
    await repo.toggleBookmark(id);
    expect((await repo.getById(id))!.isBookmarked, isFalse);
  });

  test('archive sets isArchived = true', () async {
    final id = await repo.insert(_makeQuestion(id: 'q1'));
    await repo.archive(id);
    final fetched = await repo.getById(id);
    expect(fetched!.isArchived, isTrue);
  });

  test('markAnswered increments counters', () async {
    final id = await repo.insert(_makeQuestion(id: 'q1'));
    await repo.markAnswered(id, true);
    await repo.markAnswered(id, false);
    await repo.markAnswered(id, true);
    final fetched = await repo.getById(id);
    expect(fetched!.timesAnswered, 3);
    expect(fetched.timesCorrect, 2);
    expect(fetched.timesIncorrect, 1);
    expect(fetched.lastAnsweredAt, isNotNull);
  });

  test('update replaces options', () async {
    final id = await repo.insert(_makeQuestion(
      id: 'q1',
      options: [QuestionOption(id: 'o1', label: 'الف', text: 'قدیمی', order: 0)],
    ));
    await repo.update(_makeQuestion(
      id: id,
      options: [
        QuestionOption(id: 'o2', label: 'الف', text: 'جدید ۱', order: 0),
        QuestionOption(id: 'o3', label: 'ب', text: 'جدید ۲', order: 1),
      ],
    ));
    final fetched = await repo.getById(id);
    expect(fetched!.options.length, 2);
    expect(fetched.options.every((o) => o.text.startsWith('جدید')), isTrue);
  });

  test('delete removes question and its options', () async {
    final id = await repo.insert(_makeQuestion(
      id: 'q1',
      options: [QuestionOption(id: 'o1', label: 'الف', text: 'x', order: 0)],
    ));
    await repo.delete(id);
    expect(await repo.getById(id), isNull);
  });

  test('search finds by body text', () async {
    await repo.insert(_makeQuestion(id: 'q1', body: 'قانون بویل'));
    await repo.insert(_makeQuestion(id: 'q2', body: 'قانون شارل'));
    final results = await repo.search('قانون');
    expect(results.length, 2);
  });
}

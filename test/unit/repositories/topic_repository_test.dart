// Stage 09 — TopicRepository tests
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_pdf_exam/data/database/app_database.dart';
import 'package:persian_pdf_exam/data/repositories/implementations/topic_repository_impl.dart';
import 'package:persian_pdf_exam/data/repositories/implementations/subject_repository_impl.dart';
import 'package:persian_pdf_exam/domain/entities/entities.dart';

import 'helpers.dart';

void main() {
  late AppDatabase db;
  late TopicRepositoryImpl repo;
  late SubjectRepositoryImpl subjectRepo;

  setUp(() {
    db = createInMemoryDb();
    subjectRepo = SubjectRepositoryImpl(database: db);
    repo = TopicRepositoryImpl(database: db);
  });

  tearDown(() => db.close());

  test('insert + getById round-trips', () async {
    // Parent subject must exist first (FK constraint)
    await subjectRepo.insert(Subject(
      id: 's1', name: 'شیمی', createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
    final id = await repo.insert(Topic(
      id: 't1', subjectId: 's1', name: 'اتم',
      createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
    final fetched = await repo.getById(id);
    expect(fetched, isNotNull);
    expect(fetched!.name, 'اتم');
    expect(fetched.subjectId, 's1');
  });

  test('getBySubject returns only topics for that subject', () async {
    await subjectRepo.insert(Subject(
      id: 's1', name: 'شیمی', createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
    await subjectRepo.insert(Subject(
      id: 's2', name: 'فیزیک', createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
    await repo.insert(Topic(id: 't1', subjectId: 's1', name: 'اتم',
      createdAt: DateTime(2024), updatedAt: DateTime(2024)));
    await repo.insert(Topic(id: 't2', subjectId: 's1', name: 'مولکول',
      createdAt: DateTime(2024), updatedAt: DateTime(2024)));
    await repo.insert(Topic(id: 't3', subjectId: 's2', name: 'مکانیک',
      createdAt: DateTime(2024), updatedAt: DateTime(2024)));

    final s1Topics = await repo.getBySubject('s1');
    expect(s1Topics.length, 2);
    expect(s1Topics.every((t) => t.subjectId == 's1'), isTrue);
  });

  test('update mutates name', () async {
    await subjectRepo.insert(Subject(
      id: 's1', name: 'شیمی', createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
    final id = await repo.insert(Topic(
      id: 't1', subjectId: 's1', name: 'اتم',
      createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
    await repo.update(Topic(
      id: id, subjectId: 's1', name: 'ساختار اتم',
      createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
    final fetched = await repo.getById(id);
    expect(fetched!.name, 'ساختار اتم');
  });

  test('delete removes the row', () async {
    await subjectRepo.insert(Subject(
      id: 's1', name: 'شیمی', createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
    final id = await repo.insert(Topic(
      id: 't1', subjectId: 's1', name: 'اتم',
      createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
    await repo.delete(id);
    final fetched = await repo.getById(id);
    expect(fetched, isNull);
  });
}

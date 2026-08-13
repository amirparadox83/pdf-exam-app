// Stage 09 — SubjectRepository tests
//
// Verifies that SubjectRepositoryImpl correctly:
// - inserts a new Subject (returns non-empty id)
// - getById returns the inserted row mapped back to a domain entity
// - getAll returns the full list
// - update mutates name/color/questionCount
// - delete removes the row
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_pdf_exam/data/database/app_database.dart';
import 'package:persian_pdf_exam/data/repositories/implementations/subject_repository_impl.dart';
import 'package:persian_pdf_exam/domain/entities/entities.dart';

import 'helpers.dart';

void main() {
  late AppDatabase db;
  late SubjectRepositoryImpl repo;

  setUp(() {
    db = createInMemoryDb();
    repo = SubjectRepositoryImpl(database: db);
  });

  tearDown(() => db.close());

  test('insert + getById round-trips the entity', () async {
    final id = await repo.insert(Subject(
      id: 'subj-1',
      name: 'شیمی',
      color: '#FF5722',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ));
    expect(id, 'subj-1');

    final fetched = await repo.getById(id);
    expect(fetched, isNotNull);
    expect(fetched!.name, 'شیمی');
    expect(fetched.color, '#FF5722');
    expect(fetched.questionCount, 0);
  });

  test('getAll returns all inserted subjects', () async {
    await repo.insert(Subject(
      id: 's1', name: 'شیمی', createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
    await repo.insert(Subject(
      id: 's2', name: 'فیزیک', createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
    final all = await repo.getAll();
    expect(all.length, 2);
    expect(all.map((s) => s.name).toSet(), {'شیمی', 'فیزیک'});
  });

  test('update mutates name and color', () async {
    final id = await repo.insert(Subject(
      id: 's1', name: 'شیمی', createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
    await repo.update(Subject(
      id: id, name: 'شیمی آلی', color: '#00FF00',
      createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
    final fetched = await repo.getById(id);
    expect(fetched!.name, 'شیمی آلی');
    expect(fetched.color, '#00FF00');
  });

  test('delete removes the row', () async {
    final id = await repo.insert(Subject(
      id: 's1', name: 'شیمی', createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
    await repo.delete(id);
    final fetched = await repo.getById(id);
    expect(fetched, isNull);
  });
}

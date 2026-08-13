// Stage 09 — TagRepository tests
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_pdf_exam/data/database/app_database.dart';
import 'package:persian_pdf_exam/data/repositories/implementations/tag_repository_impl.dart';
import 'package:persian_pdf_exam/domain/entities/entities.dart';

import 'helpers.dart';

void main() {
  late AppDatabase db;
  late TagRepositoryImpl repo;

  setUp(() {
    db = createInMemoryDb();
    repo = TagRepositoryImpl(database: db);
  });

  tearDown(() => db.close());

  test('insert + getAll round-trips', () async {
    await repo.insert(Tag(id: 'tag1', name: 'کنکور', createdAt: DateTime(2024)));
    await repo.insert(Tag(id: 'tag2', name: 'سخت', color: '#FF0000', createdAt: DateTime(2024)));
    final all = await repo.getAll();
    expect(all.length, 2);
    expect(all.map((t) => t.name).toSet(), {'کنکور', 'سخت'});
  });

  test('delete removes the row', () async {
    await repo.insert(Tag(id: 'tag1', name: 'کنکور', createdAt: DateTime(2024)));
    await repo.delete('tag1');
    final all = await repo.getAll();
    expect(all, isEmpty);
  });
}

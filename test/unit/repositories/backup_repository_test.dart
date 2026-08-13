// Stage 09 — BackupRepository tests
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_pdf_exam/data/database/app_database.dart';
import 'package:persian_pdf_exam/data/repositories/implementations/backup_repository_impl.dart';
import 'package:persian_pdf_exam/domain/entities/entities.dart';

import 'helpers.dart';

void main() {
  late AppDatabase db;
  late BackupRepositoryImpl repo;

  setUp(() {
    db = createInMemoryDb();
    repo = BackupRepositoryImpl(database: db);
  });

  tearDown(() => db.close());

  BackupMetadata _makeMetadata({
    String id = 'b1',
    int questionCount = 100,
    int examCount = 5,
    bool includePdfs = false,
  }) {
    return BackupMetadata(
      id: id,
      filePath: '/tmp/$id.pexam',
      fileSizeBytes: 12345,
      checksum: 'sha256:abcdef',
      formatVersion: 1,
      appVersion: '1.0.0',
      includePdfs: includePdfs,
      questionCount: questionCount,
      examCount: examCount,
      createdAt: DateTime(2024),
    );
  }

  test('insert + getAll round-trips', () async {
    await repo.insert(_makeMetadata(id: 'b1', questionCount: 50));
    await repo.insert(_makeMetadata(id: 'b2', questionCount: 100));
    final all = await repo.getAll();
    expect(all.length, 2);
    expect(all.map((b) => b.id).toSet(), {'b1', 'b2'});
  });

  test('getAll returns sorted by createdAt desc (newest first)', () async {
    await repo.insert(_makeMetadata(id: 'b1'));
    await Future.delayed(const Duration(milliseconds: 10));
    await repo.insert(_makeMetadata(id: 'b2'));
    final all = await repo.getAll();
    expect(all.first.id, 'b2');
  });

  test('insert preserves all fields', () async {
    final id = await repo.insert(_makeMetadata(
      includePdfs: true,
      questionCount: 500,
      examCount: 25,
    ));
    final all = await repo.getAll();
    final fetched = all.firstWhere((b) => b.id == id);
    expect(fetched.includePdfs, isTrue);
    expect(fetched.questionCount, 500);
    expect(fetched.examCount, 25);
    expect(fetched.checksum, 'sha256:abcdef');
    expect(fetched.fileSizeBytes, 12345);
  });

  test('delete removes the row', () async {
    await repo.insert(_makeMetadata(id: 'b1'));
    await repo.delete('b1');
    final all = await repo.getAll();
    expect(all, isEmpty);
  });
}

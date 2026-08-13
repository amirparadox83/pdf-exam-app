// Stage 09 — PdfRepository tests
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_pdf_exam/data/database/app_database.dart';
import 'package:persian_pdf_exam/data/repositories/implementations/pdf_repository_impl.dart';
import 'package:persian_pdf_exam/domain/entities/entities.dart';

import 'helpers.dart';

void main() {
  late AppDatabase db;
  late PdfRepositoryImpl repo;

  setUp(() {
    db = createInMemoryDb();
    repo = PdfRepositoryImpl(database: db);
  });

  tearDown(() => db.close());

  test('insert + getById round-trips', () async {
    final id = await repo.insert(PdfSource(
      id: 'pdf-1',
      originalFileName: 'exam.pdf',
      storedFilePath: '/tmp/exam.pdf',
      pageCount: 10,
      title: 'آزمون شیمی',
      importedAt: DateTime(2024),
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ));
    final fetched = await repo.getById(id);
    expect(fetched, isNotNull);
    expect(fetched!.originalFileName, 'exam.pdf');
    expect(fetched.pageCount, 10);
  });

  test('getAll returns all PDFs sorted by importedAt desc', () async {
    await repo.insert(PdfSource(
      id: 'pdf-1', originalFileName: 'a.pdf', storedFilePath: '/a',
      pageCount: 1,
      importedAt: DateTime(2024, 1, 1),
      createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
    await repo.insert(PdfSource(
      id: 'pdf-2', originalFileName: 'b.pdf', storedFilePath: '/b',
      pageCount: 2,
      importedAt: DateTime(2024, 2, 1),
      createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
    final all = await repo.getAll();
    expect(all.length, 2);
    expect(all.first.id, 'pdf-2'); // newest first
  });

  test('insertPage + getPages round-trips', () async {
    final pdfId = await repo.insert(PdfSource(
      id: 'pdf-1', originalFileName: 'a.pdf', storedFilePath: '/a',
      pageCount: 3,
      importedAt: DateTime(2024), createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
    await repo.insertPage(PdfPage(
      id: 'p1', pdfId: pdfId, pageNumber: 1, width: 595, height: 842,
      createdAt: DateTime(2024),
    ));
    await repo.insertPage(PdfPage(
      id: 'p2', pdfId: pdfId, pageNumber: 2, width: 595, height: 842,
      createdAt: DateTime(2024),
    ));
    final pages = await repo.getPages(pdfId);
    expect(pages.length, 2);
    expect(pages.first.pageNumber, 1); // ascending
  });

  test('update mutates title', () async {
    final id = await repo.insert(PdfSource(
      id: 'pdf-1', originalFileName: 'a.pdf', storedFilePath: '/a',
      pageCount: 1,
      importedAt: DateTime(2024), createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
    await repo.update(PdfSource(
      id: id, originalFileName: 'a.pdf', storedFilePath: '/a',
      pageCount: 1, title: 'عنوان جدید',
      importedAt: DateTime(2024), createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
    final fetched = await repo.getById(id);
    expect(fetched!.title, 'عنوان جدید');
  });

  test('delete removes PDF and its pages (cascade)', () async {
    final id = await repo.insert(PdfSource(
      id: 'pdf-1', originalFileName: 'a.pdf', storedFilePath: '/a',
      pageCount: 1,
      importedAt: DateTime(2024), createdAt: DateTime(2024), updatedAt: DateTime(2024),
    ));
    await repo.insertPage(PdfPage(
      id: 'p1', pdfId: id, pageNumber: 1, width: 100, height: 100,
      createdAt: DateTime(2024),
    ));
    await repo.delete(id);
    final fetched = await repo.getById(id);
    expect(fetched, isNull);
    final pages = await repo.getPages(id);
    expect(pages, isEmpty);
  });
}

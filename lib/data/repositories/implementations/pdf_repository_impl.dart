/// Concrete PdfRepository implementation.
/// Stage 09 — Local Database
library data.repositories.implementations.pdf_repository_impl;

import '../../../data/database/app_database.dart' hide PdfSource, PdfPage;
import '../../../data/database/daos/daos.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/repositories.dart';
import 'mappers.dart';

class PdfRepositoryImpl implements PdfRepository {
  final AppDatabase database;
  late final PdfSourcesDao _sourcesDao;
  late final PdfPagesDao _pagesDao;

  PdfRepositoryImpl({required this.database}) {
    _sourcesDao = PdfSourcesDao(database);
    _pagesDao = PdfPagesDao(database);
  }

  @override
  Future<PdfSource?> getById(String id) async {
    final row = await _sourcesDao.getById(id);
    return row == null ? null : pdfSourceFromRow(row);
  }

  @override
  Future<List<PdfSource>> getAll() async {
    final rows = await _sourcesDao.getAll();
    return rows.map(pdfSourceFromRow).toList();
  }

  @override
  Future<String> insert(PdfSource pdf) =>
      _sourcesDao.insertOne(pdfSourceToCompanion(pdf, newRecord: true));

  @override
  Future<void> update(PdfSource pdf) async {
    await _sourcesDao.updateOne(pdfSourceToCompanion(pdf, newRecord: false));
  }

  @override
  Future<void> delete(String id) async {
    await _pagesDao.deleteByPdf(id);
    await _sourcesDao.deleteById(id);
  }

  @override
  Future<List<PdfPage>> getPages(String pdfId) async {
    final rows = await _pagesDao.getByPdf(pdfId);
    return rows.map(pdfPageFromRow).toList();
  }

  @override
  Future<void> insertPage(PdfPage page) =>
      _pagesDao.insertOne(pdfPageToCompanion(page, newRecord: true));
}

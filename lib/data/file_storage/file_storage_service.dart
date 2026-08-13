/// Secure local file storage
/// Stage 04 — Project Foundation (stub)
/// Stage 10 — File Storage (full implementation)
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';

/// Manages local file storage across four categories:
/// - Permanent (PDFs, page renders): never deleted automatically
/// - Temporary (working files): cleared on app restart
/// - Cache (rebuildable renders): LRU eviction
/// - Backup (backup files): managed by user
class FileStorageService {
  late final Directory _permanentDir;
  late final Directory _tempDir;
  late final Directory _cacheDir;
  late final Directory _backupDir;
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    final appDir = await getApplicationDocumentsDirectory();
    final cacheRoot = await getTemporaryDirectory();

    _permanentDir = Directory(p.join(appDir.path, AppConstants.permanentDir));
    _tempDir = Directory(p.join(appDir.path, AppConstants.tempDir));
    _cacheDir = Directory(p.join(cacheRoot.path, AppConstants.cacheDir));
    _backupDir = Directory(p.join(appDir.path, AppConstants.backupDir));

    await _permanentDir.create(recursive: true);
    await _tempDir.create(recursive: true);
    await _cacheDir.create(recursive: true);
    await _backupDir.create(recursive: true);
    _initialized = true;
  }

  // === Permanent ===
  Future<String> savePermanent(String filename, List<int> bytes) async {
    await _init();
    final file = File(p.join(_permanentDir.path, filename));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<String> savePermanentStream(String filename, Stream<List<int>> stream) async {
    await _init();
    final file = File(p.join(_permanentDir.path, filename));
    final sink = file.openWrite();
    await for (final chunk in stream) {
      sink.add(chunk);
    }
    await sink.flush();
    await sink.close();
    return file.path;
  }

  // === Temp ===
  Future<String> saveTemp(String filename, List<int> bytes) async {
    await _init();
    final file = File(p.join(_tempDir.path, filename));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  // === Cache ===
  Future<String> saveCache(String filename, List<int> bytes) async {
    await _init();
    final file = File(p.join(_cacheDir.path, filename));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  // === Backup ===
  Future<String> saveBackup(String filename, List<int> bytes) async {
    await _init();
    final file = File(p.join(_backupDir.path, filename));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  // === Common operations ===
  Future<List<int>> read(String path) async {
    final file = File(path);
    return await file.readAsBytes();
  }

  Future<bool> exists(String path) async {
    final file = File(path);
    return await file.exists();
  }

  Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> copy(String src, String dst) async {
    await File(src).copy(dst);
  }

  Future<void> move(String src, String dst) async {
    await File(src).rename(dst);
  }

  Future<int> size(String path) async {
    final file = File(path);
    if (!await file.exists()) return 0;
    return await file.length();
  }

  // === Cleanup ===
  Future<void> cleanupTemp() async {
    await _init();
    if (await _tempDir.exists()) {
      await _tempDir.delete(recursive: true);
      await _tempDir.create(recursive: true);
    }
  }

  Future<void> cleanupCache({int keepMostRecent = AppConstants.pdfRenderCacheLimit}) async {
    await _init();
    final files = await _cacheDir.list().toList();
    files.sort((a, b) =>
        b.statSync().modified.compareTo(a.statSync().modified));
    for (var i = keepMostRecent; i < files.length; i++) {
      await files[i].delete();
    }
  }

  // === Subdirectory helpers ===
  Future<String> pdfPath(String pdfId, {String ext = '.pdf'}) async {
    await _init();
    final dir = Directory(p.join(_permanentDir.path, 'pdfs'));
    await dir.create(recursive: true);
    return p.join(dir.path, '$pdfId$ext');
  }

  Future<String> pageRenderPath(String pdfId, int pageNumber, {int scale = 1}) async {
    await _init();
    final dir = Directory(p.join(_cacheDir.path, 'renders', pdfId));
    await dir.create(recursive: true);
    return p.join(dir.path, 'page_${pageNumber}_$scale.png');
  }

  Future<String> regionPath(String questionId, String suffix) async {
    await _init();
    final dir = Directory(p.join(_permanentDir.path, 'regions'));
    await dir.create(recursive: true);
    return p.join(dir.path, '${questionId}_$suffix.png');
  }

  Future<String> formulaPath(String questionId, int index) async {
    await _init();
    final dir = Directory(p.join(_permanentDir.path, 'formulas'));
    await dir.create(recursive: true);
    return p.join(dir.path, '${questionId}_$index.png');
  }

  Future<Directory> get backupDir async {
    await _init();
    return _backupDir;
  }

  Future<int> totalStorageUsed() async {
    await _init();
    int total = 0;
    await for (final entity in _permanentDir.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    await for (final entity in _cacheDir.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  void dispose() {
    // No persistent state to clean up
  }
}

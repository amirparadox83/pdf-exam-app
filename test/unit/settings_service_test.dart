// Stage 26 — SettingsService real local-storage tests.
//
// Verifies that getString/setString/getBool/setBool actually persist to the
// JSON file via FileStorageService — no more "return defaultValue" stubs.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:persian_pdf_exam/data/file_storage/file_storage_service.dart';
import 'package:persian_pdf_exam/features/settings_engine/settings_service.dart';

class _TmpPathProvider extends PathProviderPlatform {
  final String root;
  _TmpPathProvider(this.root);

  @override
  Future<String?> getApplicationDocumentsPath() async => root;
  @override
  Future<String?> getTemporaryPath() async => p.join(root, 'tmp');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late FileStorageService fileStorage;
  late SettingsService service;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('pexam_settings_test_');
    PathProviderPlatform.instance = _TmpPathProvider(tmpDir.path);
    fileStorage = FileStorageService();
    service = SettingsService(fileStorage: fileStorage);
  });

  tearDown(() async {
    service.dispose();
    if (tmpDir.existsSync()) {
      await tmpDir.delete(recursive: true);
    }
  });

  test('getString returns defaultValue on first call (file not yet created)', () async {
    final v = await service.getString('theme', defaultValue: 'system');
    expect(v, 'system');
  });

  test('setString persists and getString reads it back', () async {
    await service.setString('theme', 'dark');
    expect(await service.getString('theme'), 'dark');
  });

  test('setBool + getBool round-trip', () async {
    await service.setBool('negativeMarking', true);
    expect(await service.getBool('negativeMarking'), isTrue);
    await service.setBool('negativeMarking', false);
    expect(await service.getBool('negativeMarking'), isFalse);
  });

  test('setInt + getInt round-trip', () async {
    await service.setInt('timePerQuestion', 90);
    expect(await service.getInt('timePerQuestion'), 90);
  });

  test('setDouble + getDouble round-trip', () async {
    await service.setDouble('fontSizeScale', 1.25);
    expect(await service.getDouble('fontSizeScale'), 1.25);
  });

  test('persistence survives re-instantiation (real file write)', () async {
    await service.setString('theme', 'light');
    await service.setInt('timePerQuestion', 120);

    // Drop the in-memory cache by creating a new service instance.
    service.dispose();
    service = SettingsService(fileStorage: fileStorage);
    expect(await service.getString('theme'), 'light');
    expect(await service.getInt('timePerQuestion'), 120);
  });

  test('typed getters return defaults on first call', () async {
    expect(await service.getThemeMode(), 'system');
    expect(await service.getFontSizeScale(), 1.0);
    expect(await service.getNegativeMarkingDefault(), isFalse);
    expect(await service.getDefaultExamTimePerQuestion(), 60);
  });

  test('typed setters persist', () async {
    await service.setThemeMode('dark');
    await service.setFontSizeScale(1.5);
    await service.setNegativeMarkingDefault(true);
    await service.setDefaultExamTimePerQuestion(120);

    expect(await service.getThemeMode(), 'dark');
    expect(await service.getFontSizeScale(), 1.5);
    expect(await service.getNegativeMarkingDefault(), isTrue);
    expect(await service.getDefaultExamTimePerQuestion(), 120);
  });

  test('clearAll wipes the cache', () async {
    await service.setString('theme', 'dark');
    await service.clearAll();
    expect(await service.getString('theme'), isNull);
  });

  test('changes stream emits on write', () async {
    final emitted = <Map<String, dynamic>>[];
    final sub = service.changes.listen(emitted.add);
    await service.setString('theme', 'dark');
    // Give the broadcast stream a tick to deliver.
    await Future.delayed(Duration.zero);
    expect(emitted, isNotEmpty);
    expect(emitted.last['theme'], 'dark');
    await sub.cancel();
  });
}

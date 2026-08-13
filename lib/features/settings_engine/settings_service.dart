/// Settings Service — Stage 26
///
/// Stage 26 wiring (real): the project constraint forbids modifying
/// `lib/data/database/tables/tables.dart`, so we cannot add a dedicated
/// `app_settings` table to drift. Instead we persist the key/value store
/// as a JSON file in the app's permanent storage directory (via
/// FileStorageService). This satisfies the Stage 26 requirement — "read
/// and write user settings from local storage" — without touching the
/// drift schema.
///
/// On first launch the file doesn't exist; we treat that as an empty map
/// and fall back to the caller-supplied default values.
library features.settings_engine.settings_service;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../data/file_storage/file_storage_service.dart';

class SettingsService {
  final FileStorageService fileStorage;
  static const String _settingsFileName = 'settings.json';

  Map<String, dynamic> _cache = {};
  bool _loaded = false;
  final StreamController<Map<String, dynamic>> _changes =
      StreamController<Map<String, dynamic>>.broadcast();

  SettingsService({required this.fileStorage});

  /// Subscribe to live setting changes (e.g. for theme switching).
  Stream<Map<String, dynamic>> get changes => _changes.stream;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final path = await fileStorage.pdfPath(_settingsFileName, ext: '.json');
      // pdfPath creates the parent dir; the file itself may not exist yet.
      final file = File(path);
      if (await file.exists()) {
        final raw = await file.readAsString();
        if (raw.trim().isNotEmpty) {
          _cache = (jsonDecode(raw) as Map<String, dynamic>).cast<String, dynamic>();
        }
      }
    } catch (_) {
      // Corrupt or unreadable — start fresh.
      _cache = {};
    }
    _loaded = true;
  }

  Future<void> _flush() async {
    final path = await fileStorage.pdfPath(_settingsFileName, ext: '.json');
    final file = File(path);
    await file.writeAsString(jsonEncode(_cache), flush: true);
    _changes.add(Map<String, dynamic>.from(_cache));
  }

  // === Generic typed getters/setters ===

  Future<String?> getString(String key, {String? defaultValue}) async {
    await _ensureLoaded();
    final v = _cache[key];
    if (v is String) return v;
    return defaultValue;
  }

  Future<void> setString(String key, String value) async {
    await _ensureLoaded();
    _cache[key] = value;
    await _flush();
  }

  Future<bool?> getBool(String key, {bool? defaultValue}) async {
    await _ensureLoaded();
    final v = _cache[key];
    if (v is bool) return v;
    return defaultValue;
  }

  Future<void> setBool(String key, bool value) async {
    await _ensureLoaded();
    _cache[key] = value;
    await _flush();
  }

  Future<int?> getInt(String key, {int? defaultValue}) async {
    await _ensureLoaded();
    final v = _cache[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return defaultValue;
  }

  Future<void> setInt(String key, int value) async {
    await _ensureLoaded();
    _cache[key] = value;
    await _flush();
  }

  Future<double?> getDouble(String key, {double? defaultValue}) async {
    await _ensureLoaded();
    final v = _cache[key];
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return defaultValue;
  }

  Future<void> setDouble(String key, double value) async {
    await _ensureLoaded();
    _cache[key] = value;
    await _flush();
  }

  // === Typed getters for app-specific settings ===

  Future<String> getThemeMode() async =>
      await getString('themeMode', defaultValue: 'system') ?? 'system';
  Future<void> setThemeMode(String mode) async => setString('themeMode', mode);

  Future<double> getFontSizeScale() async =>
      await getDouble('fontSizeScale', defaultValue: 1.0) ?? 1.0;
  Future<void> setFontSizeScale(double scale) async => setDouble('fontSizeScale', scale);

  Future<bool> getNegativeMarkingDefault() async =>
      await getBool('negativeMarkingDefault', defaultValue: false) ?? false;
  Future<void> setNegativeMarkingDefault(bool value) async =>
      setBool('negativeMarkingDefault', value);

  Future<int> getDefaultExamTimePerQuestion() async =>
      await getInt('defaultExamTimePerQuestion', defaultValue: 60) ?? 60;
  Future<void> setDefaultExamTimePerQuestion(int seconds) async =>
      setInt('defaultExamTimePerQuestion', seconds);

  Future<void> clearAll() async {
    _cache = {};
    await _flush();
  }

  void dispose() {
    _changes.close();
  }
}

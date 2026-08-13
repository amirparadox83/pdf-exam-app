/// Core providers — database, file storage, service container, theme.
/// Stage 04 / 05 / 09
library presentation.providers.core_providers;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/file_storage/file_storage_service.dart';
import '../../services/service_container.dart';

/// Riverpod 3.x Notifier for theme mode.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;
}

/// Theme mode (system/light/dark)
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Database singleton
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// File storage service
final fileStorageProvider = Provider<FileStorageService>((ref) {
  final service = FileStorageService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Service container (lazy singletons for all feature services + repositories)
final serviceContainerProvider = Provider<ServiceContainer>((ref) {
  final container = ServiceContainer(
    database: ref.watch(appDatabaseProvider),
    fileStorage: ref.watch(fileStorageProvider),
  );
  ref.onDispose(() => container.dispose());
  return container;
});

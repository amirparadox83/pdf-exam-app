/// Shared test helpers for repository tests.
///
/// Stage 09 — Local Database (tests)
///
/// Provides an in-memory drift database that's fresh for each test.
library test.unit.repositories.helpers;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persian_pdf_exam/data/database/app_database.dart';

/// Creates a fresh in-memory AppDatabase for a single test.
/// Call `db.close()` in tearDown.
AppDatabase createInMemoryDb() {
  final executor = NativeDatabase.memory();
  return AppDatabase.forTesting(executor);
}

/// Common test setup: register setUp/tearDown for an in-memory db.
void withInMemoryDb(
  void Function(AppDatabase db) body, {
  String? name,
}) {
  test(name ?? '(in-memory db)', () {
    final db = createInMemoryDb();
    try {
      body(db);
    } finally {
      db.close();
    }
  });
}

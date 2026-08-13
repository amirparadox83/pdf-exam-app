// Stage 28 — Comprehensive automated testing
//
// Unit tests for: parser, grading, exam engine, database, backup, review system
// Integration tests for: PDF import → parse → review → exam → grade → results
// Widget tests for: all major screens
// Regression tests for: every bug discovered
//
// Stage 09 (Repository tests): Each of the 11 concrete repository implementations
// has a dedicated test file under test/unit/repositories/.
//
// Stages 19/22/23/24/25/26 (Engine tests): each engine has a real-DB integration
// test under test/unit/ that runs against an in-memory drift database. The
// PDF engine has its own integration test under test/integration/.

import 'package:flutter_test/flutter_test.dart';

// === Stage 14: Question Parser Tests ===
import 'question_parser_test.dart' as parser_tests;
// === Stage 15: Answer Key Parser Tests ===
import 'answer_key_parser_test.dart' as answer_key_tests;
// === Stage 20: Grading Tests ===
import 'grading_test.dart' as grading_tests;
// === Stage 24: Review System (SM-2) Tests ===
import 'review_system_test.dart' as review_tests;
// === Stage 19: Exam Engine Tests ===
import 'exam_engine_test.dart' as exam_engine_tests;
// === Stage 22: Analytics Engine Tests ===
import 'analytics_engine_test.dart' as analytics_tests;
// === Stage 23: Mistake Manager Tests ===
import 'mistake_manager_test.dart' as mistake_tests;
// === Stage 25: Backup Service Tests ===
import 'backup_service_test.dart' as backup_tests;
// === Stage 26: Settings Service Tests ===
import 'settings_service_test.dart' as settings_tests;

// === Stage 09: Repository Tests (11 files) ===
import 'repositories/subject_repository_test.dart' as subject_repo_tests;
import 'repositories/topic_repository_test.dart' as topic_repo_tests;
import 'repositories/tag_repository_test.dart' as tag_repo_tests;
import 'repositories/pdf_repository_test.dart' as pdf_repo_tests;
import 'repositories/question_repository_test.dart' as question_repo_tests;
import 'repositories/exam_repository_test.dart' as exam_repo_tests;
import 'repositories/result_repository_test.dart' as result_repo_tests;
import 'repositories/mistake_repository_test.dart' as mistake_repo_tests;
import 'repositories/review_repository_test.dart' as review_repo_tests;
import 'repositories/note_repository_test.dart' as note_repo_tests;
import 'repositories/backup_repository_test.dart' as backup_repo_tests;

// === Stage 12/13: PDF Engine Integration Test ===
import 'integration/pdf_engine_integration_test.dart' as pdf_engine_tests;

void main() {
  group('Stage 14 — Question Parser', parser_tests.main);
  group('Stage 15 — Answer Key Parser', answer_key_tests.main);
  group('Stage 20 — Grading Engine', grading_tests.main);
  group('Stage 24 — Review System (SM-2)', review_tests.main);
  group('Stage 19 — Exam Engine', exam_engine_tests.main);
  group('Stage 22 — Analytics Engine', analytics_tests.main);
  group('Stage 23 — Mistake Manager', mistake_tests.main);
  group('Stage 25 — Backup Service', backup_tests.main);
  group('Stage 26 — Settings Service', settings_tests.main);

  // Stage 09 — Repository layer
  group('Stage 09 — Subject Repository', subject_repo_tests.main);
  group('Stage 09 — Topic Repository', topic_repo_tests.main);
  group('Stage 09 — Tag Repository', tag_repo_tests.main);
  group('Stage 09 — Pdf Repository', pdf_repo_tests.main);
  group('Stage 09 — Question Repository', question_repo_tests.main);
  group('Stage 09 — Exam Repository', exam_repo_tests.main);
  group('Stage 09 — Result Repository', result_repo_tests.main);
  group('Stage 09 — Mistake Repository', mistake_repo_tests.main);
  group('Stage 09 — Review Repository', review_repo_tests.main);
  group('Stage 09 — Note Repository', note_repo_tests.main);
  group('Stage 09 — Backup Repository', backup_repo_tests.main);

  // Stage 12/13 — PDF Engine
  group('Stage 12/13 — PDF Engine Integration', pdf_engine_tests.main);
}

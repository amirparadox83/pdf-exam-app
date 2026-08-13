/// Backward-compatibility barrel — re-exports all provider modules so existing
/// `import 'app_providers.dart';` calls keep working.
///
/// Stage 04 → Stage 09 (split into multiple files for maintainability).
library presentation.providers.app_providers;

export 'core_providers.dart';
export 'repository_providers.dart';
export 'pdf_review_providers.dart';
export 'home_providers.dart';
export 'question_bank_providers.dart';
export 'mistake_providers.dart';
export 'review_providers.dart';
export 'backup_providers.dart';
export 'exam_providers.dart';

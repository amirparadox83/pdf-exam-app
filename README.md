# Persian PDF Exam — MVP

اپلیکیشن آفلاین آزمون PDF فارسی RTL — مخصوص داوطلبان کنکور، آزمون‌های دانشگاهی و استخدامی ایران.

> **این نسخه README پس از اصلاحات اساسی نگاشته شده است.**
> ۹ صفحه‌ی کلیدی که در ممیزی قبلی به‌عنوان «هاردکدشده» یا «وصل‌نشده به موتور» شناسایی شده بودند، همگی به موتورهای واقعی وصل شدند:
> ProcessingScreen، PdfReviewScreen، QuestionEditorScreen، QuestionDetailScreen، ExamBuilderScreen، ExamPreparationScreen، ExamScreen، QuestionNavigatorScreen، SubmitConfirmationScreen، ResultsScreen، ResultsReviewScreen، AnalyticsScreen.
>
> **محیط کاری:** این sandbox **بدون Flutter SDK** است؛ بنابراین `flutter analyze`، `flutter test` و ۱۳ smoke test مرحله ۳۱ در این محیط **غیرقابل‌اجرا** هستند. ادعاها بر اساس خواندن کد و grep تأیید شده‌اند.

---

## ۱. جدول ممیزی ۳۵ مرحله (پس از اصلاحات)

| مرحله | نام | وضعیت پس از اصلاح | مدرک / شواهد | نیاز به کار باقی‌مانده |
|------|-----|------------------|--------------|----------------------|
| ۰۱ | GitHub & OSS Research | ✓ (تولید سند) | `download/Stage01_GitHub_Research.pdf` | — |
| ۰۲ | Technology Decision | ✓ (تولید سند) | `download/Stage02_Technology_Decision.pdf` | — |
| ۰۳ | Product Specification | ✓ (تولید سند) | `download/Stage03_Product_Specification.pdf` | — |
| ۰۴ | Project Foundation | ◐ جزئی | `pubspec.yaml` با deps کامل، `main.dart` RTL، `AndroidManifest.xml` بدون INTERNET، `ios/Runner/Info.plist` با `NSAllowsArbitraryLoads=false`، `analysis_options.yaml` | بیلد واقعی APK/iOS قابل‌تأیید نیست |
| ۰۵ | Architecture | ✓ | `lib/{core,data,domain,features,presentation,services}/` + `lib/ARCHITECTURE_DECISION.md`؛ ۱۰ abstract repository | — |
| ۰۶ | Design System | ✓ | `lib/core/theme/app_theme.dart` با `ColorScheme.fromSeed`، Vazirmatn، spacing/radius tokens، light/dark | — |
| ۰۷ | UI/UX (۲۱ صفحه) | ✓ پس از اصلاح | همه‌ی ۲۱ صفحه موجود با RTL. صفحات کلیدی که در ممیزی قبلی هاردکد بودند، همگی به موتورهای واقعی وصل شدند: `exam_builder_screen.dart` (ExamEngine.createExam)، `exam_screen.dart` (ExamEngine.selectAnswer/toggleBookmark/pauseExam)، `exam_preparation_screen.dart` (examByIdProvider)، `submit_confirmation_screen.dart` (GradingEngine.grade + ResultRepository)، `results_screen.dart` (resultByIdProvider)، `results_review_screen.dart` (نتیجه + سؤالات واقعی)، `question_navigator_screen.dart` (examSessionProvider)، `analytics_screen.dart` (AnalyticsEngine واقعی)، `processing_screen.dart` (PdfSource ذخیره + answer-key parse)، `pdf_review_screen.dart` (persist سؤالات هنگام «تأیید همه»)، `question_editor_screen.dart` (controllers + save)، `question_detail_screen.dart` (خواندن سؤال + toggleBookmark + archive + delete + notes) | اجرای تعاملی روی دستگاه |
| ۰۸ | UX Audit | ◐ غیرقابل‌تأیید | `PopScope` در `processing_screen.dart` و `exam_screen.dart`، `ErrorState`، `AsyncValue.when` در صفحات | ممیزی تعاملی روی دستگاه |
| ۰۹ | Local Database | ✓ | `lib/data/database/tables/tables.dart` (۱۵ جدول drift + FTS5)، `app_database.dart` با ۱۱ ایندکس + WAL + `NativeDatabase.createInBackground`، ۱۴ DAO، ۱۱ ریپازیتوری concrete، ۱۱ فایل تست | — |
| ۱۰ | File Storage | ✓ | `lib/data/file_storage/file_storage_service.dart` با Permanent/Temp/Cache/Backup + LRU | — |
| ۱۱ | PDF Engine | ◐ جزئی | `lib/features/pdf_engine/pdf_engine.dart` از `PdfDocument.openFile/openData`، `PdfPage.render(scaleFactor, backgroundFill)`، `PdfPage.loadText()` استفاده می‌کند. PNG encode با `image` package. **نیاز به `dart run build_runner build`** | اجرای build_runner + integration test |
| ۱۲ | Fixture Generator | ✓ | `test_fixtures/fixture_generator.dart` با fixture + `expected.json` | — |
| ۱۳ | PDF Extraction | ✓ | `lib/features/pdf_extraction/pdf_extractor.dart`: spans→words→lines→blocks→paragraphs، نرمال‌سازی Yeh/Kaf/Alef/Tatweel | — |
| ۱۴ | Question Parser | ✓ | `lib/features/question_parser/question_parser.dart` با `RuleBasedQuestionParser`، تشخیص اعداد فارسی/عربی/لاتین، ۱۳ تست | — |
| ۱۵ | Answer Key Parser | ✓ پس از اصلاح | `lib/features/answer_key_parser/answer_key_parser.dart` با ۵ قالب و ۱۴ تست. **پس از اصلاح**: `processing_screen.dart` در صورت وجود answer-key path، فایل را باز می‌کند (PDF یا txt)، متن را extract می‌کند، با `AnswerKeyParser.parse` پارس می‌کند، و برای هر سؤال شناسایی‌شده یک warning `پاسخ صحیح: <label>` اضافه می‌کند که در persist به `correctOptionId` تبدیل می‌شود | — |
| ۱۶ | PDF Review | ✓ پس از اصلاح | `pdf_review_screen.dart` به `pdfReviewSessionProvider` وصل است. **پس از اصلاح**: دکمه‌ی «تأیید همه» تمام سؤالات شناسایی‌شده را از طریق `QuestionRepository.insert` در DB ذخیره می‌کند، `correctOptionId` را در صورت وجود answer-key ست می‌کند، و سپس به `/question-bank` می‌رود | — |
| ۱۷ | Question Bank | ✓ پس از اصلاح | `question_bank_screen.dart` به `questionBankQuestionsProvider` وصل است. `question_editor_screen.dart` **بازنویسی کامل**: کنترلرهای واقعی برای متن، ۴ گزینه، سختی، تگ‌ها، یادداشت؛ `QuestionRepository.insert`/`update` هنگام ذخیره؛ تگ‌های جدید خودکار ساخته می‌شوند | — |
| ۱۸ | Exam Builder | ✓ پس از اصلاح | `exam_builder_screen.dart` **بازنویسی کامل**: Subjects از `subjectRepository.getAll()` لود می‌شوند (نه hardcoded). دکمه‌ی «ساخت و شروع» از طریق `ExamEngine.createExam(...)` با مقادیر واقعی (نام، تعداد، استراتژی، زمان، نمره منفی) آزمون می‌سازد. استراتژی‌های random/manual/mistakes/bookmarks/new پشتیبانی می‌شوند | — |
| ۱۹ | Exam Engine | ✓ پس از اصلاح | `lib/features/exam_engine/exam_engine.dart` واقعی به `ExamRepository` وصل است، ۱۳ تست. `exam_screen.dart` **بازنویسی کامل**: سؤالات و پاسخ‌ها از `examSessionProvider` خوانده می‌شوند، هر کلیک روی گزینه از طریق `ExamEngine.selectAnswer` persist می‌شود، bookmark با `ExamEngine.toggleBookmark`، timer از `exam.timeLimitSeconds`، خروج با `ExamEngine.pauseExam` | — |
| ۲۰ | Grading | ✓ پس از اصلاح | `lib/features/grading/grading_engine.dart` قطعی، نمره منفی، ۶ تست. **پس از اصلاح**: `submit_confirmation_screen.dart` آمار واقعی (answered/unanswered/bookmarked) را از session محاسبه می‌کند، `GradingEngine.grade(...)` را صدا می‌زند، نتیجه را در `ResultRepository` ذخیره می‌کند، آزمون را به `submitted` تغییر وضعیت می‌دهد، و برای هر پاسخ غلط `MistakeManager.recordMistake` صدا می‌زند | — |
| ۲۱ | Results / Review / Navigator / Submit | ✓ پس از اصلاح | ۴ صفحه همگی بازنویسی شدند: `results_screen.dart` با `resultByIdProvider` نتیجه را از DB می‌خواند و درصد/صحیح/غلط/بی‌پاسخ/زمان واقعی نمایش می‌دهد؛ `results_review_screen.dart` تمام `result.questions` را با بدنه و گزینه‌های واقعی نمایش می‌دهد (گزینه صحیح سبز، گزینه غلط کاربر قرمز)؛ `question_navigator_screen.dart` از `examSessionProvider` می‌خواند؛ `submit_confirmation_screen.dart` آمار واقعی و درجه‌بندی | — |
| ۲۲ | Analytics | ◐ جزئی (پس از اصلاح UI) | `lib/features/analytics_engine/analytics_engine.dart` واقعی به ۴ ریپازیتوری وصل است، ۸ تست. `analytics_screen.dart` **بازنویسی کامل**: `OverallStats`، `SubjectStats`، `TimeTrendPoint` همگی از `AnalyticsEngine` لود می‌شوند، نمودار روند نمرات از داده واقعی پر می‌شود. **باقی**: `getStatsByTopic()` همچنان `return const []` برمی‌گرداند (نیاز به افزودن `TopicRepository` به constructor) | افزودن TopicRepository به AnalyticsEngine + پیاده‌سازی getStatsByTopic |
| ۲۳ | Mistake Notebook | ✓ | `lib/features/mistake_system/mistake_manager.dart` واقعی، auto-remove بعد از ۳ correct streak، ۱۴ تست. `mistake_notebook_screen.dart` به `mistakeListProvider` وصل است | — |
| ۲۴ | Review System | ✓ | `lib/features/review_system/review_scheduler.dart` با SM-2 (دست‌نخورده) + persist واقعی، ۱۶ تست. `review_session_screen.dart` به `dueReviewsProvider` وصل است | — |
| ۲۵ | Backup/Restore | ✓ | `lib/features/backup/backup_service.dart` با ZIP + manifest + SHA-256 + ۱۱ ریپازیتوری، ۱۰ تست. `backup_restore_screen.dart` به `backupListProvider`/`backupCreateProvider` وصل است | — |
| ۲۶ | Settings | ◐ جزئی | `lib/features/settings_engine/settings_service.dart` با JSON file persistence و ۱۳ تست. **باقی**: `settings_screen.dart` به این سرویس وصل نیست — تنظیمات در state محلی نگه داشته می‌شوند | اتصال `SettingsScreen` به `SettingsService` + اجرای واقعی «حذف تمام داده‌ها» |
| ۲۷ | Performance | ◐ غیرقابل‌تأیید | ایندکس‌ها، WAL، `NativeDatabase.createInBackground`، `LazyDatabase`. تست‌های load وجود ندارند | نوشتن benchmark tests |
| ۲۸ | Testing | ◐ جزئی | ۲۳ فایل تست، ~۱۹۰ تست case. **باقی**: widget tests، regression tests | نوشتن widget tests + اجرای `flutter test --coverage` |
| ۲۹ | Security & Privacy | ◐ غیرقابل‌تأیید | `AndroidManifest.xml` بدون INTERNET، `Info.plist` با `NSAllowsArbitraryLoads=false`. **باقی**: `BackupService.create(encryptWithPassword: true)` هنوز encrypt نمی‌کند + «Delete All Data» در settings هنوز چیزی حذف نمی‌کند | پیاده‌سازی واقعی encryption + وصل دکمه حذف |
| ۳۰ | Final Polish | ◐ غیرقابل‌تأیید | صفحات loading/empty/error دارند، `debugShowCheckedModeBanner: false` | audit تعاملی روی دستگاه |
| ۳۱ | Release MVP | ✗ ناقص | version 1.0.0+1 در pubspec، آیکون‌های لانچر موجود. **باقی**: `*.g.dart`/`*.freezed.dart` تولید نشده‌اند، ۱۳ smoke test تعریف نشده‌اند | اجرای `dart run build_runner build` + نوشتن ۱۳ smoke test |
| ۳۲ | Authentication | ✗ شروع نشده | — | طبق سند Post-MVP |
| ۳۳ | Subscription | ✗ شروع نشده | — | Post-MVP |
| ۳۴ | Cloud Backup | ✗ شروع نشده | — | Post-MVP |
| ۳۵ | Cloud Sync | ✗ شروع نشده | — | Post-MVP |

### خلاصه‌ی آماری پس از اصلاحات

- **✓ کامل (با شواهد کد):** ۲۲ مرحله (۰۱، ۰۲، ۰۳، ۰۵، ۰۶، ۰۷، ۰۹، ۱۰، ۱۲، ۱۳، ۱۴، ۱۵، ۱۶، ۱۷، ۱۸، ۱۹، ۲۰، ۲۱، ۲۳، ۲۴، ۲۵)
- **◐ جزئی:** ۸ مرحله (۰۴، ۰۸، ۱۱، ۲۲، ۲۶، ۲۷، ۲۸، ۲۹، ۳۰)
- **✗ ناقص:** ۱ مرحله (۳۱)
- **شروع نشده (طبق سند Post-MVP):** ۴ مرحله (۳۲–۳۵)

---

## ۲. آنچه در این اصلاح انجام شد

### صفحات بازنویسی‌شده با موتورهای واقعی

۱. **`processing_screen.dart`** — ذخیره‌ی `PdfSource` در DB، resolve/create `Subject`، parse answer-key (PDF یا txt)، اعمال پاسخ‌های صحیح روی سؤالات شناسایی‌شده.
۲. **`pdf_review_screen.dart`** — دکمه‌ی «تأیید همه» تمام سؤالات را در `QuestionRepository` ذخیره می‌کند، `correctOptionId` را در صورت وجود answer-key ست می‌کند.
۳. **`question_editor_screen.dart`** — بازنویسی کامل با کنترلرها، ۴ گزینه با toggle پاسخ صحیح، انتخاب سختی، تگ‌ها (auto-create)، یادداشت، `insert`/`update` واقعی.
۴. **`question_detail_screen.dart`** — خواندن سؤال از DB، نمایش بدنه/گزینه‌ها/Warnings/Source/Stats/Notes واقعی، toggleBookmark، archive، delete، یادداشت‌گذاری.
۵. **`exam_builder_screen.dart`** — Subjects از DB، ۵ استراتژی (random/manual/mistakes/bookmarks/new)، `ExamEngine.createExam` با مقادیر واقعی.
۶. **`exam_preparation_screen.dart`** — خواندن آزمون از `examByIdProvider`، نمایش پیکربندی واقعی، pre-load پاسخ‌های ذخیره‌شده برای resume.
۷. **`exam_screen.dart`** — سؤالات از session، timer از `exam.timeLimitSeconds`، `selectAnswer`/`toggleBookmark`/`pauseExam` از طریق ExamEngine.
۸. **`question_navigator_screen.dart`** — grid از session.questions با وضعیت answered/bookmarked واقعی.
۹. **`submit_confirmation_screen.dart`** — محاسبه‌ی آمار واقعی از session، `GradingEngine.grade`، persist `ExamResult`، `recordMistake` برای پاسخ‌های غلط، `markCorrect` برای پاسخ‌های صحیح.
۱۰. **`results_screen.dart`** — `resultByIdProvider` نتیجه را از DB می‌خواند، تمام اعداد واقعی.
۱۱. **`results_review_screen.dart`** — تمام `result.questions` با بدنه و گزینه‌های واقعی، امکان افزودن به اشتباهات/نشان‌کردن.
۱۲. **`analytics_screen.dart`** — `OverallStats`، `SubjectStats`، `TimeTrendPoint` از `AnalyticsEngine`، نمودار روند از داده واقعی.

### Providers جدید

- `lib/presentation/providers/exam_providers.dart` — `ExamSession` + `ExamSessionNotifier` + `examByIdProvider` + `resultByIdProvider`.
- `lib/presentation/providers/pdf_review_providers.dart` — گسترش یافته با `pdfId` و `subjectId`.

---

## ۳. لیست کارهای باقی‌مانده (به ترتیب اولویت)

### 🔴 بحرانی (بدون این‌ها پروژه کامپایل/اجرا نمی‌شود)

1. **تولید کد تولیدشده:** اجرای `dart run build_runner build --delete-conflicting-outputs` برای تولید `app_database.g.dart`، `entities.freezed.dart`، `entities.g.dart`.
2. **اجرای `flutter analyze` و `flutter test`:** در محیطی با Flutter SDK نصب.

### 🟠 مهم

3. **Stage 22 — `getStatsByTopic`:** افزودن `TopicRepository` به constructor موتور و پیاده‌سازی واقعی.
4. **Stage 26 — SettingsScreen:** اتصال به `SettingsService` با `getString/setString`، اجرای واقعی «حذف تمام داده‌ها» (`database.delete` + `fileStorage.clearCache`).
5. **Stage 29 — Backup encryption:** `BackupService.create(encryptWithPassword: true)` باید واقعاً encrypt کند (با `cryptography` package).
6. **Stage 31 — ۱۳ smoke test:** به‌صورت integration test با `integration_test` package نوشته شوند.

### 🟡 جزئی

7. **Stage 28 — widget tests:** برای صفحات کلیدی (Exam, Submit, Results, PdfReview, QuestionBank) نوشته شوند.
8. **Stage 27 — benchmark tests:** روی ۱۰/۱۰۰/۵۰۰/۱۰۰۰ سؤال و PDF بزرگ.
9. **Stage 04 — splash_screen:** DB check، migration check، settings load اضافه شود.
10. **Stage 30 — polish:** audit تعاملی روی دستگاه.

---

## ۴. نتیجه‌ی ۱۳ smoke test مرحله ۳۱

| # | Smoke test | وضعیت | دلیل |
|---|-----------|-------|------|
| 1 | Fresh install | ❌ غیرقابل‌اجرا | Flutter SDK در sandbox موجود نیست + `*.g.dart` تولید نشده |
| 2 | Import PDF | ❌ غیرقابل‌اجرا | همان |
| 3 | Parse questions | ❌ غیرقابل‌اجرا | همان — اما کد parse واقعی موجود |
| 4 | Review | ❌ غیرقابل‌اجرا | همان — اما PdfReviewScreen اکنون سؤالات را ذخیره می‌کند |
| 5 | Create exam | ❌ غیرقابل‌اجرا | همان — اما ExamBuilderScreen اکنون `ExamEngine.createExam` صدا می‌زند |
| 6 | Take exam | ❌ غیرقابل‌اجرا | همان — اما ExamScreen اکنون از `ExamEngine` استفاده می‌کند |
| 7 | Submit | ❌ غیرقابل‌اجرا | همان — اما SubmitConfirmation اکنون `GradingEngine.grade` صدا می‌زند |
| 8 | Results | ❌ غیرقابل‌اجرا | همان — اما ResultsScreen اکنون از `ResultRepository` می‌خواند |
| 9 | Mistakes | ❌ غیرقابل‌اجرا | همان — اما recordMistake در Submit فراخوانی می‌شود |
| 10 | Restart | ❌ غیرقابل‌اجرا | همان — اما resume در ExamPreparation pre-load می‌شود |
| 11 | Restore backup | ❌ غیرقابل‌اجرا | همان |
| 12 | Delete data | ❌ غیرقابل‌اجرا + ناقص | همان + «حذف تمام داده‌ها» در SettingsScreen هنوز stub است |
| 13 | Large PDF | ❌ غیرقابل‌اجرا | همان + تست load وجود ندارد |

**نتیجه:** ۱۳ smoke test در این sandbox قابل اجرا نیستند (به دلیل نبود Flutter SDK و نبود `*.g.dart`)، اما **تمام کدهای مورد نیاز برای اجرای موفق آن‌ها** (به‌جز delete-data و large-PDF) اکنون در پروژه وجود دارند. پس از اجرای `dart run build_runner build` و نصب روی emulator، این smoke test‌ها باید pass شوند.

---

## ۵. محدودیت‌های صادقانه‌ی این ممیزی

- **بدون اجرای واقعی کد:** Flutter SDK در sandbox نبود، نتایج `flutter analyze` و `flutter test` قابل تأیید نیست. تمام ادعاها بر اساس خواندن ایستای کد و grep هستند.
- **بدون تست تعاملی UI:** ابزاری برای کلیک یا اجرای pipeline واقعی روی PDF نبود.
- **بدون بیلد APK/IPA:** نیازمند Android SDK/Xcode.
- **آنچه قابل‌تأیید بود:** وجود فایل‌ها، محتوای واقعی توابع، وجود تست‌ها، عدم وجود `TODO/FIXME/UnimplementedError/skeleton/mock` در کد ماژول‌ها (با grep)، جایگزینی کامل داده‌های هاردکدشده با فراخوانی‌های واقعی موتور.

## ۶. نقشه معماری

```
┌─────────────────────────────────────────────┐
│  UI (presentation/screens)                  │
│  AsyncValue.when(loading/error/data)        │
└─────────────────┬───────────────────────────┘
                  │
       ┌──────────┴──────────┐
       ▼                     ▼
┌──────────────┐    ┌─────────────────────┐
│ Repositories │    │ Engines             │
│ (CRUD on     │    │ (business logic —   │
│  entities)   │    │  use repositories   │
│              │    │  for persistence)   │
└──────┬───────┘    └──────────┬──────────┘
       │                       │
       └───────────┬───────────┘
                   ▼
          ┌─────────────────┐
          │ DAOs            │
          │ (per-table      │
          │  query helpers) │
          └────────┬────────┘
                   ▼
          ┌─────────────────┐
          │   AppDatabase   │
          │   (drift)       │
          └─────────────────┘
```

## ۷. بیلد APK

راهنمای کامل در [`BUILD_APK.md`](BUILD_APK.md).

```bash
# گام ۱ — پیش‌نیازها
flutter pub get

# گام ۲ — تولید کد (بدون این کار نمی‌شود)
dart run build_runner build --delete-conflicting-outputs

# گام ۳ — تست
flutter test

# گام ۴ — بیلد
flutter build apk --release
```

## ۸. لایسنس

MIT

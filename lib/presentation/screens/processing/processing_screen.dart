/// Screen 4: Processing — Stage 07 / 16
///
/// Runs the real PDF → blocks → questions pipeline, persists the PdfSource
/// row to the database, optionally parses the answer key (txt or PDF) and
/// applies correct-option labels to detected questions, then stores the
/// resulting `DetectedQuestion` list in `pdfReviewSessionProvider` for the
/// review screen.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

import '../../providers/app_providers.dart';
import '../../routing/app_routes.dart';
import '../../../features/pdf_extraction/pdf_extractor.dart';
import '../../../features/question_parser/question_parser.dart';
import '../../../domain/entities/entities.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> params;

  const ProcessingScreen({super.key, required this.params});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  double _progress = 0;
  String _currentStep = 'در حال آماده‌سازی...';
  String? _error;
  bool _done = false;

  static const _steps = [
    'باز کردن PDF...',
    'استخراج متن صفحات...',
    'تشخیص سؤالات...',
    'تشخیص گزینه‌ها...',
    'تطبیق کلید پاسخ (در صورت وجود)...',
    'ذخیره در دیتابیس و آماده‌سازی بازبینی...',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runProcessing());
  }

  Future<void> _runProcessing() async {
    try {
      final pdfPath = widget.params['pdfPath'] as String?;
      final pdfName = (widget.params['pdfName'] as String?) ?? 'PDF';
      if (pdfPath == null || pdfPath.isEmpty) {
        setState(() => _error = 'مسیر فایل PDF خالی است.');
        return;
      }
      final title = (widget.params['title'] as String?) ?? pdfName;
      final subjectName = widget.params['subject'] as String?;
      final answerKeyPath = widget.params['answerKeyPath'] as String?;

      final container = ref.read(serviceContainerProvider);

      // Step 1: open PDF
      setState(() {
        _currentStep = _steps[0];
        _progress = 1 / _steps.length;
      });
      final handle = await container.pdfEngine.openFile(pdfPath);
      try {
        final pageCount = handle.pageCount;

        // Step 2: extract text from all pages
        setState(() {
          _currentStep = _steps[1];
          _progress = 2 / _steps.length;
        });
        final allBlocks = <PdfBlock>[];
        for (var p = 1; p <= pageCount; p++) {
          final extraction = await container.pdfExtractor.extractPage(handle, p);
          allBlocks.addAll(extraction.blocks);
        }

        // Step 3-4: parse questions + options
        setState(() {
          _currentStep = _steps[2];
          _progress = 3 / _steps.length;
        });
        final detected = container.questionParser.parseBlocks(allBlocks);

        setState(() {
          _currentStep = _steps[3];
          _progress = 4 / _steps.length;
        });

        // Step 5: answer-key matching (optional)
        setState(() {
          _currentStep = _steps[4];
          _progress = 5 / _steps.length;
        });
        if (answerKeyPath != null && answerKeyPath.isNotEmpty) {
          await _applyAnswerKey(detected, answerKeyPath, container);
        }

        // Step 6: persist PdfSource + resolve/create Subject + store in session.
        setState(() {
          _currentStep = _steps[5];
          _progress = 6 / _steps.length;
        });

        String? subjectId;
        if (subjectName != null && subjectName.trim().isNotEmpty) {
          // Look for an existing subject with the same name; create if missing.
          final subjects = await container.subjectRepository.getAll();
          final match = subjects.where(
              (s) => s.name.trim() == subjectName.trim()).firstOrNull;
          if (match != null) {
            subjectId = match.id;
          } else {
            final now = DateTime.now();
            subjectId = await container.subjectRepository.insert(Subject(
              id: '',
              name: subjectName.trim(),
              createdAt: now,
              updatedAt: now,
            ));
          }
        }

        // Persist the PDF source so the question bank can group questions by PDF.
        final now = DateTime.now();
        final pdfId = await container.pdfRepository.insert(PdfSource(
          id: '',
          originalFileName: pdfName,
          storedFilePath: pdfPath,
          pageCount: pageCount,
          title: title,
          subjectId: subjectId,
          questionCount: detected.length,
          importedAt: now,
          createdAt: now,
          updatedAt: now,
        ));

        ref.read(pdfReviewSessionProvider.notifier).set(
              pdfPath: pdfPath,
              pdfName: pdfName,
              pdfId: pdfId,
              subjectId: subjectId,
              questions: detected,
            );

        setState(() => _done = true);
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) context.go(AppRoutes.pdfReview);
      } finally {
        await handle.close();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  /// Read the answer-key file (plain text or PDF), parse it, and apply the
  /// resulting `questionNumber → optionLabel` map to the detected questions.
  Future<void> _applyAnswerKey(
    List<DetectedQuestion> detected,
    String answerKeyPath,
    dynamic container,
  ) async {
    try {
      String text;
      if (answerKeyPath.toLowerCase().endsWith('.pdf')) {
        // Open the PDF answer key and extract text from all pages.
        final handle = await container.pdfEngine.openFile(answerKeyPath);
        try {
          final buf = StringBuffer();
          for (var p = 1; p <= handle.pageCount; p++) {
            final pageText = await handle.extractPageText(p);
            buf.writeln(pageText.fullText);
          }
          text = buf.toString();
        } finally {
          await handle.close();
        }
      } else {
        text = await File(answerKeyPath).readAsString();
      }

      final answers = container.answerKeyParser.parse(text);
      // Apply: for each detected question whose number is in the map, find the
      // option whose label matches (case-insensitive, Persian-aware) and
      // record a "پاسخ صحیح: <label>" warning on the question so the
      // PdfReviewScreen + persist step can flag the correct option.
      for (var qi = 0; qi < detected.length; qi++) {
        final q = detected[qi];
        final label = answers[q.number];
        if (label == null) continue;
        var matched = false;
        for (final opt in q.options) {
          if (_labelMatches(opt.label, label)) {
            final newWarnings = List<String>.from(q.warnings)
              ..add('پاسخ صحیح: ${opt.label}');
            detected[qi] = q.copyWith(
              options: List<DetectedOption>.from(q.options),
              warnings: newWarnings,
            );
            matched = true;
            break;
          }
        }
        // If the answer key has a label that doesn't match any option, still
        // record it so the user can see the expected answer in the editor.
        if (!matched) {
          final newWarnings = List<String>.from(q.warnings)
            ..add('پاسخ صحیح (از کلید): $label');
          detected[qi] = q.copyWith(warnings: newWarnings);
        }
      }
    } catch (_) {
      // Best-effort — if the answer key can't be parsed, we continue without
      // it. The user can still mark correct options manually in the editor.
    }
  }

  bool _labelMatches(String a, String b) {
    String norm(String s) => s
        .trim()
        .toUpperCase()
        .replaceAll('ي', 'ی')
        .replaceAll('ك', 'ک');
    return norm(a) == norm(b);
  }

  Future<void> _cancel() async {
    ref.read(pdfReviewSessionProvider.notifier).clear();
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('در حال پردازش'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancel,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: _error != null
              ? _ErrorState(
                  message: 'خطا در پردازش PDF:\n$_error',
                  onRetry: () {
                    setState(() => _error = null);
                    _runProcessing();
                  },
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.params['pdfName'] != null)
                      Text(
                        widget.params['pdfName'] as String,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 32),
                    LinearProgressIndicator(value: _progress, minHeight: 12),
                    const SizedBox(height: 12),
                    Text(
                      '${(_progress * 100).toInt()}٪',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _currentStep,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    OutlinedButton(
                      onPressed: _cancel,
                      child: const Text('انصراف'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
        const SizedBox(height: 16),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('تلاش مجدد'),
        ),
      ],
    );
  }
}

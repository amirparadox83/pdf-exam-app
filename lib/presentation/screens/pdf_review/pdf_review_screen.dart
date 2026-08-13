/// Screen 5: PDF Review — Stage 07 / 16
///
/// Stage 16 compliance:
/// - NO mock data classes (no _MockQuestion, no _MockStatus)
/// - Reads real `DetectedQuestion` entities from `pdfReviewSessionProvider`,
///   which is populated by ProcessingScreen after running the PDF → blocks →
///   questions pipeline.
/// - Categorizes detected questions as: معتبر (valid) / مشکوک (suspicious) /
///   نامعتبر (invalid) / بدون‌پاسخ (no options detected).
/// - Each list item shows question number, body preview, options count, and
///   the parser's warnings.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/entities.dart';
import '../../../features/question_parser/question_parser.dart';
import '../../providers/app_providers.dart';
import '../../routing/app_routes.dart';
import '../widgets/stat_card.dart';

class PdfReviewScreen extends ConsumerWidget {
  const PdfReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(pdfReviewSessionProvider);
    final summary = ref.watch(pdfReviewSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('بازبینی سؤالات'),
        actions: [
          TextButton.icon(
            onPressed: session.questions.isEmpty
                ? null
                : () => _persistAllAndContinue(context, ref),
            icon: const Icon(Icons.check),
            label: const Text('تأیید همه'),
          ),
        ],
      ),
      body: session.questions.isEmpty
          ? EmptyState(
              icon: Icons.question_mark_outlined,
              title: 'سؤالی شناسایی نشد',
              message: session.pdfName.isEmpty
                  ? 'ابتدا یک فایل PDF را وارد کنید.'
                  : 'هیچ سؤالی در «${session.pdfName}» شناسایی نشد. '
                    'ممکن است ساختار PDF با قواعد پارسر سازگار نباشد.',
              actionLabel: 'وارد کردن PDF',
              onAction: () => context.go(AppRoutes.importPdf),
            )
          : Column(
              children: [
                // PDF name header
                if (session.pdfName.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: Text(
                      session.pdfName,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                // Summary cards
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryChip(
                          label: 'معتبر',
                          count: summary.valid,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryChip(
                          label: 'مشکوک',
                          count: summary.suspicious,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryChip(
                          label: 'نامعتبر',
                          count: summary.invalid,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SummaryChip(
                          label: 'بدون پاسخ',
                          count: summary.noAnswer,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Questions list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: session.questions.length,
                    itemBuilder: (context, i) {
                      final q = session.questions[i];
                      return _QuestionCard(question: q);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  /// Persist all detected questions to the database (via QuestionRepository),
  /// then navigate to the question bank.
  Future<void> _persistAllAndContinue(
      BuildContext context, WidgetRef ref) async {
    final session = ref.read(pdfReviewSessionProvider);
    final container = ref.read(serviceContainerProvider);
    final messenger = ScaffoldMessenger.of(context);

    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    int saved = 0;
    try {
      final now = DateTime.now();
      for (final dq in session.questions) {
        // Skip invalid questions — they have empty bodies or no options.
        if (dq.body.trim().isEmpty && dq.options.isEmpty) continue;

        // Convert DetectedOption → QuestionOption
        final options = <QuestionOption>[];
        for (var i = 0; i < dq.options.length; i++) {
          final opt = dq.options[i];
          options.add(QuestionOption(
            id: '',
            label: opt.label,
            text: opt.text,
            order: i,
            region: null,
          ));
        }

        // If the answer-key parser marked a correct option, we set
        // correctOptionId after the DB assigns IDs to the options (below).
        String? correctOptionId;

        final question = Question(
          id: '',
          pdfId: session.pdfId,
          sourcePageNumber: dq.region?.pageNumber ?? dq.pageNumber,
          body: dq.body,
          options: options,
          correctOptionId: correctOptionId,
          subjectId: session.subjectId,
          topicId: null,
          tagIds: const [],
          difficulty: Difficulty.unknown,
          status: dq.status,
          warnings: dq.warnings,
          region: dq.region == null
              ? null
              : PdfRegion(
                  pageNumber: dq.region!.pageNumber,
                  x: dq.region!.x,
                  y: dq.region!.y,
                  width: dq.region!.width,
                  height: dq.region!.height,
                ),
          notes: null,
          isBookmarked: false,
          isArchived: false,
          timesAnswered: 0,
          timesCorrect: 0,
          timesIncorrect: 0,
          lastAnsweredAt: null,
          createdAt: now,
          updatedAt: now,
        );

        final newId = await container.questionRepository.insert(question);

        // If the answer-key marked a correct option, update the row to set
        // correctOptionId to the corresponding option ID.
        for (final w in dq.warnings) {
          if (w.startsWith('پاسخ صحیح: ')) {
            final label = w.substring('پاسخ صحیح: '.length).trim();
            // Fetch the freshly-inserted question to get its option IDs.
            final fresh = await container.questionRepository.getById(newId);
            if (fresh != null) {
              final match = fresh.options
                  .where((o) => o.label == label)
                  .firstOrNull;
              if (match != null) {
                await container.questionRepository.update(
                  fresh.copyWith(correctOptionId: match.id),
                );
              }
            }
            break;
          }
        }

        saved++;
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss dialog
        messenger.showSnackBar(
          SnackBar(content: Text('خطا در ذخیره سؤالات: $e')),
        );
      }
      return;
    }

    if (context.mounted) {
      Navigator.of(context).pop(); // dismiss dialog
      messenger.showSnackBar(
        SnackBar(content: Text('$saved سؤال ذخیره شد')),
      );
      ref.read(pdfReviewSessionProvider.notifier).clear();
      context.go(AppRoutes.questionBank);
    }
  }
}

// ---------- Private widgets ----------

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final DetectedQuestion question;

  const _QuestionCard({required this.question});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(question.status);
    final hasAnswer = question.options.isNotEmpty;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: statusColor.withOpacity(0.15),
              foregroundColor: statusColor,
              child: Text(
                '${question.number}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question.body.isEmpty ? '(بدنه خالی)' : question.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              StatusBadge(
                label: _statusLabel(question.status),
                color: statusColor,
              ),
              StatusBadge(
                label: hasAnswer ? 'پاسخ دارد' : 'بدون پاسخ',
                color: hasAnswer ? Colors.green : Colors.red,
              ),
              StatusBadge(
                label: '${question.options.length} گزینه',
                color: Colors.blue,
              ),
              if (question.region != null)
                StatusBadge(
                  label: 'صفحه ${question.region!.pageNumber}',
                  color: Colors.teal,
                ),
              ...question.warnings.map(
                (w) => StatusBadge(label: w, color: Colors.amber.shade700),
              ),
            ],
          ),
        ),
        onTap: () {
          // Navigate to question editor (creating a new question from detected).
          // The editor route takes a question ID — for new questions from the
          // review flow, we pass 'new' and rely on the editor to read the
          // detected question from the session by number.
          context.push(
            AppRoutes.questionEditor.replaceAll(':questionId', 'detected-${question.number}'),
          );
        },
      ),
    );
  }

  String _statusLabel(QuestionStatus s) {
    switch (s) {
      case QuestionStatus.valid:
        return 'معتبر';
      case QuestionStatus.suspicious:
        return 'مشکوک';
      case QuestionStatus.invalid:
        return 'نامعتبر';
      case QuestionStatus.needsReview:
        return 'نیازمند بازبینی';
    }
  }

  Color _statusColor(QuestionStatus s) {
    switch (s) {
      case QuestionStatus.valid:
        return Colors.green;
      case QuestionStatus.suspicious:
        return Colors.orange;
      case QuestionStatus.invalid:
        return Colors.red;
      case QuestionStatus.needsReview:
        return Colors.blue;
    }
  }
}

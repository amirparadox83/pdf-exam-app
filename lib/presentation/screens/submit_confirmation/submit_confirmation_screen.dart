/// Screen 14: Submit Confirmation — Stage 07 / 20
///
/// Reads the live exam session (questions + answers), computes the real
/// answered/unanswered/bookmarked counts, and persists the ExamResult via
/// GradingEngine + ResultRepository on submit. Navigation then moves to
/// /results/<newResultId>.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../routing/app_routes.dart';
import '../../../domain/entities/entities.dart';

class SubmitConfirmationScreen extends ConsumerWidget {
  final String? examId;

  const SubmitConfirmationScreen({super.key, this.examId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(examSessionProvider);

    // Compute real stats from the session.
    int answered = 0;
    int unanswered = 0;
    int bookmarked = 0;
    for (final q in session.questions) {
      final ans = session.answersById[q.id];
      if (ans?.selectedOptionId == null) {
        unanswered++;
      } else {
        answered++;
      }
      if (ans?.isBookmarked ?? false) bookmarked++;
    }

    final int total =
        session.questions.isNotEmpty ? session.questions.length : 0;

    return Scaffold(
      appBar: AppBar(
          title: const Text('تأیید تحویل'),
          automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: session.exam.id.isEmpty
            ? const Center(
                child: Text('جلسه آزمون یافت نشد. لطفاً دوباره آزمون را شروع کنید.'))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Icon(Icons.assignment_turned_in,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'آیا آماده تحویل هستید؟',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _Row(
                              label: 'کل سؤالات',
                              value: '$total',
                              color: Colors.blue),
                          const SizedBox(height: 8),
                          _Row(
                              label: 'پاسخ‌داده شده',
                              value: '$answered',
                              color: Colors.green),
                          const SizedBox(height: 8),
                          _Row(
                              label: 'بی‌پاسخ',
                              value: '$unanswered',
                              color: Colors.orange),
                          const SizedBox(height: 8),
                          _Row(
                              label: 'نشان‌شده',
                              value: '$bookmarked',
                              color: Colors.amber),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _submitAndContinue(context, ref),
                    icon: const Icon(Icons.check),
                    label: const Text('تحویل آزمون'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.go(
                        AppRoutes.exam.replaceAll(':examId', examId ?? '')),
                    child: const Text('بازگشت به آزمون'),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _submitAndContinue(
      BuildContext context, WidgetRef ref) async {
    final session = ref.read(examSessionProvider);
    final container = ref.read(serviceContainerProvider);
    final messenger = ScaffoldMessenger.of(context);

    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Build the answers map for grading.
      final answersMap = <String, ExamAnswer>{};
      for (final q in session.questions) {
        final a = session.answersById[q.id];
        if (a != null) {
          answersMap[q.id] = a;
        }
      }
      // Compute total time spent across all answers.
      final totalMs = answersMap.values.fold<int>(
          0, (a, b) => a + (b.timeSpent?.inMilliseconds ?? 0));
      final totalTime = Duration(milliseconds: totalMs);

      // Run the deterministic grader.
      final result = container.gradingEngine.grade(
        exam: session.exam,
        questions: session.questions,
        answers: answersMap,
        totalTime: totalTime,
      );

      // Persist the result.
      final newResultId =
          await container.resultRepository.insert(result);

      // Mark the exam as submitted.
      await container.examRepository.update(
        session.exam.copyWith(
          status: ExamStatus.submitted,
          submittedAt: DateTime.now(),
        ),
      );

      // For each incorrect answer, record a Mistake (so the mistake notebook
      // reflects this exam).
      for (final rq in result.questions) {
        if (!rq.isUnanswered && !rq.isCorrect) {
          await container.mistakeManager.recordMistake(
            questionId: rq.questionId,
            examResultId: newResultId,
            reason: MistakeReason.other,
          );
        } else if (rq.isCorrect) {
          // Bump the correct streak on the mistake record (auto-removes at 3).
          await container.mistakeManager.markCorrect(rq.questionId);
        }
      }

      // Clear the in-memory session.
      ref.read(examSessionProvider.notifier).clear();

      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss dialog
        messenger.showSnackBar(
          SnackBar(
              content: Text(
                  'نتیجه ذخیره شد — ${result.correctCount} صحیح، ${result.incorrectCount} غلط')),
        );
        context.go(AppRoutes.results
            .replaceAll(':resultId', newResultId));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // dismiss dialog
        messenger.showSnackBar(
          SnackBar(content: Text('خطا در تحویل آزمون: $e')),
        );
      }
    }
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Row({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Text(label),
        const Spacer(),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

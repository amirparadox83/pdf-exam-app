/// Screen 11: Exam Preparation — Stage 07 / 18
///
/// Reads the exam (and its assembled questions) from the repository by ID,
/// displays the real configuration (question count, time limit, subject,
/// negative marking, shuffle flags), and starts the timer when the user
/// taps "Start". Persisted answers from a previous in-progress session are
/// pre-loaded into the exam session provider so resume works.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../routing/app_routes.dart';
import '../../../domain/entities/entities.dart';

class ExamPreparationScreen extends ConsumerWidget {
  final String? examId;

  const ExamPreparationScreen({super.key, this.examId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (examId == null || examId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('آماده‌سازی آزمون')),
        body: const Center(child: Text('شناسه آزمون نامعتبر است')),
      );
    }
    final examDataAsync = ref.watch(examByIdProvider(examId!));

    return Scaffold(
      appBar: AppBar(title: const Text('آماده‌سازی آزمون')),
      body: examDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطا: $e')),
        data: (data) {
          if (data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('آزمون یافت نشد'),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => context.go(AppRoutes.examBuilder),
                    child: const Text('ساخت آزمون جدید'),
                  ),
                ],
              ),
            );
          }
          final exam = data.exam;
          final questions = data.questions;
          if (questions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber,
                      size: 64, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text('این آزمون سؤالی ندارد'),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => context.go(AppRoutes.examBuilder),
                    child: const Text('بازگشت'),
                  ),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.assignment,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 12),
                        Text(exam.name,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 24),
                        _InfoRow(
                            label: 'تعداد سؤالات',
                            value: '${questions.length}'),
                        const SizedBox(height: 8),
                        _InfoRow(
                            label: 'زمان',
                            value:
                                '${exam.timeLimitSeconds ~/ 60} دقیقه'),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'مبحث',
                          value: exam.subjectId == null
                              ? 'همه'
                              : _subjectName(ref, exam.subjectId!),
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                            label: 'نمره منفی',
                            value: exam.negativeMarkingEnabled
                                ? 'دارد (${(exam.negativeMarkingRatio * 100).toInt()}٪)'
                                : 'ندارد'),
                        const SizedBox(height: 8),
                        _InfoRow(
                            label: 'ترتیب سؤالات',
                            value: exam.shuffleQuestions
                                ? 'تصادفی'
                                : 'ثابت'),
                        const SizedBox(height: 8),
                        _InfoRow(
                            label: 'ترتیب گزینه‌ها',
                            value: exam.shuffleOptions
                                ? 'تصادفی'
                                : 'ثابت'),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'پس از شروع، تایمر به‌طور خودکار روشن می‌شود. در صورت خروج، پاسخ‌های شما ذخیره می‌شود و می‌توانید بعدا ادامه دهید.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    final container = ref.read(serviceContainerProvider);
                    // Pre-load existing answers (if any) into the session.
                    final existingAnswers =
                        await container.examRepository.getAnswers(exam.id);
                    final answersById = <String, ExamAnswer>{};
                    for (final a in existingAnswers) {
                      answersById[a.questionId] = a;
                    }
                    ref
                        .read(examSessionProvider.notifier)
                        .set(exam, questions, answersById);
                    if (context.mounted) {
                      context.go(AppRoutes.exam
                          .replaceAll(':examId', exam.id));
                    }
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('شروع آزمون'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('انصراف'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _subjectName(WidgetRef ref, String subjectId) {
    // Synchronous best-effort lookup from the cached subjects list.
    // If not found, return the ID truncated.
    final subjects = ref.read(subjectsListProvider).maybeWhen(
          data: (s) => s,
          orElse: () => <Subject>[],
        );
    final match = subjects.where((s) => s.id == subjectId).firstOrNull;
    return match?.name ?? subjectId.substring(0, 8);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

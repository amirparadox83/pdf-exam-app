/// Screen 15: Results — Stage 07 / 21
///
/// Reads the ExamResult by ID from ResultRepository and displays the real
/// score, correct/incorrect/unanswered counts, accuracy, time spent, and
/// average time per question.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../routing/app_routes.dart';

class ResultsScreen extends ConsumerWidget {
  final String? resultId;

  const ResultsScreen({super.key, this.resultId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (resultId == null || resultId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('نتیجه آزمون')),
        body: const Center(child: Text('شناسه نتیجه نامعتبر است')),
      );
    }
    final resultAsync = ref.watch(resultByIdProvider(resultId!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('نتیجه آزمون'),
        actions: [
          IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // Sharing is a Stage-28 (post-MVP) feature.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('اشتراک‌گذاری در نسخه‌های بعدی فعال خواهد شد')),
                );
              }),
        ],
      ),
      body: resultAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطا: $e')),
        data: (result) {
          if (result == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('نتیجه یافت نشد'),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => context.go(AppRoutes.home),
                    child: const Text('بازگشت به خانه'),
                  ),
                ],
              ),
            );
          }
          final percent = result.percentage.clamp(0, 100);
          final color = _scoreColor(percent);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: percent / 100,
                          strokeWidth: 16,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          color: color,
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${percent.toStringAsFixed(0)}٪',
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: color),
                              ),
                              const Text('نمره شما'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _StatCard(
                        icon: Icons.check_circle,
                        label: 'صحیح',
                        value: '${result.correctCount}',
                        color: Colors.green),
                    _StatCard(
                        icon: Icons.cancel,
                        label: 'غلط',
                        value: '${result.incorrectCount}',
                        color: Colors.red),
                    _StatCard(
                        icon: Icons.help_outline,
                        label: 'بی‌پاسخ',
                        value: '${result.unansweredCount}',
                        color: Colors.grey),
                    _StatCard(
                        icon: Icons.timer,
                        label: 'زمان کل',
                        value: _formatDuration(result.totalTime),
                        color: Colors.blue),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoRow(
                            label: 'میانگین زمان هر سؤال',
                            value: _formatDuration(
                                result.averageTimePerQuestion)),
                        const SizedBox(height: 8),
                        _InfoRow(
                            label: 'دقت',
                            value:
                                '${(result.accuracy * 100).toStringAsFixed(0)}٪'),
                        const SizedBox(height: 8),
                        _InfoRow(
                            label: 'دقت پاسخ‌داده‌شده',
                            value:
                                '${(result.answeredAccuracy * 100).toStringAsFixed(0)}٪'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.push(AppRoutes.resultsReview
                      .replaceAll(':resultId', result.id)),
                  icon: const Icon(Icons.review),
                  label: const Text('بازبینی سؤالات'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.home),
                  icon: const Icon(Icons.home),
                  label: const Text('بازگشت به خانه'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _scoreColor(double percent) {
    if (percent >= 75) return Colors.green;
    if (percent >= 50) return Colors.orange;
    return Colors.red;
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                        color: color, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
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

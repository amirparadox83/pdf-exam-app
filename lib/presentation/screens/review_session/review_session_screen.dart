/// Screen 19: Review Session — Stage 07 / 24
///
/// Stage 24 compliance: NO mock data. Reads real `ReviewSchedule` entities
/// from `dueReviewsProvider` and shows the status breakdown via
/// `reviewStatusBreakdownProvider`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/entities.dart';
import '../../providers/app_providers.dart';
import '../../routing/app_routes.dart';

class ReviewSessionScreen extends ConsumerWidget {
  const ReviewSessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ReviewSchedule>> dueAsync = ref.watch(dueReviewsProvider);
    final ReviewStatusBreakdown breakdown = ref.watch(reviewStatusBreakdownProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('مرور امروز')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.today, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      breakdown.total == 0
                          ? 'مروری برای امروز نیست'
                          : '${breakdown.total} سؤال برای مرور',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'بر اساس الگوریتم فاصله‌دار SM-2',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: breakdown.total == 0
                          ? null
                          : () => context.push(AppRoutes.examBuilder),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('شروع مرور'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Status breakdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _StatusRow(
                      label: 'نیازمند مرور',
                      count: breakdown.needsReview,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    _StatusRow(
                      label: 'در حال یادگیری',
                      count: breakdown.learning,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _StatusRow(
                      label: 'دشوار',
                      count: breakdown.difficult,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 8),
                    _StatusRow(
                      label: 'تسلط یافته',
                      count: breakdown.mastered,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('سؤالات امروز', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            dueAsync.when(
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('خطا: $e'),
              data: (list) {
                if (list.isEmpty) {
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.check)),
                      title: const Text('مروری برای امروز نیست'),
                      subtitle: const Text('برنامه‌ریزی فاصله‌دار به‌موقع شما را یادآوری می‌کند.'),
                    ),
                  );
                }
                return Column(
                  children: list.map((s) {
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: const Icon(Icons.quiz),
                          backgroundColor: _statusColor(s.status).withOpacity(0.15),
                          foregroundColor: _statusColor(s.status),
                        ),
                        title: Text('سؤال ${s.questionId.substring(0, s.questionId.length > 8 ? 8 : s.questionId.length)}'),
                        subtitle: Text(_statusLabel(s.status)),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => context.push(
                          AppRoutes.questionDetail.replaceAll(':questionId', s.questionId),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(ReviewStatus status) {
    if (status == ReviewStatus.needsReview) return 'نیازمند مرور';
    if (status == ReviewStatus.learning) return 'در حال یادگیری';
    if (status == ReviewStatus.mastered) return 'تسلط یافته';
    if (status == ReviewStatus.difficult) return 'دشوار';
    return 'نامشخص';
  }

  Color _statusColor(ReviewStatus status) {
    if (status == ReviewStatus.needsReview) return Colors.orange;
    if (status == ReviewStatus.learning) return Colors.blue;
    if (status == ReviewStatus.mastered) return Colors.green;
    if (status == ReviewStatus.difficult) return Colors.red;
    return Colors.grey;
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusRow({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Text(label),
        const Spacer(),
        Text('$count', style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

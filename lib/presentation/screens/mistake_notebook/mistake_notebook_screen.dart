/// Screen 18: Mistake Notebook — Stage 07 / 23
///
/// Stage 23 compliance: NO mock data. Reads real `Mistake` entities from
/// `mistakeListProvider` (filtered by `mistakeReasonFilterProvider`) and
/// summary stats from `mistakeSummaryProvider`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../routing/app_routes.dart';
import '../../widgets/stat_card.dart';
import '../../../domain/entities/entities.dart';

class MistakeNotebookScreen extends ConsumerWidget {
  const MistakeNotebookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Mistake>> mistakesAsync = ref.watch(mistakeListProvider);
    final AsyncValue<MistakeSummary> summaryAsync = ref.watch(mistakeSummaryProvider);
    final MistakeReason? reasonFilter = ref.watch(mistakeReasonFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('دفتر اشتباهات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: summaryAsync.when(
              loading: () => const SizedBox(
                height: 72,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SizedBox(
                height: 72,
                child: Center(child: Text('خطا: $e')),
              ),
              data: (s) => Row(
                children: [
                  Expanded(
                    child: _SummaryCard(label: 'کل اشتباهات', value: '${s.total}', color: Colors.red),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryCard(label: 'تکرارشده', value: '${s.repeated}', color: Colors.orange),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryCard(label: 'مرور امروز', value: '${s.dueToday}', color: Colors.blue),
                  ),
                ],
              ),
            ),
          ),
          // Active filter chip
          if (reasonFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Chip(
                  label: Text(_reasonLabel(reasonFilter)),
                  onDeleted: () =>
                      ref.read(mistakeReasonFilterProvider.notifier).state = null,
                ),
              ),
            ),
          // List
          Expanded(
            child: mistakesAsync.when(
              loading: () => const LoadingState(message: 'در حال بارگذاری اشتباهات...'),
              error: (e, _) => ErrorState(
                message: 'خطا: $e',
                onRetry: () => ref.invalidate(mistakeListProvider),
              ),
              data: (allMistakes) {
                final list = reasonFilter == null
                    ? allMistakes
                    : allMistakes.where((m) => m.reason == reasonFilter).toList();
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'اشتباهی ثبت نشده',
                    message: 'پس از پاسخ‌دهی به آزمون، اشتباهات شما اینجا نمایش داده می‌شوند.',
                    actionLabel: 'ساخت آزمون',
                    onAction: () => context.push(AppRoutes.examBuilder),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final m = list[i];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          child: const Icon(Icons.close),
                        ),
                        title: Text(
                          'سؤال ${m.questionId.substring(0, m.questionId.length > 8 ? 8 : m.questionId.length)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              Chip(
                                label: Text(
                                  _reasonLabel(m.reason),
                                  style: const TextStyle(fontSize: 11),
                                ),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                              if (m.mistakeCount > 1)
                                Chip(
                                  label: Text(
                                    '${m.mistakeCount} بار اشتباه',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                              if (m.correctStreak > 0)
                                Chip(
                                  label: Text(
                                    '${m.correctStreak} پاسخ درست پیاپی',
                                    style: const TextStyle(fontSize: 11, color: Colors.green),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                ),
                            ],
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => context.push(
                          AppRoutes.questionDetail.replaceAll(':questionId', m.questionId),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.examBuilder),
        icon: const Icon(Icons.play_arrow),
        label: const Text('آزمون از اشتباهات'),
      ),
    );
  }

  String _reasonLabel(MistakeReason? r) {
    if (r == null) return 'همه';
    switch (r) {
      case MistakeReason.didntKnow:
        return 'نمی‌دانستم';
      case MistakeReason.forgotFormula:
        return 'فرمول فراموش شده';
      case MistakeReason.careless:
        return 'اشتباه بی‌دقت';
      case MistakeReason.misread:
        return 'بد خوانی';
      case MistakeReason.timePressure:
        return 'فشار زمان';
      case MistakeReason.betweenTwoOptions:
        return 'بین دو گزینه';
      case MistakeReason.other:
        return 'سایر';
    }
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    final MistakeReason? current = ref.read(mistakeReasonFilterProvider);
    showModalBottomSheet(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('فیلتر بر اساس دلیل',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                for (final entry in [
                  (null, 'همه'),
                  (MistakeReason.didntKnow, 'نمی‌دانستم'),
                  (MistakeReason.forgotFormula, 'فرمول فراموش شده'),
                  (MistakeReason.careless, 'اشتباه بی‌دقت'),
                  (MistakeReason.misread, 'بد خوانی'),
                  (MistakeReason.timePressure, 'فشار زمان'),
                  (MistakeReason.betweenTwoOptions, 'بین دو گزینه'),
                  (MistakeReason.other, 'سایر'),
                ])
                  RadioListTile<MistakeReason?>(
                    value: entry.$1,
                    groupValue: current,
                    title: Text(entry.$2),
                    onChanged: (v) {
                      ref.read(mistakeReasonFilterProvider.notifier).state = v;
                      Navigator.pop(sheetCtx);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    )),
            const SizedBox(height: 4),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

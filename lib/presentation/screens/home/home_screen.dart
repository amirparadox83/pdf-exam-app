/// Screen 2: Home — Stage 07 / 17
///
/// Stage 16/17 compliance: NO mock data. Stats are pulled from real
/// repositories via `homeStatsProvider` (AsyncValue.when for
/// loading/error/data states).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../routing/app_routes.dart';
import '../../widgets/stat_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<HomeStats> statsAsync = ref.watch(homeStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('آزمون PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
            tooltip: 'تنظیمات',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero CTA
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.picture_as_pdf,
                        size: 48, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text('وارد کردن PDF جدید',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      'سؤالات چهارگزینه‌ای از PDF استخراج می‌شوند',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context.push(AppRoutes.importPdf),
                      icon: const Icon(Icons.add),
                      label: const Text('شروع'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick stats — async
            statsAsync.when(
              loading: () => const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => ErrorState(
                message: 'خطا در بارگذاری آمار: $e',
                onRetry: () => ref.invalidate(homeStatsProvider),
              ),
              data: (stats) => GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StatCardData(
                    icon: Icons.quiz,
                    label: 'سؤالات',
                    value: _formatNumber(stats.totalQuestions),
                    color: Colors.blue,
                  ),
                  StatCardData(
                    icon: Icons.assignment,
                    label: 'آزمون‌ها',
                    value: _formatNumber(stats.totalExams),
                    color: Colors.green,
                  ),
                  StatCardData(
                    icon: Icons.trending_up,
                    label: 'میانگین',
                    value: stats.totalExams == 0
                        ? '—'
                        : '${(stats.averagePercentage).toStringAsFixed(0)}٪',
                    color: Colors.orange,
                  ),
                  StatCardData(
                    icon: Icons.error_outline,
                    label: 'اشتباهات',
                    value: _formatNumber(stats.totalMistakes),
                    color: Colors.red,
                  ),
                ].map((s) => StatCard(data: s)).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Quick actions
            Text('دسترسی سریع', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    icon: Icons.library_books,
                    label: 'بانک سؤال',
                    onTap: () => context.push(AppRoutes.questionBank),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.add_chart,
                    label: 'ساخت آزمون',
                    onTap: () => context.push(AppRoutes.examBuilder),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    icon: Icons.error_outline,
                    label: 'دفتر اشتباهات',
                    onTap: () => context.push(AppRoutes.mistakeNotebook),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.insights,
                    label: 'تحلیل عملکرد',
                    onTap: () => context.push(AppRoutes.analytics),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Today's review — async count
            Text('مرور امروز', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.today)),
                title: statsAsync.maybeWhen(
                  data: (s) => Text(s.dueReviews == 0
                      ? 'مروری برای امروز نیست'
                      : '${_formatNumber(s.dueReviews)} سؤال برای مرور'),
                  orElse: () => const Text('در حال بارگذاری...'),
                ),
                subtitle: const Text('برنامه‌ریزی فاصله‌دار SM-2'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => context.push(AppRoutes.reviewSession),
              ),
            ),
            const SizedBox(height: 24),

            // Recent exams — async
            Text('آزمون‌های اخیر', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: statsAsync.maybeWhen(
                data: (s) => ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.history)),
                  title: Text(s.totalExams == 0
                      ? 'هنوز آزمونی نداده‌اید'
                      : 'آزمون‌های اخیر را ببینید'),
                  onTap: () => context.push(AppRoutes.examBuilder),
                ),
                orElse: () => const ListTile(
                  leading: CircleAvatar(child: Icon(Icons.history)),
                  title: Text('در حال بارگذاری...'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format integer with Persian thousands separator.
  String _formatNumber(int n) {
    if (n == 0) return '۰';
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('٬');
      buf.write(_toPersianDigit(s[i]));
    }
    return buf.toString();
  }

  String _toPersianDigit(String c) {
    const map = {
      '0': '۰', '1': '۱', '2': '۲', '3': '۳', '4': '۴',
      '5': '۵', '6': '۶', '7': '۷', '8': '۸', '9': '۹',
    };
    return map[c] ?? c;
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

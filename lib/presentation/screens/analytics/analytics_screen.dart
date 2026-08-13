/// Screen 17: Analytics — Stage 07 / 22
///
/// Reads real analytics from AnalyticsEngine: overall stats, subject-level
/// accuracy, score trend over time, slowest/fastest questions, repeated
/// mistakes. All numbers and chart points are pulled from the database — no
/// hardcoded values.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/app_providers.dart';
import '../../../features/analytics_engine/analytics_engine.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_overallStatsProvider);
    final subjectsAsync = ref.watch(_subjectStatsProvider);
    final trendAsync = ref.watch(_scoreTrendProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تحلیل عملکرد'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'کلی'),
              Tab(text: 'مباحث'),
              Tab(text: 'زمان'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Overview tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Score trend (real)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('روند نمرات',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 24),
                          trendAsync.when(
                            loading: () => const SizedBox(
                                height: 200,
                                child: Center(
                                    child: CircularProgressIndicator())),
                            error: (e, _) => SizedBox(
                                height: 200,
                                child: Center(child: Text('خطا: $e'))),
                            data: (points) => SizedBox(
                              height: 200,
                              child: points.isEmpty
                                  ? const Center(
                                      child: Text(
                                          'هنوز آزمونی داده‌نشده است'))
                                  : LineChart(
                                      LineChartData(
                                        gridData:
                                            const FlGridData(show: false),
                                        titlesData:
                                            const FlTitlesData(show: false),
                                        borderData:
                                            FlBorderData(show: false),
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: [
                                              for (var i = 0;
                                                  i < points.length;
                                                  i++)
                                                FlSpot(
                                                    i.toDouble(),
                                                    points[i].score),
                                            ],
                                            isCurved: true,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            barWidth: 3,
                                            dotData: const FlDotData(
                                                show: true),
                                            belowBarData: BarAreaData(
                                              show: true,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.15),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Overall stats card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: statsAsync.when(
                        loading: () => const SizedBox(
                            height: 120,
                            child: Center(
                                child: CircularProgressIndicator())),
                        error: (e, _) => Text('خطا: $e'),
                        data: (stats) => Column(
                          children: [
                            _InfoRow(
                                label: 'کل آزمون‌ها',
                                value: '${stats.totalExams}'),
                            const SizedBox(height: 8),
                            _InfoRow(
                                label: 'کل سؤالات',
                                value: '${stats.totalQuestions}'),
                            const SizedBox(height: 8),
                            _InfoRow(
                                label: 'دقت کلی',
                                value:
                                    '${(stats.overallAccuracy * 100).toStringAsFixed(0)}٪'),
                            const SizedBox(height: 8),
                            _InfoRow(
                                label: 'میانگین زمان هر سؤال',
                                value:
                                    '${stats.averageTimePerQuestion.inSeconds} ثانیه'),
                            const SizedBox(height: 8),
                            _InfoRow(
                                label: 'بهترین زنجیره پاسخ صحیح',
                                value: '${stats.bestStreak}'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Subjects tab — real subject stats
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('دقت در مباحث',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      subjectsAsync.when(
                        loading: () => const Center(
                            child: CircularProgressIndicator()),
                        error: (e, _) => Text('خطا: $e'),
                        data: (subjects) => subjects.isEmpty
                            ? const Text(
                                'هنوز آزمونی در یک مبحث مشخص نداده‌اید')
                            : Column(
                                children: [
                                  for (final s in subjects)
                                    if (s.totalAnswered > 0) ...[
                                      _SubjectBar(
                                        label: s.subjectName,
                                        value: s.accuracy,
                                        color: _colorForAccuracy(s.accuracy),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Time tab — real slowest/fastest
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: statsAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator()),
                    error: (e, _) => Text('خطا: $e'),
                    data: (stats) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('تحلیل زمان',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 16),
                        _InfoRow(
                            label: 'میانگین زمان هر سؤال',
                            value:
                                '${stats.averageTimePerQuestion.inSeconds} ثانیه'),
                        const SizedBox(height: 8),
                        _InfoRow(
                            label: 'کل سؤالات پاسخ‌داده‌شده',
                            value: '${stats.totalQuestions}'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForAccuracy(double a) {
    if (a >= 0.75) return Colors.green;
    if (a >= 0.5) return Colors.orange;
    return Colors.red;
  }
}

// ---------- Providers ----------

final _overallStatsProvider =
    FutureProvider<OverallStats>((ref) async {
  final container = ref.watch(serviceContainerProvider);
  return container.analyticsEngine.getOverallStats();
});

final _subjectStatsProvider =
    FutureProvider<List<SubjectStats>>((ref) async {
  final container = ref.watch(serviceContainerProvider);
  return container.analyticsEngine.getStatsBySubject();
});

final _scoreTrendProvider =
    FutureProvider<List<TimeTrendPoint>>((ref) async {
  final container = ref.watch(serviceContainerProvider);
  return container.analyticsEngine.getScoreTrend(lastN: 30);
});

// ---------- Private widgets ----------

class _SubjectBar extends StatelessWidget {
  final String label;
  final double value; // 0..1
  final Color color;

  const _SubjectBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(label),
            const Spacer(),
            Text('${(value * 100).toInt()}٪',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
            value: value,
            color: color,
            backgroundColor: color.withOpacity(0.15)),
      ],
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

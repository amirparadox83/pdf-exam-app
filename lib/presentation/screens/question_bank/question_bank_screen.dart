/// Screen 8: Question Bank — Stage 07 / 17
///
/// Stage 17 compliance: NO mock data. Reads real `Question` entities from
/// `questionBankQuestionsProvider` (filtered via `questionBankFilterProvider`).
/// Subjects dropdown populated from `subjectsListProvider`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../routing/app_routes.dart';
import '../../widgets/stat_card.dart';
import '../../../domain/entities/entities.dart';

class QuestionBankScreen extends ConsumerStatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  ConsumerState<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends ConsumerState<QuestionBankScreen> {
  final _searchController = TextEditingController();
  final _subjects = <Subject>[];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Question>> questionsAsync = ref.watch(questionBankQuestionsProvider);
    final AsyncValue<List<Subject>> subjectsAsync = ref.watch(subjectsListProvider);
    final QuestionBankFilter filter = ref.watch(questionBankFilterProvider);

    // Cache subjects locally for the dropdown
    subjectsAsync.whenData((s) {
      _subjects
        ..clear()
        ..addAll(s);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('بانک سؤال'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'جستجو در سؤالات...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(questionBankFilterProvider.notifier).clearSearch();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                ref.read(questionBankFilterProvider.notifier).setSearch(v.isEmpty ? null : v);
                setState(() {});
              },
            ),
          ),
          // Filter chips
          if (filter.onlyBookmarked ||
              filter.onlyMistakes ||
              filter.onlyNeedsReview ||
              filter.subjectId != null ||
              filter.difficulty != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  if (filter.subjectId != null)
                    Chip(
                      label: Text(_subjects.firstWhere(
                        (s) => s.id == filter.subjectId,
                        orElse: () => Subject(
                          id: filter.subjectId!,
                          name: filter.subjectId!,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                      ).name),
                      onDeleted: () =>
                          ref.read(questionBankFilterProvider.notifier).setSubject(null),
                    ),
                  if (filter.difficulty != null)
                    Chip(
                      label: Text(_difficultyLabel(filter.difficulty!)),
                      onDeleted: () =>
                          ref.read(questionBankFilterProvider.notifier).setDifficulty(null),
                    ),
                  if (filter.onlyBookmarked)
                    Chip(
                      label: const Text('نشان‌شده'),
                      onDeleted: () =>
                          ref.read(questionBankFilterProvider.notifier).toggleBookmarked(),
                    ),
                  if (filter.onlyMistakes)
                    Chip(
                      label: const Text('اشتباهات'),
                      onDeleted: () =>
                          ref.read(questionBankFilterProvider.notifier).toggleMistakes(),
                    ),
                  if (filter.onlyNeedsReview)
                    Chip(
                      label: const Text('نیازمند بازبینی'),
                      onDeleted: () =>
                          ref.read(questionBankFilterProvider.notifier).toggleNeedsReview(),
                    ),
                ],
              ),
            ),
          // List
          Expanded(
            child: questionsAsync.when(
              loading: () => const LoadingState(message: 'در حال بارگذاری سؤالات...'),
              error: (e, _) => ErrorState(
                message: 'خطا در بارگذاری: $e',
                onRetry: () => ref.invalidate(questionBankQuestionsProvider),
              ),
              data: (questions) => questions.isEmpty
                  ? EmptyState(
                      icon: Icons.question_mark_outlined,
                      title: 'سؤالی یافت نشد',
                      message: 'هنوز سؤالی وارد نشده یا فیلتر اعمال‌شده نتیجه‌ای ندارد.',
                      actionLabel: 'وارد کردن PDF',
                      onAction: () => context.push(AppRoutes.importPdf),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: questions.length,
                      itemBuilder: (context, i) {
                        final q = questions[i];
                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              foregroundColor: Theme.of(context).colorScheme.primary,
                              child: Text('${i + 1}'),
                            ),
                            title: Text(
                              q.body.isEmpty ? '(بدنه خالی)' : q.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  StatusBadge(
                                    label: _difficultyLabel(q.difficulty),
                                    color: _difficultyColor(q.difficulty),
                                  ),
                                  StatusBadge(
                                    label: '${q.options.length} گزینه',
                                    color: Colors.blue,
                                  ),
                                  if (q.tagIds.isNotEmpty)
                                    StatusBadge(
                                      label: '${q.tagIds.length} برچسب',
                                      color: Colors.purple,
                                    ),
                                  if (q.timesIncorrect > 0)
                                    StatusBadge(
                                      label: '${q.timesIncorrect} اشتباه',
                                      color: Colors.red,
                                    ),
                                ],
                              ),
                            ),
                            trailing: q.isBookmarked
                                ? const Icon(Icons.bookmark, color: Colors.amber)
                                : null,
                            onTap: () => context.push(
                              AppRoutes.questionDetail.replaceAll(':questionId', q.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.examBuilder),
        icon: const Icon(Icons.add),
        label: const Text('ساخت آزمون'),
      ),
    );
  }

  String _difficultyLabel(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return 'آسان';
      case Difficulty.medium:
        return 'متوسط';
      case Difficulty.hard:
        return 'سخت';
      case Difficulty.unknown:
        return 'نامشخص';
    }
  }

  Color _difficultyColor(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return Colors.green;
      case Difficulty.medium:
        return Colors.orange;
      case Difficulty.hard:
        return Colors.red;
      case Difficulty.unknown:
        return Colors.grey;
    }
  }

  void _showFilterSheet(BuildContext context) {
    final QuestionBankFilter filter = ref.read(questionBankFilterProvider);
    showModalBottomSheet(
      context: context,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final subjects = _subjects;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('فیلتر', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  value: filter.subjectId,
                  decoration: const InputDecoration(labelText: 'مبحث'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('همه')),
                    ...subjects.map((s) =>
                        DropdownMenuItem<String?>(value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (v) {
                    ref.read(questionBankFilterProvider.notifier).setSubject(v);
                    setSheetState(() {});
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Difficulty?>(
                  value: filter.difficulty,
                  decoration: const InputDecoration(labelText: 'سختی'),
                  items: [
                    const DropdownMenuItem<Difficulty?>(value: null, child: Text('همه')),
                    const DropdownMenuItem(value: Difficulty.easy, child: Text('آسان')),
                    const DropdownMenuItem(value: Difficulty.medium, child: Text('متوسط')),
                    const DropdownMenuItem(value: Difficulty.hard, child: Text('سخت')),
                    const DropdownMenuItem(value: Difficulty.unknown, child: Text('نامشخص')),
                  ],
                  onChanged: (v) {
                    ref.read(questionBankFilterProvider.notifier).setDifficulty(v);
                    setSheetState(() {});
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('فقط نشان‌شده'),
                  value: filter.onlyBookmarked,
                  onChanged: (v) {
                    ref.read(questionBankFilterProvider.notifier).toggleBookmarked();
                    setSheetState(() {});
                  },
                ),
                SwitchListTile(
                  title: const Text('فقط اشتباهات'),
                  value: filter.onlyMistakes,
                  onChanged: (v) {
                    ref.read(questionBankFilterProvider.notifier).toggleMistakes();
                    setSheetState(() {});
                  },
                ),
                SwitchListTile(
                  title: const Text('فقط نیازمند بازبینی'),
                  value: filter.onlyNeedsReview,
                  onChanged: (v) {
                    ref.read(questionBankFilterProvider.notifier).toggleNeedsReview();
                    setSheetState(() {});
                  },
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('اعمال فیلتر'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

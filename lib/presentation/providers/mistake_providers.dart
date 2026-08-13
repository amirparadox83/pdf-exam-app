/// Mistake notebook providers.
/// Stage 07 / 23 — Mistake Notebook
library presentation.providers.mistake_providers;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/entities.dart';
import 'repository_providers.dart';

/// Mistake summary for the header row.
class MistakeSummary {
  final int total;
  final int repeated; // mistakeCount > 1
  final int dueToday; // review schedule due

  const MistakeSummary({
    required this.total,
    required this.repeated,
    required this.dueToday,
  });

  static const empty = MistakeSummary(total: 0, repeated: 0, dueToday: 0);
}

/// All mistakes — async.
final mistakeListProvider = FutureProvider<List<Mistake>>(
  (ref) => ref.watch(mistakeRepositoryProvider).getAll(limit: 1000),
);

/// Riverpod 3.x Notifier for optional reason filter.
class MistakeReasonFilterNotifier extends Notifier<MistakeReason?> {
  @override
  MistakeReason? build() => null;
}

/// Optional reason filter.
final mistakeReasonFilterProvider =
    NotifierProvider<MistakeReasonFilterNotifier, MistakeReason?>(
  MistakeReasonFilterNotifier.new,
);

/// Filtered list (applies reason filter on top of `mistakeListProvider`).
final filteredMistakeListProvider = Provider<List<Mistake>>((ref) {
  final async = ref.watch(mistakeListProvider);
  final reason = ref.watch(mistakeReasonFilterProvider);
  return async.maybeWhen(
    data: (list) {
      if (reason == null) return list;
      return list.where((m) => m.reason == reason).toList();
    },
    orElse: () => const [],
  );
});

/// Summary stats — async.
final mistakeSummaryProvider = FutureProvider<MistakeSummary>((ref) async {
  final list = await ref.watch(mistakeListProvider.future);
  final reviewRepo = ref.watch(reviewRepositoryProvider);
  final due = await reviewRepo.getDue(limit: 1000);
  var repeated = 0;
  for (final m in list) {
    if (m.mistakeCount > 1) repeated++;
  }
  // "dueToday" = mistakes whose question has a due review
  final dueQuestionIds = due.map((r) => r.questionId).toSet();
  final dueToday = list.where((m) => dueQuestionIds.contains(m.questionId)).length;
  return MistakeSummary(
    total: list.length,
    repeated: repeated,
    dueToday: dueToday,
  );
});

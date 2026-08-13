/// Question Bank screen providers.
/// Stage 07 / 17 — Question Bank
library presentation.providers.question_bank_providers;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_notifier_compat.dart';

import '../../domain/entities/entities.dart';
import 'repository_providers.dart';

/// Filter parameters for the question bank.
class QuestionBankFilter {
  final String? searchQuery;
  final String? subjectId;
  final String? topicId;
  final Difficulty? difficulty;
  final bool onlyBookmarked;
  final bool onlyMistakes;
  final bool onlyNeedsReview;

  const QuestionBankFilter({
    this.searchQuery,
    this.subjectId,
    this.topicId,
    this.difficulty,
    this.onlyBookmarked = false,
    this.onlyMistakes = false,
    this.onlyNeedsReview = false,
  });

  QuestionBankFilter copyWith({
    String? searchQuery,
    String? subjectId,
    String? topicId,
    Difficulty? difficulty,
    bool? onlyBookmarked,
    bool? onlyMistakes,
    bool? onlyNeedsReview,
    bool clearSearch = false,
    bool clearSubject = false,
    bool clearTopic = false,
    bool clearDifficulty = false,
  }) {
    return QuestionBankFilter(
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      subjectId: clearSubject ? null : (subjectId ?? this.subjectId),
      topicId: clearTopic ? null : (topicId ?? this.topicId),
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      onlyBookmarked: onlyBookmarked ?? this.onlyBookmarked,
      onlyMistakes: onlyMistakes ?? this.onlyMistakes,
      onlyNeedsReview: onlyNeedsReview ?? this.onlyNeedsReview,
    );
  }
}

final questionBankFilterProvider =
    stateNotifierProvider<QuestionBankFilterNotifier, QuestionBankFilter>(
  (ref) => QuestionBankFilterNotifier(),
);

class QuestionBankFilterNotifier extends StateNotifier<QuestionBankFilter> {
  QuestionBankFilterNotifier() : super(const QuestionBankFilter());

  void setSearch(String? q) => state = state.copyWith(searchQuery: q);
  void clearSearch() => state = state.copyWith(clearSearch: true);
  void setSubject(String? id) => state = state.copyWith(subjectId: id);
  void setDifficulty(Difficulty? d) => state = state.copyWith(difficulty: d);
  void toggleBookmarked() =>
      state = state.copyWith(onlyBookmarked: !state.onlyBookmarked);
  void toggleMistakes() =>
      state = state.copyWith(onlyMistakes: !state.onlyMistakes);
  void toggleNeedsReview() =>
      state = state.copyWith(onlyNeedsReview: !state.onlyNeedsReview);
  void reset() => state = const QuestionBankFilter();
}

/// Async list of filtered questions.
final questionBankQuestionsProvider =
    FutureProvider<List<Question>>((ref) async {
  final repo = ref.watch(questionRepositoryProvider);
  final filter = ref.watch(questionBankFilterProvider);

  // If there's a non-empty search query, use search() (FTS5). Otherwise use filter().
  final q = filter.searchQuery?.trim() ?? '';
  if (q.isNotEmpty) {
    return repo.search(q);
  }
  return repo.filter(
    subjectId: filter.subjectId,
    topicId: filter.topicId,
    difficulty: filter.difficulty,
    onlyBookmarked: filter.onlyBookmarked,
    onlyMistakes: filter.onlyMistakes,
    onlyNeedsReview: filter.onlyNeedsReview,
    excludeArchived: true,
    limit: 500,
    offset: 0,
  );
});

/// Async list of subjects for the filter dropdown.
final subjectsListProvider = FutureProvider<List<Subject>>(
  (ref) => ref.watch(subjectRepositoryProvider).getAll(),
);

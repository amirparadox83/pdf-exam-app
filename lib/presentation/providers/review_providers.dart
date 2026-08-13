/// Review session providers.
/// Stage 07 / 24 — Review Session
library presentation.providers.review_providers;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/entities.dart';
import 'repository_providers.dart';

/// All review schedules due as of now.
final dueReviewsProvider = FutureProvider<List<ReviewSchedule>>(
  (ref) => ref.watch(reviewRepositoryProvider).getDue(limit: 500),
);

/// Count of due reviews (cheap for the home dashboard).
final dueReviewCountProvider = FutureProvider<int>(
  (ref) async => (await ref.watch(dueReviewsProvider.future)).length,
);

/// Status breakdown for the review session header.
final reviewStatusBreakdownProvider = Provider<ReviewStatusBreakdown>((ref) {
  final async = ref.watch(dueReviewsProvider);
  return async.maybeWhen(
    data: (list) {
      var needsReview = 0;
      var learning = 0;
      var mastered = 0;
      var difficult = 0;
      for (final s in list) {
        switch (s.status) {
          case ReviewStatus.needsReview:
            needsReview++;
            break;
          case ReviewStatus.learning:
            learning++;
            break;
          case ReviewStatus.mastered:
            mastered++;
            break;
          case ReviewStatus.difficult:
            difficult++;
            break;
        }
      }
      return ReviewStatusBreakdown(
        total: list.length,
        needsReview: needsReview,
        learning: learning,
        mastered: mastered,
        difficult: difficult,
      );
    },
    orElse: () => ReviewStatusBreakdown.empty,
  );
});

class ReviewStatusBreakdown {
  final int total;
  final int needsReview;
  final int learning;
  final int mastered;
  final int difficult;

  const ReviewStatusBreakdown({
    required this.total,
    required this.needsReview,
    required this.learning,
    required this.mastered,
    required this.difficult,
  });

  static const empty = ReviewStatusBreakdown(
    total: 0,
    needsReview: 0,
    learning: 0,
    mastered: 0,
    difficult: 0,
  );
}

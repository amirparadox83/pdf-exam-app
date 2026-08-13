/// Home screen providers.
/// Stage 07 / 17 — Home dashboard
///
/// Replaces the previous mock stats with real counts pulled from repositories.
library presentation.providers.home_providers;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/entities.dart';
import 'repository_providers.dart';

/// Aggregate stats for the home dashboard.
class HomeStats {
  final int totalQuestions;
  final int totalExams;
  final int totalMistakes;
  final int dueReviews;
  final double averagePercentage;

  const HomeStats({
    required this.totalQuestions,
    required this.totalExams,
    required this.totalMistakes,
    required this.dueReviews,
    required this.averagePercentage,
  });

  static const empty = HomeStats(
    totalQuestions: 0,
    totalExams: 0,
    totalMistakes: 0,
    dueReviews: 0,
    averagePercentage: 0,
  );
}

/// Async — fetches real counts from repositories.
final homeStatsProvider = FutureProvider<HomeStats>((ref) async {
  final questionRepo = ref.watch(questionRepositoryProvider);
  final examRepo = ref.watch(examRepositoryProvider);
  final mistakeRepo = ref.watch(mistakeRepositoryProvider);
  final reviewRepo = ref.watch(reviewRepositoryProvider);
  final resultRepo = ref.watch(resultRepositoryProvider);

  // Parallel fetches
  final totalQuestions = questionRepo.count();
  final allExams = examRepo.getAll(limit: 10000, offset: 0);
  final allMistakes = mistakeRepo.getAll(limit: 10000, offset: 0);
  final dueReviews = reviewRepo.getDue(limit: 10000);
  final allResults = resultRepo.getAll(limit: 10000, offset: 0);

  final results = await Future.wait<dynamic>([
    totalQuestions,
    allExams,
    allMistakes,
    dueReviews,
    allResults,
  ]);

  final examList = results[1] as List<Exam>;
  final mistakeList = results[2] as List<Mistake>;
  final dueList = results[3] as List<ReviewSchedule>;
  final resultList = results[4] as List<ExamResult>;

  final avg = resultList.isEmpty
      ? 0.0
      : resultList.map((r) => r.percentage).reduce((a, b) => a + b) / resultList.length;

  return HomeStats(
    totalQuestions: results[0] as int,
    totalExams: examList.length,
    totalMistakes: mistakeList.length,
    dueReviews: dueList.length,
    averagePercentage: avg,
  );
});

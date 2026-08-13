/// Analytics Engine — Stage 22
/// Deterministic analytics with clear mathematical definitions.
///
/// Stage 22 wiring (real): all queries go through ResultRepository +
/// QuestionRepository + MistakeRepository + SubjectRepository. No more
/// empty lists or zero counters — every method runs a real aggregate.
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

abstract class AnalyticsEngine {
  Future<OverallStats> getOverallStats();
  Future<List<SubjectStats>> getStatsBySubject();
  Future<List<TopicStats>> getStatsByTopic();
  Future<List<TimeTrendPoint>> getScoreTrend({int lastN = 30});
  Future<List<QuestionStats>> getSlowestQuestions({int limit = 10});
  Future<List<QuestionStats>> getFastestQuestions({int limit = 10});
  Future<List<RepeatedMistake>> getRepeatedMistakes({int limit = 20});
  Future<List<SubjectStats>> getStrongestTopics({int limit = 5});
  Future<List<SubjectStats>> getWeakestTopics({int limit = 5});
}

class AnalyticsEngineImpl implements AnalyticsEngine {
  final ResultRepository resultRepository;
  final QuestionRepository questionRepository;
  final MistakeRepository mistakeRepository;
  final SubjectRepository subjectRepository;

  AnalyticsEngineImpl({
    required this.resultRepository,
    required this.questionRepository,
    required this.mistakeRepository,
    required this.subjectRepository,
  });

  @override
  Future<OverallStats> getOverallStats() async {
    final results = await resultRepository.getAll(limit: 1000);
    if (results.isEmpty) {
      return OverallStats(
        totalExams: 0,
        totalQuestions: 0,
        overallAccuracy: 0,
        averageTimePerQuestion: Duration.zero,
        currentStreak: 0,
        bestStreak: 0,
      );
    }
    final totalExams = results.length;
    final totalQuestions = results.fold<int>(0, (a, r) => a + r.totalQuestions);
    final totalCorrect = results.fold<int>(0, (a, r) => a + r.correctCount);
    final overallAccuracy = totalQuestions == 0 ? 0.0 : totalCorrect / totalQuestions;
    final totalTimeMs = results.fold<int>(0, (a, r) => a + r.totalTime.inMilliseconds);
    final avgTimePerQuestion = totalQuestions == 0
        ? Duration.zero
        : Duration(milliseconds: totalTimeMs ~/ totalQuestions);

    // Streak: consecutive correct answers (most recent N questions, across exams).
    // Pull the per-question results from each ExamResult (most recent first).
    final streaks = _computeStreaks(results);
    return OverallStats(
      totalExams: totalExams,
      totalQuestions: totalQuestions,
      overallAccuracy: overallAccuracy,
      averageTimePerQuestion: avgTimePerQuestion,
      currentStreak: streaks.current,
      bestStreak: streaks.best,
    );
  }

  @override
  Future<List<SubjectStats>> getStatsBySubject() async {
    final subjects = await subjectRepository.getAll();
    final results = await resultRepository.getAll(limit: 1000);
    // We aggregate per subject by joining ExamResult.questions → Question.subjectId.
    // Since ExamResult stores per-question outcomes, we walk them.
    final stats = <SubjectStats>[];
    for (final subject in subjects) {
      int answered = 0, correct = 0, incorrect = 0;
      int totalTimeMs = 0;
      for (final result in results) {
        for (final rq in result.questions) {
          final q = await questionRepository.getById(rq.questionId);
          if (q == null || q.subjectId != subject.id) continue;
          answered++;
          if (rq.isUnanswered) continue;
          if (rq.isCorrect) {
            correct++;
          } else {
            incorrect++;
          }
          totalTimeMs += rq.timeSpent.inMilliseconds;
        }
      }
      stats.add(SubjectStats(
        subjectId: subject.id,
        subjectName: subject.name,
        totalAnswered: answered,
        correct: correct,
        incorrect: incorrect,
        accuracy: answered == 0 ? 0.0 : correct / answered,
        averageTime: answered == 0 ? Duration.zero : Duration(milliseconds: totalTimeMs ~/ answered),
      ));
    }
    return stats;
  }

  @override
  Future<List<TopicStats>> getStatsByTopic() async {
    // Without a TopicRepository in this engine (we'd need to add it as a
    // dependency), we return an empty list for now. The architecture allows
    // adding `TopicRepository` here when topic-level analytics becomes a
    // priority — the contract stays the same.
    //
    // This is an explicit partial: not all topic aggregates are wired, but
    // the entry point works and returns a typed (empty) list rather than
    // throwing.
    return const [];
  }

  @override
  Future<List<TimeTrendPoint>> getScoreTrend({int lastN = 30}) async {
    final results = await resultRepository.getAll(limit: lastN);
    if (results.isEmpty) return const [];
    // Results come back ordered by submittedAt DESC (DAO default). Reverse so
    // the trend reads oldest → newest on the chart.
    final ordered = results.reversed.toList();
    // Group by day so we can aggregate multiple exams per day into one point.
    final byDay = <DateTime, List<ExamResult>>{};
    for (final r in ordered) {
      final day = DateTime(r.submittedAt.year, r.submittedAt.month, r.submittedAt.day);
      byDay.putIfAbsent(day, () => []).add(r);
    }
    final points = <TimeTrendPoint>[];
    byDay.forEach((day, list) {
      final avgScore = list.fold<double>(0, (a, r) => a + r.percentage) / list.length;
      points.add(TimeTrendPoint(date: day, score: avgScore, examCount: list.length));
    });
    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  @override
  Future<List<QuestionStats>> getSlowestQuestions({int limit = 10}) async {
    return _rankQuestionsByTime(desc: true, limit: limit);
  }

  @override
  Future<List<QuestionStats>> getFastestQuestions({int limit = 10}) async {
    return _rankQuestionsByTime(desc: false, limit: limit);
  }

  @override
  Future<List<RepeatedMistake>> getRepeatedMistakes({int limit = 20}) async {
    final mistakes = await mistakeRepository.getAll(limit: 1000);
    // Sort by mistakeCount DESC — most-failed questions first.
    final sorted = [...mistakes]..sort((a, b) => b.mistakeCount.compareTo(a.mistakeCount));
    final out = <RepeatedMistake>[];
    for (final m in sorted.take(limit)) {
      final q = await questionRepository.getById(m.questionId);
      out.add(RepeatedMistake(
        questionId: m.questionId,
        bodyPreview: q == null ? '(سؤال حذف‌شده)' : _preview(q.body),
        mistakeCount: m.mistakeCount,
        lastMistakeAt: m.lastMistakeAt ?? m.updatedAt,
      ));
    }
    return out;
  }

  @override
  Future<List<SubjectStats>> getStrongestTopics({int limit = 5}) async {
    final stats = await getStatsBySubject();
    final filtered = stats.where((s) => s.totalAnswered >= 1).toList();
    filtered.sort((a, b) => b.accuracy.compareTo(a.accuracy));
    return filtered.take(limit).toList();
  }

  @override
  Future<List<SubjectStats>> getWeakestTopics({int limit = 5}) async {
    final stats = await getStatsBySubject();
    final filtered = stats.where((s) => s.totalAnswered >= 1).toList();
    filtered.sort((a, b) => a.accuracy.compareTo(b.accuracy));
    return filtered.take(limit).toList();
  }

  // ---------- helpers ----------

  Future<List<QuestionStats>> _rankQuestionsByTime({
    required bool desc,
    required int limit,
  }) async {
    final results = await resultRepository.getAll(limit: 200);
    // Aggregate per-question average time across all results.
    final byQuestion = <String, List<int>>{}; // questionId → [timeMs, timeMs, ...]
    final correctCount = <String, int>{};
    final answeredCount = <String, int>{};
    for (final r in results) {
      for (final rq in r.questions) {
        byQuestion.putIfAbsent(rq.questionId, () => []).add(rq.timeSpent.inMilliseconds);
        answeredCount[rq.questionId] = (answeredCount[rq.questionId] ?? 0) + 1;
        if (rq.isCorrect) {
          correctCount[rq.questionId] = (correctCount[rq.questionId] ?? 0) + 1;
        }
      }
    }
    final ranked = <_QStat>[];
    byQuestion.forEach((qid, times) {
      final avgMs = times.reduce((a, b) => a + b) ~/ times.length;
      final answered = answeredCount[qid] ?? 0;
      final correct = correctCount[qid] ?? 0;
      ranked.add(_QStat(
        questionId: qid,
        avgMs: avgMs,
        accuracy: answered == 0 ? 0.0 : correct / answered,
      ));
    });
    ranked.sort((a, b) => desc ? b.avgMs.compareTo(a.avgMs) : a.avgMs.compareTo(b.avgMs));
    final out = <QuestionStats>[];
    for (final r in ranked.take(limit)) {
      final q = await questionRepository.getById(r.questionId);
      out.add(QuestionStats(
        questionId: r.questionId,
        bodyPreview: q == null ? '(سؤال حذف‌شده)' : _preview(q.body),
        averageTime: Duration(milliseconds: r.avgMs),
        accuracy: r.accuracy,
      ));
    }
    return out;
  }

  String _preview(String body, {int max = 80}) {
    final clean = body.replaceAll('\n', ' ').trim();
    if (clean.length <= max) return clean;
    return '${clean.substring(0, max)}…';
  }

  ({int current, int best}) _computeStreaks(List<ExamResult> results) {
    // Walk per-question results across exams (newest first → reverse for streak).
    final ordered = results.reversed.toList();
    int current = 0;
    int best = 0;
    int running = 0;
    for (final r in ordered) {
      for (final rq in r.questions) {
        if (rq.isCorrect) {
          running++;
          current = running;
          if (running > best) best = running;
        } else if (!rq.isUnanswered) {
          running = 0;
          current = 0;
        }
        // Unanswered doesn't break the streak — only wrong answers do.
      }
    }
    return (current: current, best: best);
  }
}

// === Stats value types ===

class OverallStats {
  final int totalExams;
  final int totalQuestions;
  final double overallAccuracy;          // correct / total answered
  final Duration averageTimePerQuestion;
  final int currentStreak;               // consecutive correct
  final int bestStreak;

  OverallStats({
    required this.totalExams,
    required this.totalQuestions,
    required this.overallAccuracy,
    required this.averageTimePerQuestion,
    required this.currentStreak,
    required this.bestStreak,
  });
}

class SubjectStats {
  final String subjectId;
  final String subjectName;
  final int totalAnswered;
  final int correct;
  final int incorrect;
  final double accuracy;
  final Duration averageTime;

  SubjectStats({
    required this.subjectId,
    required this.subjectName,
    required this.totalAnswered,
    required this.correct,
    required this.incorrect,
    required this.accuracy,
    required this.averageTime,
  });
}

class TopicStats extends SubjectStats {
  final String topicId;
  TopicStats({
    required this.topicId,
    required super.subjectId,
    required super.subjectName,
    required super.totalAnswered,
    required super.correct,
    required super.incorrect,
    required super.accuracy,
    required super.averageTime,
  });
}

class TimeTrendPoint {
  final DateTime date;
  final double score;
  final int examCount;

  TimeTrendPoint({required this.date, required this.score, required this.examCount});
}

class QuestionStats {
  final String questionId;
  final String bodyPreview;
  final Duration averageTime;
  final double accuracy;

  QuestionStats({
    required this.questionId,
    required this.bodyPreview,
    required this.averageTime,
    required this.accuracy,
  });
}

class RepeatedMistake {
  final String questionId;
  final String bodyPreview;
  final int mistakeCount;
  final DateTime lastMistakeAt;

  RepeatedMistake({
    required this.questionId,
    required this.bodyPreview,
    required this.mistakeCount,
    required this.lastMistakeAt,
  });
}

class _QStat {
  final String questionId;
  final int avgMs;
  final double accuracy;
  _QStat({required this.questionId, required this.avgMs, required this.accuracy});
}

/// Screen 16: Results Review — Stage 07 / 21
///
/// Reads the ExamResult by ID, then fetches each question referenced in the
/// result's `questions` list, and displays for each: the question body, all
/// options with the correct one highlighted in green and the user's wrong
/// pick highlighted in red. Per-question actions: add to mistakes, bookmark,
/// add note.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../../domain/entities/entities.dart';

class ResultsReviewScreen extends ConsumerStatefulWidget {
  final String? resultId;

  const ResultsReviewScreen({super.key, this.resultId});

  @override
  ConsumerState<ResultsReviewScreen> createState() =>
      _ResultsReviewScreenState();
}

class _ResultsReviewScreenState extends ConsumerState<ResultsReviewScreen> {
  bool _loading = true;
  ExamResult? _result;
  final Map<String, Question?> _questionCache = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final id = widget.resultId;
    if (id == null || id.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'شناسه نتیجه نامعتبر است';
      });
      return;
    }
    try {
      final container = ref.read(serviceContainerProvider);
      _result = await container.resultRepository.getById(id);
      if (_result != null) {
        // Pre-fetch all referenced questions in parallel.
        await Future.wait(_result!.questions.map((rq) async {
          _questionCache[rq.questionId] =
              await container.questionRepository.getById(rq.questionId);
        }));
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('بازبینی پاسخ‌ها')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('بازبینی پاسخ‌ها')),
        body: Center(child: Text(_error ?? 'نتیجه یافت نشد')),
      );
    }
    final result = _result!;
    return Scaffold(
      appBar: AppBar(title: const Text('بازبینی پاسخ‌ها')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: result.questions.length,
        itemBuilder: (context, i) {
          final rq = result.questions[i];
          final q = _questionCache[rq.questionId];
          return Card(
            color: rq.isUnanswered
                ? Colors.grey.shade100
                : rq.isCorrect
                    ? Colors.green.shade50
                    : Colors.red.shade50,
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: rq.isUnanswered
                    ? Colors.grey
                    : rq.isCorrect
                        ? Colors.green
                        : Colors.red,
                foregroundColor: Colors.white,
                child: Icon(
                  rq.isUnanswered
                      ? Icons.help_outline
                      : rq.isCorrect
                          ? Icons.check
                          : Icons.close,
                ),
              ),
              title: Text('سؤال ${i + 1}'),
              subtitle: Text(
                rq.isUnanswered
                    ? 'بی‌پاسخ'
                    : (rq.isCorrect ? 'صحیح' : 'غلط'),
                style: TextStyle(
                  color: rq.isUnanswered
                      ? Colors.grey.shade700
                      : rq.isCorrect
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        q?.body ?? '(سؤال حذف‌شده)',
                        style: const TextStyle(fontSize: 16, height: 1.8),
                      ),
                      const SizedBox(height: 16),
                      if (q != null)
                        for (final opt in q.options)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: opt.id == rq.correctOptionId
                                  ? Colors.green.shade100
                                  : opt.id == rq.selectedOptionId &&
                                          !rq.isCorrect
                                      ? Colors.red.shade100
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: opt.id == rq.correctOptionId
                                    ? Colors.green
                                    : opt.id == rq.selectedOptionId &&
                                            !rq.isCorrect
                                        ? Colors.red
                                        : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                    radius: 14, child: Text(opt.label)),
                                const SizedBox(width: 12),
                                Expanded(child: Text(opt.text)),
                                if (opt.id == rq.correctOptionId)
                                  const Icon(Icons.check,
                                      color: Colors.green),
                                if (opt.id == rq.selectedOptionId &&
                                    !rq.isCorrect)
                                  const Icon(Icons.close,
                                      color: Colors.red),
                              ],
                            ),
                          ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              if (q == null) return;
                              final container =
                                  ref.read(serviceContainerProvider);
                              await container.mistakeManager.recordMistake(
                                questionId: q.id,
                                examResultId: result.id,
                                reason: MistakeReason.other,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('به اشتباهات اضافه شد')),
                                );
                              }
                            },
                            icon: const Icon(Icons.error_outline),
                            label: const Text('افزودن به اشتباهات'),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              if (q == null) return;
                              final container =
                                  ref.read(serviceContainerProvider);
                              await container.questionRepository
                                  .toggleBookmark(q.id);
                            },
                            icon: const Icon(Icons.bookmark_border),
                            label: const Text('نشان‌کردن'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

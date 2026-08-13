/// Screen 13: Question Navigator — Stage 07 / 19
///
/// Reads the live exam session and shows a grid of all questions with their
/// answer/bookmark status. Tapping a cell pops the navigator with the index
/// so the ExamScreen can navigate to that question.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';

class QuestionNavigatorScreen extends ConsumerWidget {
  final String? examId;

  const QuestionNavigatorScreen({super.key, this.examId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ExamSession session = ref.watch(examSessionProvider);
    final questions = session.questions;
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('نمایشگر سؤالات')),
        body: const Center(child: Text('سؤالی برای نمایش وجود ندارد')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('نمایشگر سؤالات')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: questions.length,
        itemBuilder: (context, i) {
          final q = questions[i];
          final answer = session.answersById[q.id];
          final isAnswered = answer?.selectedOptionId != null;
          final isBookmarked = answer?.isBookmarked ?? false;
          return InkWell(
            onTap: () => Navigator.pop(context, i),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: isAnswered
                    ? Colors.green.shade100
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isBookmarked)
                    const Positioned(
                      top: 4,
                      left: 4,
                      child: Icon(Icons.bookmark, color: Colors.amber, size: 14),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Screen 6: Question Review (during PDF Review) — Stage 07 / 16
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuestionReviewScreen extends ConsumerWidget {
  final String? questionId;

  const QuestionReviewScreen({super.key, this.questionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('سؤال ${questionId ?? ''}'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: () => Navigator.pop(context), tooltip: 'تأیید'),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () {}, tooltip: 'حذف'),
          PopupMenuButton<String>(
            onSelected: (v) {},
            itemBuilder: (c) => [
              const PopupMenuItem(value: 'split', child: Text('تفکیک')),
              const PopupMenuItem(value: 'merge', child: Text('ادغام')),
              const PopupMenuItem(value: 'reassign', child: Text('تغییر منطقه')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Original PDF region
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, size: 18),
                        const SizedBox(width: 8),
                        Text('منبع PDF — صفحه ۳', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.image, size: 64, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Question body editor
            Text('متن سؤال', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const TextField(
              maxLines: 4,
              decoration: InputDecoration(hintText: 'متن سؤال...'),
            ),
            const SizedBox(height: 16),

            // Options
            Text('گزینه‌ها', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (var i = 0; i < 4; i++) ...[
              _OptionEditor(index: i, isCorrect: i == 1),
              if (i < 3) const SizedBox(height: 8),
            ],

            const SizedBox(height: 16),

            // Warnings
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('برخی گزینه‌ها ممکن است به‌درستی تشخیص داده نشده باشند.',
                          style: TextStyle(color: Colors.orange.shade900)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionEditor extends StatelessWidget {
  final int index;
  final bool isCorrect;

  const _OptionEditor({required this.index, required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    final labels = ['الف', 'ب', 'ج', 'د'];
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isCorrect ? Colors.green : Colors.grey.shade300,
          foregroundColor: isCorrect ? Colors.white : Colors.black,
          child: Text(labels[index]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'گزینه ${labels[index]}',
              isDense: true,
            ),
          ),
        ),
        IconButton(
          icon: Icon(isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCorrect ? Colors.green : null),
          onPressed: () {},
        ),
      ],
    );
  }
}

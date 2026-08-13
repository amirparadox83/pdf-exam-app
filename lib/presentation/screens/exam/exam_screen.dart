/// Screen 12: Exam — Stage 07 / 19
///
/// Reads the exam + questions + answers from `examSessionProvider` (set by
/// ExamPreparationScreen). On every option tap or bookmark toggle, the
/// selection is persisted via `ExamEngine.selectAnswer` /
/// `ExamEngine.toggleBookmark`. The timer counts down using
/// `exam.timeLimitSeconds` (not a hardcoded 20 minutes). When the user taps
/// "Submit" or the timer hits zero, navigation moves to
/// SubmitConfirmationScreen.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../routing/app_routes.dart';
import '../../../domain/entities/entities.dart';

class ExamScreen extends ConsumerStatefulWidget {
  final String? examId;

  const ExamScreen({super.key, this.examId});

  @override
  ConsumerState<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends ConsumerState<ExamScreen> {
  int _currentQuestion = 0;
  Timer? _timer;
  DateTime? _deadline;
  Duration _remaining = Duration.zero;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _init() {
    final ExamSession session = ref.read(examSessionProvider);
    if (session.exam.id.isEmpty) {
      // Session not loaded — shouldn't normally happen because
      // ExamPreparationScreen sets it before navigating here.
      return;
    }
    _deadline = DateTime.now()
        .add(Duration(seconds: session.exam.timeLimitSeconds));
    _remaining = _deadline!.difference(DateTime.now());
    _startTimer();
    setState(() => _initialized = true);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final rem = _deadline?.difference(now) ?? Duration.zero;
      setState(() {
        _remaining = rem.isNegative ? Duration.zero : rem;
      });
      if (_remaining == Duration.zero) {
        _timer?.cancel();
        _autoSubmit();
      }
    });
  }

  void _autoSubmit() {
    if (mounted) {
      context.go(AppRoutes.submitConfirmation
          .replaceAll(':examId', widget.examId ?? ''));
    }
  }

  Future<void> _selectOption(String optionId) async {
    final ExamSession session = ref.read(examSessionProvider);
    final questionId = session.questions[_currentQuestion].id;
    final container = ref.read(serviceContainerProvider);

    final existing = session.answersById[questionId];
    final updated = ExamAnswer(
      examId: session.examId,
      questionId: questionId,
      selectedOptionId: optionId,
      isBookmarked: existing?.isBookmarked ?? false,
      timeSpent: existing?.timeSpent,
      updatedAt: DateTime.now(),
    );
    await container.examEngine.selectAnswer(
        session.examId, questionId, optionId);
    ref.read(examSessionProvider.notifier).upsertAnswer(questionId, updated);
    setState(() {});
  }

  Future<void> _toggleBookmark() async {
    final ExamSession session = ref.read(examSessionProvider);
    final questionId = session.questions[_currentQuestion].id;
    final container = ref.read(serviceContainerProvider);
    final existing = session.answersById[questionId];
    final updated = ExamAnswer(
      examId: session.examId,
      questionId: questionId,
      selectedOptionId: existing?.selectedOptionId,
      isBookmarked: !(existing?.isBookmarked ?? false),
      timeSpent: existing?.timeSpent,
      updatedAt: DateTime.now(),
    );
    await container.examEngine.toggleBookmark(session.examId, questionId);
    ref.read(examSessionProvider.notifier).upsertAnswer(questionId, updated);
    setState(() {});
  }

  void _next() {
    final ExamSession session = ref.read(examSessionProvider);
    if (_currentQuestion < session.questions.length - 1) {
      setState(() => _currentQuestion++);
    } else {
      // Reached the last question — go to submit confirmation.
      context.go(AppRoutes.submitConfirmation
          .replaceAll(':examId', widget.examId ?? ''));
    }
  }

  void _prev() {
    if (_currentQuestion > 0) {
      setState(() => _currentQuestion--);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timeString {
    final m = _remaining.inMinutes;
    final s = _remaining.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ExamSession session = ref.watch(examSessionProvider);

    if (!_initialized || session.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('آزمون')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final total = session.questions.length;
    final question = session.questions[_currentQuestion];
    final answer = session.answersById[question.id];
    final selectedOptionId = answer?.selectedOptionId;
    final isBookmarked = answer?.isBookmarked ?? false;
    final isTimeWarning = _remaining.inMinutes < 5;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('خروج از آزمون'),
              content: const Text(
                  'پاسخ‌های شما ذخیره می‌شود و می‌توانید بعدا ادامه دهید. آیا مطمئن هستید؟'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('ادامه آزمون')),
                TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('خروج')),
              ],
            ),
          );
          if (shouldExit == true && context.mounted) {
            // Pause the timer on exit (ExamEngine.pauseExam)
            final container = ref.read(serviceContainerProvider);
            await container.examEngine.pauseExam(session.examId);
            if (context.mounted) context.go(AppRoutes.home);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              final shouldExit = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('خروج از آزمون'),
                  content: const Text(
                      'پاسخ‌های شما ذخیره می‌شود و می‌توانید بعدا ادامه دهید.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('ادامه آزمون')),
                    TextButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('خروج')),
                  ],
                ),
              );
              if (shouldExit == true && context.mounted) {
                final container = ref.read(serviceContainerProvider);
                await container.examEngine.pauseExam(session.examId);
                if (context.mounted) context.go(AppRoutes.home);
              }
            },
          ),
          title: Text('سؤال ${_currentQuestion + 1} از $total'),
          centerTitle: true,
          actions: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: isTimeWarning
                    ? Colors.red.shade100
                    : Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer,
                      color: isTimeWarning
                          ? Colors.red
                          : Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    _timeString,
                    style: TextStyle(
                      color: isTimeWarning
                          ? Colors.red
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: isBookmarked ? Colors.amber : null,
              ),
              onPressed: _toggleBookmark,
            ),
            IconButton(
              icon: const Icon(Icons.grid_view),
              onPressed: () => context.push(AppRoutes.questionNavigator
                  .replaceAll(':examId', widget.examId ?? '')),
            ),
          ],
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
                value: (_currentQuestion + 1) / total, minHeight: 4),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'سؤال ${_currentQuestion + 1}:',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              question.body.isEmpty
                                  ? '(بدنه خالی)'
                                  : question.body,
                              style: const TextStyle(
                                  fontSize: 17, height: 1.9),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    for (var i = 0; i < question.options.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => _selectOption(question.options[i].id),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: selectedOptionId ==
                                      question.options[i].id
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedOptionId ==
                                        question.options[i].id
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                                width: selectedOptionId ==
                                        question.options[i].id
                                    ? 2
                                    : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: selectedOptionId ==
                                          question.options[i].id
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                  foregroundColor: selectedOptionId ==
                                          question.options[i].id
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.onSurface,
                                  child: Text(question.options[i].label),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    question.options[i].text,
                                    style: const TextStyle(fontSize: 15),
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
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_currentQuestion > 0)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _prev,
                          icon: const Icon(Icons.chevron_right),
                          label: const Text('قبلی'),
                        ),
                      )
                    else
                      const Spacer(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _next,
                        icon: const Icon(Icons.chevron_left),
                        label: Text(_currentQuestion == total - 1
                            ? 'تحویل'
                            : 'بعدی'),
                      ),
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

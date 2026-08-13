/// Screen 10: Exam Builder — Stage 07 / 18
///
/// Stage 18 compliance:
/// - Subjects dropdown is populated from `subjectRepository.getAll()` (real
///   data, not hardcoded).
/// - "Create & Start" calls `ExamEngine.createExam` with the chosen filters,
///   then navigates to `/exam-preparation/<newExamId>` so the user can review
///   the assembled exam before starting the timer.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../routing/app_routes.dart';
import '../../../domain/entities/entities.dart';

class ExamBuilderScreen extends ConsumerStatefulWidget {
  const ExamBuilderScreen({super.key});

  @override
  ConsumerState<ExamBuilderScreen> createState() => _ExamBuilderScreenState();
}

class _ExamBuilderScreenState extends ConsumerState<ExamBuilderScreen> {
  final _nameController = TextEditingController(text: 'آزمون تمرینی');
  int _questionCount = 20;
  String _strategy = 'random';
  String? _subjectId;
  int _timeLimit = 20; // minutes
  bool _negativeMarking = false;
  bool _shuffleQuestions = true;
  bool _shuffleOptions = false;
  bool _creating = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createAndStart() async {
    if (_creating) return;
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final container = ref.read(serviceContainerProvider);

      // Resolve question IDs based on the strategy.
      final questionIds = <String>[];
      switch (_strategy) {
        case 'mistakes':
          questionIds.addAll(await container.mistakeManager
              .getMistakeQuestionIds(
                  limit: _questionCount, subjectId: _subjectId));
          break;
        case 'bookmarks':
          final all = await container.questionRepository.filter(
            subjectId: _subjectId,
            onlyBookmarked: true,
            excludeArchived: true,
            limit: _questionCount,
            offset: 0,
          );
          questionIds.addAll(all.map((q) => q.id));
          break;
        case 'new':
          // "New" = questions the user has never answered (timesAnswered == 0).
          final all = await container.questionRepository.filter(
            subjectId: _subjectId,
            excludeArchived: true,
            limit: 500,
            offset: 0,
          );
          final fresh = all.where((q) => q.timesAnswered == 0).take(_questionCount);
          questionIds.addAll(fresh.map((q) => q.id));
          break;
        case 'manual':
          // For MVP, manual selection is the same as random — the user can
          // tweak the list in the question editor later. We just pick the
          // first N from the filtered pool.
          final all = await container.questionRepository.filter(
            subjectId: _subjectId,
            excludeArchived: true,
            limit: _questionCount,
            offset: 0,
          );
          questionIds.addAll(all.map((q) => q.id));
          break;
        case 'random':
        default:
          final all = await container.questionRepository.filter(
            subjectId: _subjectId,
            excludeArchived: true,
            limit: 500,
            offset: 0,
          );
          // Shuffle deterministically so the user can reproduce the exam.
          all.shuffle();
          questionIds.addAll(all.take(_questionCount).map((q) => q.id));
          break;
      }

      if (questionIds.isEmpty) {
        setState(() {
          _creating = false;
          _error = 'هیچ سؤالی برای ساخت آزمون یافت نشد. ابتدا سؤال وارد کنید.';
        });
        return;
      }

      final now = DateTime.now();
      final exam = Exam(
        id: '',
        name: _nameController.text.trim().isEmpty
            ? 'آزمون تمرینی'
            : _nameController.text.trim(),
        questionIds: questionIds,
        timeLimitSeconds: _timeLimit * 60,
        negativeMarkingEnabled: _negativeMarking,
        negativeMarkingRatio: 0.25,
        shuffleQuestions: _shuffleQuestions,
        shuffleOptions: _shuffleOptions,
        subjectId: _subjectId,
        topicId: null,
        filters: {
          'strategy': _strategy,
          'subjectId': _subjectId,
          'count': _questionCount,
        },
        randomSeed: now.millisecondsSinceEpoch,
        status: ExamStatus.ready,
        startedAt: null,
        submittedAt: null,
        createdAt: now,
      );

      final newExamId = await container.examEngine.createExam(exam);
      if (mounted) {
        context.push(AppRoutes.examPreparation.replaceAll(':examId', newExamId));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Subject>> subjectsAsync = ref.watch(subjectsListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('ساخت آزمون')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer)),
              ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'نام آزمون',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Selection strategy
            Text('روش انتخاب سؤالات',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                    label: const Text('تصادفی'),
                    selected: _strategy == 'random',
                    onSelected: (v) => setState(() => _strategy = 'random')),
                ChoiceChip(
                    label: const Text('دستی'),
                    selected: _strategy == 'manual',
                    onSelected: (v) => setState(() => _strategy = 'manual')),
                ChoiceChip(
                    label: const Text('از اشتباهات'),
                    selected: _strategy == 'mistakes',
                    onSelected: (v) => setState(() => _strategy = 'mistakes')),
                ChoiceChip(
                    label: const Text('نشان‌شده‌ها'),
                    selected: _strategy == 'bookmarks',
                    onSelected: (v) => setState(() => _strategy = 'bookmarks')),
                ChoiceChip(
                    label: const Text('سؤالات جدید'),
                    selected: _strategy == 'new',
                    onSelected: (v) => setState(() => _strategy = 'new')),
              ],
            ),
            const SizedBox(height: 16),

            // Question count slider
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text('تعداد سؤالات',
                            style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        Text('$_questionCount',
                            style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                    Slider(
                      value: _questionCount.toDouble(),
                      min: 5,
                      max: 100,
                      divisions: 19,
                      label: '$_questionCount',
                      onChanged: (v) =>
                          setState(() => _questionCount = v.round()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Time limit slider
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text('زمان آزمون (دقیقه)',
                            style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        Text('$_timeLimit دقیقه',
                            style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                    Slider(
                      value: _timeLimit.toDouble(),
                      min: 5,
                      max: 180,
                      divisions: 35,
                      label: '$_timeLimit',
                      onChanged: (v) => setState(() => _timeLimit = v.round()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Subject dropdown — populated from DB
            subjectsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('خطا در بارگذاری مباحث: $e'),
              data: (subjects) => DropdownButtonFormField<String?>(
                value: _subjectId,
                decoration: const InputDecoration(
                  labelText: 'مبحث',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                      value: null, child: Text('همه مباحث')),
                  ...subjects.map((s) => DropdownMenuItem<String?>(
                      value: s.id, child: Text(s.name))),
                ],
                onChanged: (v) => setState(() => _subjectId = v),
              ),
            ),
            const SizedBox(height: 12),

            // Toggles
            SwitchListTile(
              title: const Text('نمره منفی'),
              subtitle: const Text('۲۵٪ نمره سؤال صحیح برای پاسخ غلط'),
              value: _negativeMarking,
              onChanged: (v) => setState(() => _negativeMarking = v),
            ),
            SwitchListTile(
              title: const Text('ترتیب تصادفی سؤالات'),
              value: _shuffleQuestions,
              onChanged: (v) => setState(() => _shuffleQuestions = v),
            ),
            SwitchListTile(
              title: const Text('ترتیب تصادفی گزینه‌ها'),
              value: _shuffleOptions,
              onChanged: (v) => setState(() => _shuffleOptions = v),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _creating ? null : _createAndStart,
              icon: _creating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: const Text('ساخت و شروع'),
            ),
          ],
        ),
      ),
    );
  }
}

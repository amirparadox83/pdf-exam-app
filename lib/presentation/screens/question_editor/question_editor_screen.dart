/// Screen 7: Question Editor — Stage 07 / 17
///
/// Reads an existing `Question` by ID from the repository (or opens a fresh
/// blank editor when `questionId` is null / 'new'). Edits the body, options,
/// correct-option flag, difficulty, tags, and notes through controllers, and
/// persists the result via `QuestionRepository.insert` / `update` on save.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import '../../../domain/entities/entities.dart';

class QuestionEditorScreen extends ConsumerStatefulWidget {
  final String? questionId;

  const QuestionEditorScreen({super.key, this.questionId});

  @override
  ConsumerState<QuestionEditorScreen> createState() =>
      _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends ConsumerState<QuestionEditorScreen> {
  final _bodyController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagsController = TextEditingController();
  final _optionControllers = <TextEditingController>[];
  final _optionLabels = <String>['الف', 'ب', 'ج', 'د'];
  int _correctOptionIndex = 0;
  Difficulty _difficulty = Difficulty.medium;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Question? _existing;
  List<String> _existingTagIds = const [];

  @override
  void initState() {
    super.initState();
    // Seed four option controllers regardless of how many the question has,
    // so the UI is always four options wide.
    for (var i = 0; i < 4; i++) {
      _optionControllers.add(TextEditingController());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuestion());
  }

  Future<void> _loadQuestion() async {
    final id = widget.questionId;
    if (id == null || id.isEmpty || id == 'new') {
      setState(() => _loading = false);
      return;
    }
    try {
      final container = ref.read(serviceContainerProvider);
      final q = await container.questionRepository.getById(id);
      if (q != null) {
        _existing = q;
        _bodyController.text = q.body;
        _notesController.text = q.notes ?? '';
        _difficulty = q.difficulty;
        _existingTagIds = q.tagIds;
        // Pre-fill option texts
        for (var i = 0; i < 4; i++) {
          if (i < q.options.length) {
            _optionControllers[i].text = q.options[i].text;
            if (q.correctOptionId != null &&
                q.options[i].id == q.correctOptionId) {
              _correctOptionIndex = i;
            }
          }
        }
        // Pre-fill tags by fetching names
        if (q.tagIds.isNotEmpty) {
          final allTags = await container.tagRepository.getAll();
          final names = allTags
              .where((t) => q.tagIds.contains(t.id))
              .map((t) => t.name)
              .join('، ');
          _tagsController.text = names;
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final container = ref.read(serviceContainerProvider);
      final now = DateTime.now();
      final body = _bodyController.text.trim();
      if (body.isEmpty) {
        setState(() {
          _saving = false;
          _error = 'متن سؤال نمی‌تواند خالی باشد';
        });
        return;
      }

      // Build options — assign stable IDs upfront so correctOptionId can be set.
      final options = <QuestionOption>[];
      for (var i = 0; i < 4; i++) {
        final text = _optionControllers[i].text.trim();
        // Allow empty option text — user might not have filled all four.
        options.add(QuestionOption(
          id: _existing != null && i < _existing!.options.length
              ? _existing!.options[i].id
              : '',
          label: _optionLabels[i],
          text: text,
          order: i,
          region: null,
        ));
      }

      // Resolve tags (split by comma, fetch existing or create new)
      final tagIds = <String>[];
      final tagNames = _tagsController.text
          .split('،')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      if (tagNames.isNotEmpty) {
        final allTags = await container.tagRepository.getAll();
        for (final name in tagNames) {
          final match = allTags.where((t) => t.name == name).firstOrNull;
          if (match != null) {
            tagIds.add(match.id);
          } else {
            final id = await container.tagRepository.insert(Tag(
              id: '',
              name: name,
              createdAt: now,
            ));
            tagIds.add(id);
          }
        }
      }

      final question = Question(
        id: _existing?.id ?? '',
        pdfId: _existing?.pdfId ?? '',
        sourcePageNumber: _existing?.sourcePageNumber,
        body: body,
        options: options,
        correctOptionId: options[_correctOptionIndex].id.isEmpty
            ? null
            : options[_correctOptionIndex].id,
        subjectId: _existing?.subjectId,
        topicId: _existing?.topicId,
        tagIds: tagIds,
        difficulty: _difficulty,
        status: _existing?.status ?? QuestionStatus.valid,
        warnings: _existing?.warnings ?? const [],
        region: _existing?.region,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        isBookmarked: _existing?.isBookmarked ?? false,
        isArchived: _existing?.isArchived ?? false,
        timesAnswered: _existing?.timesAnswered ?? 0,
        timesCorrect: _existing?.timesCorrect ?? 0,
        timesIncorrect: _existing?.timesIncorrect ?? 0,
        lastAnsweredAt: _existing?.lastAnsweredAt,
        createdAt: _existing?.createdAt ?? now,
        updatedAt: now,
      );

      String newId;
      if (_existing == null) {
        newId = await container.questionRepository.insert(question);
        // Re-fetch so option IDs are populated, then set correctOptionId.
        final fresh = await container.questionRepository.getById(newId);
        if (fresh != null && fresh.options.length > _correctOptionIndex) {
          await container.questionRepository.update(
            fresh.copyWith(
              correctOptionId: fresh.options[_correctOptionIndex].id,
            ),
          );
        }
      } else {
        // Update existing — option IDs are already known.
        await container.questionRepository.update(question);
        // If the correct option had no ID yet, re-fetch & update.
        if (question.correctOptionId == null ||
            question.correctOptionId!.isEmpty) {
          final fresh = await container.questionRepository.getById(question.id);
          if (fresh != null && fresh.options.length > _correctOptionIndex) {
            await container.questionRepository.update(
              fresh.copyWith(
                correctOptionId: fresh.options[_correctOptionIndex].id,
              ),
            );
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('سؤال ذخیره شد')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'سؤال جدید' : 'ویرایش سؤال'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('ذخیره'),
          ),
        ],
      ),
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
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'متن کامل سؤال',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              maxLines: 6,
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < 4; i++) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('گزینه ${_optionLabels[i]}',
                              style: Theme.of(context).textTheme.titleMedium),
                          const Spacer(),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('پاسخ صحیح'),
                            value: _correctOptionIndex == i,
                            onChanged: (v) {
                              if (v) {
                                setState(() => _correctOptionIndex = i);
                              }
                            },
                          ),
                        ],
                      ),
                      TextField(
                        controller: _optionControllers[i],
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'متن گزینه',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<Difficulty>(
              value: _difficulty,
              decoration: const InputDecoration(
                labelText: 'سختی',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: Difficulty.easy, child: Text('آسان')),
                DropdownMenuItem(
                    value: Difficulty.medium, child: Text('متوسط')),
                DropdownMenuItem(
                    value: Difficulty.hard, child: Text('سخت')),
                DropdownMenuItem(
                    value: Difficulty.unknown, child: Text('نامشخص')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _difficulty = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'تگ‌ها (با «،» جدا کنید)',
                hintText: 'مثلاً: کنکور، تجربی، شیمی',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'یادداشت',
                hintText: 'یادداشت شخصی...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

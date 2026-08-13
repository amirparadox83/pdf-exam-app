/// Screen 9: Question Detail — Stage 07 / 17
///
/// Reads the Question by ID from the repository and displays the real body,
/// options, source PDF info, statistics (timesAnswered/correct/incorrect),
/// and notes. Supports toggling bookmark, jumping to the editor, archiving,
/// and deleting.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../routing/app_routes.dart';
import '../../../domain/entities/entities.dart';

class QuestionDetailScreen extends ConsumerStatefulWidget {
  final String? questionId;

  const QuestionDetailScreen({super.key, this.questionId});

  @override
  ConsumerState<QuestionDetailScreen> createState() =>
      _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends ConsumerState<QuestionDetailScreen> {
  bool _loading = true;
  Question? _question;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final id = widget.questionId;
    if (id == null || id.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'شناسه سؤال نامعتبر است';
      });
      return;
    }
    try {
      final container = ref.read(serviceContainerProvider);
      final q = await container.questionRepository.getById(id);
      _question = q;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleBookmark() async {
    if (_question == null) return;
    final container = ref.read(serviceContainerProvider);
    await container.questionRepository.toggleBookmark(_question!.id);
    await _load();
  }

  Future<void> _archive() async {
    if (_question == null) return;
    final container = ref.read(serviceContainerProvider);
    await container.questionRepository.archive(_question!.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سؤال بایگانی شد')),
      );
      context.go(AppRoutes.questionBank);
    }
  }

  Future<void> _delete() async {
    if (_question == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('حذف سؤال'),
        content: const Text('آیا از حذف این سؤال مطمئن هستید؟ این عمل قابل بازگشت نیست.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('انصراف')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;
    final container = ref.read(serviceContainerProvider);
    await container.questionRepository.delete(_question!.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سؤال حذف شد')),
      );
      context.go(AppRoutes.questionBank);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('سؤال')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _question == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('سؤال')),
        body: Center(child: Text(_error ?? 'سؤال یافت نشد')),
      );
    }
    final q = _question!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('سؤال ${q.id.substring(0, 8)}…'),
          actions: [
            IconButton(
              icon: Icon(
                q.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: q.isBookmarked ? Colors.amber : null,
              ),
              onPressed: _toggleBookmark,
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push(
                  AppRoutes.questionEditor.replaceAll(':questionId', q.id)),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'archive') _archive();
                if (v == 'delete') _delete();
              },
              itemBuilder: (c) => [
                const PopupMenuItem(value: 'archive', child: Text('بایگانی')),
                const PopupMenuItem(value: 'delete', child: Text('حذف')),
              ],
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'سؤال'),
              Tab(text: 'آمار'),
              Tab(text: 'یادداشت‌ها'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Question tab — real body + options
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('متن سؤال',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                            q.body.isEmpty ? '(بدنه خالی)' : q.body,
                            style: const TextStyle(fontSize: 16, height: 1.8),
                          ),
                          if (q.warnings.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: q.warnings
                                  .map((w) => Chip(
                                        label: Text(w),
                                        backgroundColor:
                                            Colors.orange.shade50,
                                      ))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final opt in q.options)
                    Card(
                      color: opt.id == q.correctOptionId
                          ? Colors.green.shade50
                          : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              opt.id == q.correctOptionId
                                  ? Colors.green
                                  : Colors.grey.shade300,
                          foregroundColor:
                              opt.id == q.correctOptionId
                                  ? Colors.white
                                  : Colors.black,
                          child: Text(opt.label),
                        ),
                        title: Text(opt.text.isEmpty
                            ? '(متن خالی)'
                            : opt.text),
                        trailing: opt.id == q.correctOptionId
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                      ),
                    ),
                  if (q.pdfId.isNotEmpty) ...[
                    const SizedBox(height: 16),
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
                                Text('منبع',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('PDF: ${q.pdfId}'),
                            if (q.sourcePageNumber != null)
                              Text('صفحه ${q.sourcePageNumber}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Stats tab — real counts
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('آمار پاسخ',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                              value: '${q.timesAnswered}',
                              label: 'کل',
                              color: Colors.blue),
                          _StatItem(
                              value: '${q.timesCorrect}',
                              label: 'صحیح',
                              color: Colors.green),
                          _StatItem(
                              value: '${q.timesIncorrect}',
                              label: 'غلط',
                              color: Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Notes tab — read from DB lazily
            _NotesTab(questionId: q.id),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _NotesTab extends ConsumerStatefulWidget {
  final String questionId;
  const _NotesTab({required this.questionId});

  @override
  ConsumerState<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends ConsumerState<_NotesTab> {
  final _controller = TextEditingController();
  List<Note> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final container = ref.read(serviceContainerProvider);
      _notes = await container.noteRepository.getByQuestion(widget.questionId);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final container = ref.read(serviceContainerProvider);
    final now = DateTime.now();
    await container.noteRepository.insert(Note(
      id: '',
      questionId: widget.questionId,
      content: text,
      createdAt: now,
      updatedAt: now,
    ));
    _controller.clear();
    await _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'یادداشت جدید...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: _add,
              ),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _notes.isEmpty
                ? const Center(child: Text('یادداشت‌ای وجود ندارد'))
                : ListView.builder(
                    itemCount: _notes.length,
                    itemBuilder: (context, i) {
                      final n = _notes[i];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.note)),
                          title: Text(n.content),
                          subtitle: Text(
                              '${n.updatedAt.year}/${n.updatedAt.month}/${n.updatedAt.day}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final container =
                                  ref.read(serviceContainerProvider);
                              await container.noteRepository.delete(n.id);
                              await _load();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

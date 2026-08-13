/// Screen 3: Import PDF — Stage 07
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import '../../routing/app_routes.dart';

class ImportPdfScreen extends ConsumerStatefulWidget {
  const ImportPdfScreen({super.key});

  @override
  ConsumerState<ImportPdfScreen> createState() => _ImportPdfScreenState();
}

class _ImportPdfScreenState extends ConsumerState<ImportPdfScreen> {
  String? _pdfPath;
  String? _pdfName;
  String? _answerKeyPath;
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  bool _includeAnswerKey = false;
  bool _picking = false;

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pdfPath = result.files.first.path;
          _pdfName = result.files.first.name;
          if (_titleController.text.isEmpty) {
            _titleController.text = _pdfName!.replaceAll('.pdf', '');
          }
        });
      }
    } finally {
      setState(() => _picking = false);
    }
  }

  Future<void> _pickAnswerKey() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _answerKeyPath = result.files.first.path;
        _includeAnswerKey = true;
      });
    }
  }

  void _startProcessing() {
    if (_pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً ابتدا فایل PDF را انتخاب کنید')),
      );
      return;
    }
    context.push(AppRoutes.processing, extra: {
      'pdfPath': _pdfPath,
      'pdfName': _pdfName,
      'answerKeyPath': _answerKeyPath,
      'title': _titleController.text,
      'subject': _subjectController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('وارد کردن PDF')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // PDF picker
            Card(
              child: InkWell(
                onTap: _picking ? null : _pickPdf,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        _pdfPath != null ? Icons.check_circle : Icons.upload_file,
                        size: 64,
                        color: _pdfPath != null
                            ? Colors.green
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _pdfName ?? 'انتخاب فایل PDF',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      if (_pdfPath == null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'فایل آزمون چهارگزینه‌ای را انتخاب کنید',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (_picking) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'عنوان',
                hintText: 'مثلاً: آزمون شیمی ۱۴۰۲',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 12),

            // Subject
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'مبحث (اختیاری)',
                hintText: 'مثلاً: شیمی',
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 20),

            // Answer key toggle
            SwitchListTile(
              title: const Text('شامل کلید پاسخ'),
              subtitle: const Text('فایل جداگانه با پاسخ‌های صحیح'),
              value: _includeAnswerKey,
              onChanged: (v) {
                setState(() => _includeAnswerKey = v);
                if (v && _answerKeyPath == null) {
                  _pickAnswerKey();
                }
              },
            ),
            if (_includeAnswerKey && _answerKeyPath != null)
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 4),
                child: Text(
                  'فایل کلید پاسخ: ${_answerKeyPath!.split('/').last}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (_includeAnswerKey && _answerKeyPath != null)
              TextButton.icon(
                onPressed: _pickAnswerKey,
                icon: const Icon(Icons.refresh),
                label: const Text('تغییر فایل کلید پاسخ'),
              ),
            const SizedBox(height: 24),

            // Start
            FilledButton.icon(
              onPressed: _pdfPath == null ? null : _startProcessing,
              icon: const Icon(Icons.play_arrow),
              label: const Text('شروع پردازش'),
            ),
            const SizedBox(height: 8),
            Text(
              'پردازش به‌صورت محلی انجام می‌شود و فایل شما آپلود نمی‌شود.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

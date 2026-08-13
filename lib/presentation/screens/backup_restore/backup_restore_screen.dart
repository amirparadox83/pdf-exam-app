/// Screen 20: Backup/Restore — Stage 07 / 25
///
/// Stage 25 compliance: NO mock data. Reads real `BackupMetadata` rows from
/// `backupListProvider` and triggers real backup creation via
/// `backupCreateProvider` (which calls `BackupService`).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../providers/app_providers.dart';
import '../../../domain/entities/entities.dart';

class BackupRestoreScreen extends ConsumerWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BackupCreateState createState = ref.watch(backupCreateProvider);
    final AsyncValue<List<BackupMetadata>> backupsAsync = ref.watch(backupListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('پشتیبان و بازیابی')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Create backup
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.backup, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text('ساخت پشتیبان', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('شامل فایل‌های PDF'),
                      subtitle: const Text('حجم پشتیبان بیشتر می‌شود'),
                      value: createState.includePdfs,
                      onChanged: createState.isCreating
                          ? null
                          : (v) => ref.read(backupCreateProvider.notifier).setIncludePdfs(v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('رمزگذاری'),
                      subtitle: const Text('نیاز به رمز عبور هنگام بازیابی'),
                      value: createState.encrypt,
                      onChanged: createState.isCreating
                          ? null
                          : (v) => ref.read(backupCreateProvider.notifier).setEncrypt(v),
                    ),
                    if (createState.isCreating) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: createState.progress),
                      const SizedBox(height: 4),
                      Text('${(createState.progress * 100).toInt()}٪', textAlign: TextAlign.center),
                    ],
                    if (createState.error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        createState.error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: createState.isCreating
                          ? null
                          : () => ref.read(backupCreateProvider.notifier).create(),
                      icon: const Icon(Icons.save),
                      label: const Text('ساخت پشتیبان'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Restore
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.restore, color: Colors.green),
                        const SizedBox(width: 8),
                        Text('بازیابی', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _restoreBackup(context, ref),
                      icon: const Icon(Icons.file_upload),
                      label: const Text('انتخاب فایل پشتیبان'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // History
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('پشتیبان‌های اخیر', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    backupsAsync.when(
                      loading: () => const SizedBox(
                        height: 60,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text('خطا: $e'),
                      data: (backups) => backups.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'هنوز پشتیبانی ساخته نشده',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : Column(
                              children: backups.map((b) {
                                return ListTile(
                                  leading: const CircleAvatar(child: Icon(Icons.history)),
                                  title: Text(_formatDate(b.createdAt)),
                                  subtitle: Text(
                                    '${b.questionCount} سؤال • ${_formatSize(b.fileSizeBytes)}'
                                    '${b.includePdfs ? ' • شامل PDF' : ''}',
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (v) {
                                      if (v == 'delete') {
                                        _deleteBackup(context, ref, b.id, b.filePath);
                                      }
                                    },
                                    itemBuilder: (c) => const [
                                      PopupMenuItem(value: 'restore', child: Text('بازیابی')),
                                      PopupMenuItem(value: 'share', child: Text('اشتراک‌گذاری')),
                                      PopupMenuItem(value: 'delete', child: Text('حذف')),
                                    ],
                                  ),
                                );
                              }).toList(),
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

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pexam'],
    );
    if (result == null || result.files.isEmpty) return;

    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('بازیابی پشتیبان'),
        content: const Text(
          'بازیابی، داده‌های فعلی را با داده‌های پشتیبان جایگزین می‌کند. آیا ادامه می‌دهید؟',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('بازیابی')),
        ],
      ),
    );
    if (shouldRestore != true) return;

    final backupService = ref.read(serviceContainerProvider).backupService;
    try {
      final restoreResult = await backupService.restore(
        backupFilePath: result.files.first.path!,
        overwriteExisting: true,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            restoreResult.success
                ? 'بازیابی انجام شد — ${restoreResult.questionsRestored} سؤال'
                : 'خطا در بازیابی: ${restoreResult.error ?? "نامشخص"}',
          )),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e')),
        );
      }
    }
  }

  Future<void> _deleteBackup(
    BuildContext context,
    WidgetRef ref,
    String id,
    String filePath,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('حذف پشتیبان'),
        content: const Text('این پشتیبان حذف شود؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(backupRepositoryProvider).delete(id);
    ref.invalidate(backupListProvider);
  }

  String _formatDate(DateTime d) {
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes بایت';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} کیلوبایت';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} مگابایت';
  }
}

/// Screen 21: Settings — Stage 07 / 26
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double _fontSizeScale = 1.0;
  bool _negativeMarking = false;
  int _defaultTime = 60;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(
        children: [
          // Appearance
          _SectionHeader(title: 'ظاهر'),
          RadioListTile<ThemeMode>(
            value: ThemeMode.system,
            groupValue: themeMode,
            title: const Text('پیش‌فرض سیستم'),
            onChanged: (v) => ref.read(themeModeProvider.notifier).state = v!,
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.light,
            groupValue: themeMode,
            title: const Text('روشن'),
            onChanged: (v) => ref.read(themeModeProvider.notifier).state = v!,
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.dark,
            groupValue: themeMode,
            title: const Text('تیره'),
            onChanged: (v) => ref.read(themeModeProvider.notifier).state = v!,
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('اندازه فونت'),
            subtitle: Slider(
              value: _fontSizeScale,
              min: 0.8, max: 1.4, divisions: 6,
              label: '${(_fontSizeScale * 100).toInt()}٪',
              onChanged: (v) => setState(() => _fontSizeScale = v),
            ),
            trailing: Text('${(_fontSizeScale * 100).toInt()}٪'),
          ),
          const Divider(),

          // Exam defaults
          _SectionHeader(title: 'پیش‌فرض‌های آزمون'),
          SwitchListTile(
            secondary: const Icon(Icons.remove_circle_outline),
            title: const Text('نمره منفی پیش‌فرض'),
            value: _negativeMarking,
            onChanged: (v) => setState(() => _negativeMarking = v),
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('زمان پیش‌فرض هر سؤال'),
            subtitle: Text('$_defaultTime ثانیه'),
            trailing: SizedBox(
              width: 100,
              child: Slider(
                value: _defaultTime.toDouble(),
                min: 30, max: 180, divisions: 10,
                onChanged: (v) => setState(() => _defaultTime = v.round()),
              ),
            ),
          ),
          const Divider(),

          // Storage
          _SectionHeader(title: 'حافظه'),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('حافظه استفاده‌شده'),
            subtitle: const Text('۱۲۰ مگابایت'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text('پاک‌سازی کش'),
            subtitle: const Text('۴۵ مگابایت قابل پاک‌سازی'),
            onTap: () => _showClearCacheDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('پشتیبان و بازیابی'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.pushNamed(context, '/backup'),
          ),
          const Divider(),

          // Privacy
          _SectionHeader(title: 'حریم خصوصی'),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('سیاست حریم خصوصی'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('حذف تمام داده‌ها', style: TextStyle(color: Colors.red)),
            subtitle: const Text('غیرقابل بازگشت'),
            onTap: () => _showDeleteAllDialog(context),
          ),
          const Divider(),

          // About
          _SectionHeader(title: 'درباره'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('نسخه'),
            subtitle: const Text('۱.۰.۰'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('مجوزهای متن‌باز'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('امتیاز به ما'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('پاک‌سازی کش'),
        content: const Text('آیا مطمئن هستید؟ این عمل فقط فایل‌های قابل بازسازی را حذف می‌کند.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('انصراف')),
          FilledButton(
            onPressed: () {
              Navigator.pop(c);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('کش پاک شد')),
              );
            },
            child: const Text('پاک‌سازی'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('حذف تمام داده‌ها'),
        content: const Text(
          'این عمل تمام سؤالات، آزمون‌ها، نتایج و تنظیمات را به‌طور دائمی حذف می‌کند. این عمل غیرقابل بازگشت است!',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('انصراف')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(c);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('در حال حذف...')),
              );
            },
            child: const Text('حذف کن'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

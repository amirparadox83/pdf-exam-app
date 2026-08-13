import 'package:flutter/material.dart';

/// A simple stat card widget for dashboards.
class StatCardData {
  final String title;
  final String value;
  final IconData? icon;
  final Color? color;

  const StatCardData({
    required this.title,
    required this.value,
    this.icon,
    this.color,
  });
}

class StatCard extends StatelessWidget {
  final StatCardData data;
  const StatCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (data.icon != null)
              Icon(data.icon, color: data.color ?? theme.primaryColor, size: 32),
            const SizedBox(height: 8),
            Text(data.value, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(data.title, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// A status badge widget for question/exam status display.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  const StatusBadge({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: color ?? Colors.grey, fontSize: 12)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatCard extends StatelessWidget {
  final String title;
  /// Any string; if it contains a number (e.g. "Rs 12000"), that number will be grouped.
  final String value;
  final IconData icon;
  final Color color;
  final ColorScheme colorScheme;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.colorScheme,
  });

  String _formatStatValue(String value) {
    final v = value.trim();
    final match = RegExp(r'-?\d[\d,]*(?:\.\d+)?').firstMatch(v);
    if (match == null) return v;

    final prefix = v.substring(0, match.start);
    final suffix = v.substring(match.end);
    final numberStr = match.group(0)!.replaceAll(',', '');

    final parsed = num.tryParse(numberStr);
    if (parsed == null) return v;

    final formattedNumber = NumberFormat.decimalPattern().format(parsed);
    return '$prefix$formattedNumber$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final formattedValue = _formatStatValue(value);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formattedValue,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

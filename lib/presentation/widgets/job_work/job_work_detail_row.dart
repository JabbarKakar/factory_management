import 'package:flutter/material.dart';

class JobWorkDetailRow extends StatelessWidget {
  const JobWorkDetailRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.highlight = false,
    super.key,
  });

  final String label;
  final String value;
  final bool bold;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final valueColor = highlight ? theme.colorScheme.primary : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: muted,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              height: 1.35,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

class JobWorkDetailRows extends StatelessWidget {
  const JobWorkDetailRows({required this.rows, super.key});

  final List<JobWorkDetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1) const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }
}

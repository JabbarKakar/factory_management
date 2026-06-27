import 'package:flutter/material.dart';

import '../../../domain/enums/quality_enums.dart';

class QcDispositionBadge extends StatelessWidget {
  const QcDispositionBadge({
    required this.disposition,
    super.key,
  });

  final QcDisposition disposition;

  Color _color() {
    return switch (disposition) {
      QcDisposition.pass => Colors.green,
      QcDisposition.rework => Colors.orange,
      QcDisposition.reject => Colors.red,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        disposition.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

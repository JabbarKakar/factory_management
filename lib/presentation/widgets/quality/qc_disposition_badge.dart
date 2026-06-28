import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/enums/quality_enums.dart';
import '../compact_status_chip.dart';

class QcDispositionBadge extends StatelessWidget {
  const QcDispositionBadge({
    required this.disposition,
    this.compact = false,
    super.key,
  });

  final QcDisposition disposition;
  final bool compact;

  Color get _color => switch (disposition) {
        QcDisposition.pass => AppColors.success,
        QcDisposition.rework => AppColors.warning,
        QcDisposition.reject => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return CompactStatusChip(
        label: disposition.label,
        color: _color,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        disposition.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
      ),
    );
  }
}

Color qcDispositionAccent(QcDisposition disposition) {
  return switch (disposition) {
    QcDisposition.pass => AppColors.success,
    QcDisposition.rework => AppColors.warning,
    QcDisposition.reject => AppColors.error,
  };
}

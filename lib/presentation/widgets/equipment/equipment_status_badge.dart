import 'package:flutter/material.dart';

import '../../../domain/enums/equipment_enums.dart';

class EquipmentStatusBadge extends StatelessWidget {
  const EquipmentStatusBadge({
    required this.status,
    super.key,
  });

  final EquipmentStatus status;

  Color _color() {
    return switch (status) {
      EquipmentStatus.running => Colors.green,
      EquipmentStatus.underMaintenance => Colors.orange,
      EquipmentStatus.broken => Colors.red,
      EquipmentStatus.retired => Colors.grey,
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
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

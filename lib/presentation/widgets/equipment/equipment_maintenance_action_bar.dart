import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../dashboard/dashboard_surface.dart';

class EquipmentMaintenanceActionBar extends StatelessWidget {
  const EquipmentMaintenanceActionBar({
    required this.onPressed,
    super.key,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: DashboardSurfaceCard(
        compact: true,
        borderRadius: 14,
        padding: const EdgeInsets.all(12),
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.build_circle_outlined, size: 16),
          label: Text(
            AppStrings.recordMaintenance,
            style: const TextStyle(fontSize: 12),
          ),
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );
  }
}

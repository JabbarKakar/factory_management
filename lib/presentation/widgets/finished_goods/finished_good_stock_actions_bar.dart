import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../dashboard/dashboard_surface.dart';

class FinishedGoodStockActionsBar extends StatelessWidget {
  const FinishedGoodStockActionsBar({
    required this.onAdjustIn,
    required this.onAdjustOut,
    super.key,
  });

  final VoidCallback onAdjustIn;
  final VoidCallback onAdjustOut;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: DashboardSurfaceCard(
        compact: true,
        borderRadius: 14,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onAdjustOut,
                icon: const Icon(Icons.remove_circle_outline, size: 16),
                label: Text(
                  AppStrings.adjustStockOut,
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: onAdjustIn,
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: Text(
                  AppStrings.adjustStockIn,
                  style: const TextStyle(fontSize: 12),
                ),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

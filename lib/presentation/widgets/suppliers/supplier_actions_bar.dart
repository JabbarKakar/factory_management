import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../dashboard/dashboard_surface.dart';

class SupplierActionsBar extends StatelessWidget {
  const SupplierActionsBar({
    required this.canRecordPurchase,
    required this.canStockIn,
    required this.onRecordPurchase,
    required this.onStockIn,
    super.key,
  });

  final bool canRecordPurchase;
  final bool canStockIn;
  final VoidCallback onRecordPurchase;
  final VoidCallback onStockIn;

  @override
  Widget build(BuildContext context) {
    if (!canRecordPurchase && !canStockIn) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: DashboardSurfaceCard(
        compact: true,
        borderRadius: 14,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (canRecordPurchase)
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRecordPurchase,
                  icon: const Icon(Icons.add_shopping_cart_outlined, size: 16),
                  label: Text(
                    AppStrings.recordPurchase,
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            if (canRecordPurchase && canStockIn) const SizedBox(width: 8),
            if (canStockIn)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onStockIn,
                  icon: const Icon(Icons.inventory_2_outlined, size: 16),
                  label: Text(
                    AppStrings.stockIn,
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
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

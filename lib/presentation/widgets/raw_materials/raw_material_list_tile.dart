import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/raw_material.dart';
import 'low_stock_badge.dart';

class RawMaterialListTile extends StatelessWidget {
  const RawMaterialListTile({
    required this.material,
    required this.onTap,
    super.key,
  });

  final RawMaterial material;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      material.materialType.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  if (material.isLowStock) const LowStockBadge(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                Formatters.stockQuantity(
                  material.currentStock,
                  material.unit.label,
                ),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${AppStrings.reorderLevel}: ${Formatters.stockQuantity(material.reorderLevel, material.unit.label)}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: muted,
                        ),
                  ),
                  const Spacer(),
                  if (material.hasStock)
                    Text(
                      Formatters.currencyPkr(material.stockValue),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

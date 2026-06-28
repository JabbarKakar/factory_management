import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/enums/supplier_enums.dart';
import '../compact_status_chip.dart';

Color supplierTypeAccent(SupplierType type) {
  return switch (type) {
    SupplierType.marbleBlockSlab => AppColors.primary,
    SupplierType.consumables => AppColors.warning,
    SupplierType.chemical => AppColors.error,
    SupplierType.machinery => AppColors.primary,
    SupplierType.spareParts => AppColors.textSecondary,
    SupplierType.transportLogistics => AppColors.warning,
    SupplierType.utility => AppColors.success,
    SupplierType.other => AppColors.textSecondary,
  };
}

class SupplierTypeChip extends StatelessWidget {
  const SupplierTypeChip({
    required this.supplierType,
    this.compact = false,
    super.key,
  });

  final SupplierType supplierType;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = supplierTypeAccent(supplierType);

    if (compact) {
      return CompactStatusChip(
        label: supplierType.label,
        color: color,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        supplierType.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
      ),
    );
  }
}

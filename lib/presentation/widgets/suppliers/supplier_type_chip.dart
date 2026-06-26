import 'package:flutter/material.dart';

import '../../../domain/enums/supplier_enums.dart';

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
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        supplierType.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

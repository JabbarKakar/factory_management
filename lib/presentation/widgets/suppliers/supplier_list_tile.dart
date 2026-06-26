import 'package:flutter/material.dart';

import '../../../domain/entities/supplier.dart';
import 'supplier_type_chip.dart';

class SupplierListTile extends StatelessWidget {
  const SupplierListTile({
    required this.supplier,
    required this.onTap,
    super.key,
  });

  final Supplier supplier;
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
              Text(
                supplier.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                supplier.phone,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: muted,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SupplierTypeChip(
                    supplierType: supplier.supplierType,
                    compact: true,
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.location_on_outlined, size: 14, color: muted),
                  const SizedBox(width: 2),
                  Text(
                    supplier.displayLocation,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: muted,
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

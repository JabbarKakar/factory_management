import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/supplier.dart';
import 'supplier_type_chip.dart';

class SupplierDetailHero extends StatelessWidget {
  const SupplierDetailHero({required this.supplier, super.key});

  final Supplier supplier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);
    final accent = supplierTypeAccent(supplier.supplierType);
    const cardShape = BorderRadius.only(
      topRight: Radius.circular(14),
      bottomRight: Radius.circular(14),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: cardShape,
          border: Border.all(color: outline),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              supplier.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                height: 1.2,
                              ),
                            ),
                          ),
                          SupplierTypeChip(supplierType: supplier.supplierType),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        supplier.supplierNumber,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              supplier.phone,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (supplier.displayLocation != '—') ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                supplier.displayLocation,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Divider(
                        height: 1,
                        color: outline.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppStrings.paymentTerms,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Text(
                            supplier.paymentTerms.label,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

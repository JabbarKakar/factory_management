import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/production_batch.dart';

class ProductionBatchListTile extends StatelessWidget {
  const ProductionBatchListTile({
    required this.batch,
    required this.onTap,
    super.key,
  });

  final ProductionBatch batch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        child: const Icon(Icons.precision_manufacturing_outlined),
      ),
      title: Text(batch.batchNumber),
      subtitle: Text(
        '${DateFormat.yMMMd().format(batch.productionDate)} · '
        '${batch.productType.label} · ${batch.marbleVariety}',
        style: TextStyle(color: muted),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Formatters.stockQuantity(batch.totalUsableSqFt, 'sq. ft'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            batch.shift.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: muted,
                ),
          ),
        ],
      ),
    );
  }
}

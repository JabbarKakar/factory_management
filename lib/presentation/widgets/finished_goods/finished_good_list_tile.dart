import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/finished_good.dart';
import '../../widgets/raw_materials/low_stock_badge.dart';

class FinishedGoodListTile extends StatelessWidget {
  const FinishedGoodListTile({
    required this.item,
    required this.onTap,
    super.key,
  });

  final FinishedGood item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        child: const Icon(Icons.layers_outlined),
      ),
      title: Text(item.productType.label),
      subtitle: Text(item.displaySubtitle, style: TextStyle(color: muted)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Formatters.stockQuantity(item.currentQuantity, 'sq. ft'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (item.isLowStock)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: LowStockBadge(),
            )
          else if (item.location != null && item.location!.isNotEmpty)
            Text(
              item.location!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: muted,
                  ),
            ),
        ],
      ),
    );
  }
}

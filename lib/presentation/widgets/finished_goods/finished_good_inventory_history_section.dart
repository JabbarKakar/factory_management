import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/inventory_transaction.dart';
import '../../../domain/enums/inventory_enums.dart';
import '../../../data/services/stock_correction_helper.dart';
import '../../routes/route_paths.dart';
import '../tile_options_menu.dart';
import '../job_work/job_work_detail_section.dart';

class FinishedGoodInventoryHistorySection extends StatelessWidget {
  const FinishedGoodInventoryHistorySection({
    required this.transactions,
    this.canCorrect = false,
    this.onCorrect,
    super.key,
  });

  final List<InventoryTransaction> transactions;
  final bool canCorrect;
  final ValueChanged<InventoryTransaction>? onCorrect;

  @override
  Widget build(BuildContext context) {
    return JobWorkDetailSection(
      title: AppStrings.inventoryHistory,
      icon: Icons.history_rounded,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: transactions.isEmpty
            ? Text(
                AppStrings.noInventoryHistory,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      height: 1.35,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            : Column(
                children: [
                  for (var i = 0; i < transactions.length; i++) ...[
                    _InventoryTransactionRow(
                      transaction: transactions[i],
                      canCorrect: canCorrect,
                      onCorrect: onCorrect,
                    ),
                    if (i < transactions.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
      ),
    );
  }
}

class _InventoryTransactionRow extends StatelessWidget {
  const _InventoryTransactionRow({
    required this.transaction,
    required this.canCorrect,
    this.onCorrect,
  });

  final InventoryTransaction transaction;
  final bool canCorrect;
  final ValueChanged<InventoryTransaction>? onCorrect;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final isOut =
        transaction.movementType == InventoryMovementType.adjustmentOut;
    final color = isOut ? AppColors.error : AppColors.success;
    final prefix = isOut ? '−' : '+';
    final dateLabel = DateFormat.yMMMd().format(transaction.transactionDate);

    final subtitleParts = <String>[
      transaction.transactionNumber,
      dateLabel,
      if (transaction.productionBatchNumber != null)
        transaction.productionBatchNumber!,
      if (transaction.reason != null && transaction.reason!.isNotEmpty)
        transaction.reason!,
    ];

    final icon = switch (transaction.movementType) {
      InventoryMovementType.productionIn =>
        Icons.precision_manufacturing_outlined,
      InventoryMovementType.adjustmentIn => Icons.add_circle_outline,
      InventoryMovementType.adjustmentOut => Icons.remove_circle_outline,
    };

    final onTap = transaction.productionBatchId != null
        ? () => context.push(
              RoutePaths.productionDetail(transaction.productionBatchId!),
            )
        : null;
    final showCorrect = canCorrect &&
        onCorrect != null &&
        StockCorrectionHelper.canCorrectInventoryTransaction(transaction);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.movementType.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleParts.join(' · '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: muted,
                            fontSize: 11,
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$prefix${Formatters.stockQuantity(transaction.quantity, 'sq. ft')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
              ),
              if (showCorrect)
                TileOptionsButton(
                  actions: [
                    TileMenuAction(
                      label: AppStrings.correctLedgerEntry,
                      icon: Icons.edit_outlined,
                      onSelected: () => onCorrect!(transaction),
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

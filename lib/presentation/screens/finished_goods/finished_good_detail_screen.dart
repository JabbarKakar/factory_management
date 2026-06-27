import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/finished_goods/finished_goods_detail_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/inventory_data.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/inventory_transaction.dart';
import '../../../domain/enums/inventory_enums.dart';
import '../../routes/route_paths.dart';
import '../../widgets/raw_materials/low_stock_badge.dart';
import '../../widgets/settings_section.dart';

class FinishedGoodDetailScreen extends StatelessWidget {
  const FinishedGoodDetailScreen({required this.finishedGoodId, super.key});

  final String finishedGoodId;

  Future<void> _editReorderLevel(BuildContext context, double current) async {
    final controller = TextEditingController(
      text: current > 0 ? current.toStringAsFixed(0) : '',
    );
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(AppStrings.setReorderLevel),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: AppStrings.reorderLevel,
              helperText: AppStrings.reorderLevelHint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(controller.text.trim()) ?? 0;
                Navigator.pop(dialogContext, value);
              },
              child: const Text(AppStrings.saveChanges),
            ),
          ],
        );
      },
    );

    if (!context.mounted || result == null) return;

    context.read<FinishedGoodsDetailBloc>().add(
          FinishedGoodsReorderLevelUpdated(result),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.reorderLevelUpdated)),
    );
  }

  Future<void> _editLocation(
    BuildContext context,
    String? currentLocation,
  ) async {
    String? selected = currentLocation;
    if (selected != null &&
        !InventoryData.storageLocations.contains(selected)) {
      selected = 'Other';
    }

    final customController = TextEditingController(
      text: selected == 'Other' ? (currentLocation ?? '') : '',
    );

    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(AppStrings.setStorageLocation),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String?>(
                    initialValue: selected,
                    decoration: const InputDecoration(
                      labelText: AppStrings.storageLocation,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text(AppStrings.notSpecified),
                      ),
                      ...InventoryData.storageLocations.map(
                        (location) => DropdownMenuItem(
                          value: location,
                          child: Text(location),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => selected = value),
                  ),
                  if (selected == 'Other') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: customController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.storageLocation,
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(AppStrings.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    if (selected == 'Other') {
                      Navigator.pop(
                        dialogContext,
                        customController.text.trim().isEmpty
                            ? null
                            : customController.text.trim(),
                      );
                    } else {
                      Navigator.pop(dialogContext, selected);
                    }
                  },
                  child: const Text(AppStrings.saveChanges),
                ),
              ],
            );
          },
        );
      },
    );

    if (!context.mounted) return;

    context.read<FinishedGoodsDetailBloc>().add(
          FinishedGoodsLocationUpdated(result),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.locationUpdated)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FinishedGoodsDetailBloc, FinishedGoodsDetailState>(
      listenWhen: (prev, curr) =>
          prev.errorMessage != curr.errorMessage && curr.errorMessage != null,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        if (state.status == FinishedGoodsDetailStatus.loading &&
            state.item == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.stockItemDetails)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final item = state.item;
        if (item == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.stockItemDetails)),
            body: Center(
              child: Text(
                state.errorMessage ?? AppStrings.stockItemNotFound,
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text(AppStrings.stockItemDetails)),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: 'fab-inventory-out',
                onPressed: () => context.push(
                  RoutePaths.finishedGoodAdjustOut(item.id),
                ),
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text(AppStrings.adjustStockOut),
              ),
              const SizedBox(height: 12),
              FloatingActionButton.extended(
                heroTag: 'fab-inventory-in',
                onPressed: () => context.push(
                  RoutePaths.finishedGoodAdjustIn(item.id),
                ),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text(AppStrings.adjustStockIn),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 140),
            children: [
              Card(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              Formatters.stockQuantity(
                                item.currentQuantity,
                                'sq. ft',
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (item.isLowStock) const LowStockBadge(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.currentQuantity,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.productType.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.displaySubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              SettingsSection(
                title: AppStrings.stockItemDetails,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SummaryRow(
                        label: AppStrings.reorderLevel,
                        value: Formatters.stockQuantity(
                          item.reorderLevel,
                          'sq. ft',
                        ),
                        trailing: IconButton(
                          onPressed: () =>
                              _editReorderLevel(context, item.reorderLevel),
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: AppStrings.setReorderLevel,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        label: AppStrings.storageLocation,
                        value: item.location ?? AppStrings.notSpecified,
                        trailing: IconButton(
                          onPressed: () =>
                              _editLocation(context, item.location),
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: AppStrings.setStorageLocation,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        label: AppStrings.averageCost,
                        value: item.averageCost > 0
                            ? '${Formatters.currencyPkr(item.averageCost)} / sq. ft'
                            : '—',
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        label: AppStrings.stockValue,
                        value: item.hasStock
                            ? Formatters.currencyPkr(item.stockValue)
                            : '—',
                      ),
                      if (item.lastReceiptDate != null) ...[
                        const SizedBox(height: 12),
                        _SummaryRow(
                          label: AppStrings.lastReceipt,
                          value:
                              DateFormat.yMMMd().format(item.lastReceiptDate!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SettingsSection(
                title: AppStrings.inventoryHistory,
                child: state.transactions.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          AppStrings.noInventoryHistory,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      )
                    : Column(
                        children: state.transactions
                            .map(
                              (transaction) => _TransactionTile(
                                transaction: transaction,
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: muted)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final InventoryTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isIn = transaction.movementType != InventoryMovementType.adjustmentOut;
    final color = isIn ? AppColors.success : AppColors.error;
    final prefix = isIn ? '+' : '−';
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    final subtitleParts = <String>[
      DateFormat.yMMMd().format(transaction.transactionDate),
      transaction.transactionNumber,
      if (transaction.productionBatchNumber != null)
        transaction.productionBatchNumber!,
      if (transaction.reason != null && transaction.reason!.isNotEmpty)
        transaction.reason!,
    ];

    return ListTile(
      leading: Icon(
        isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
        color: color,
      ),
      title: Text(transaction.movementType.label),
      subtitle: Text(
        subtitleParts.join(' · '),
        style: TextStyle(color: muted),
      ),
      trailing: Text(
        '$prefix${Formatters.stockQuantity(transaction.quantity, 'sq. ft')}',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
      onTap: transaction.productionBatchId != null
          ? () => context.push(
                RoutePaths.productionDetail(transaction.productionBatchId!),
              )
          : null,
    );
  }
}

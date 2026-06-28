import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/raw_material/raw_material_detail_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/supplier_repository.dart';
import '../../../domain/entities/stock_transaction.dart';
import '../../../domain/entities/supplier.dart';
import '../../../domain/enums/raw_material_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../widgets/dialogs/app_input_dialog.dart';
import '../../widgets/app_extended_fab.dart';
import '../../widgets/raw_materials/low_stock_badge.dart';
import '../../widgets/settings_section.dart';

class RawMaterialDetailScreen extends StatelessWidget {
  const RawMaterialDetailScreen({
    required this.materialTypeName,
    super.key,
  });

  final String materialTypeName;

  RawMaterialType get materialType =>
      RawMaterialType.fromString(materialTypeName);

  Future<void> _editReorderLevel(BuildContext context, double current) async {
    final result = await AppInputDialog.showNumber(
      context,
      title: AppStrings.setReorderLevel,
      fieldLabel: AppStrings.reorderLevel,
      helperText: AppStrings.reorderLevelHint,
      initialValue: current,
    );

    if (!context.mounted || result == null) return;

    context.read<RawMaterialDetailBloc>().add(
          RawMaterialReorderLevelUpdated(result),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.reorderLevelUpdated)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RawMaterialDetailBloc, RawMaterialDetailState>(
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
        if (state.status == RawMaterialDetailStatus.loading &&
            state.transactions.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.materialDetails)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final material = state.material;
        final factoryId = readFactoryId(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(material.materialType.label),
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppExtendedFab(
                heroTag: 'fab-stock-out',
                onPressed: () => context.push(
                  RoutePaths.rawMaterialStockOut(materialType.name),
                ),
                icon: Icons.remove_circle_outline,
                label: AppStrings.stockOut,
              ),
              const SizedBox(height: 10),
              AppExtendedFab(
                heroTag: 'fab-stock-in',
                onPressed: () => context.push(
                  RoutePaths.rawMaterialStockIn(materialType.name),
                ),
                icon: Icons.add_circle_outline,
                label: AppStrings.stockIn,
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
                                material.currentStock,
                                material.unit.label,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (material.isLowStock) const LowStockBadge(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.currentStock,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              SettingsSection(
                title: AppStrings.materialDetails,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SummaryRow(
                        label: AppStrings.reorderLevel,
                        value: Formatters.stockQuantity(
                          material.reorderLevel,
                          material.unit.label,
                        ),
                        trailing: IconButton(
                          onPressed: material.id.isEmpty
                              ? null
                              : () => _editReorderLevel(
                                    context,
                                    material.reorderLevel,
                                  ),
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: AppStrings.setReorderLevel,
                        ),
                      ),
                      if (material.id.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            AppStrings.recordStockInFirst,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        label: AppStrings.averageCost,
                        value: material.averageCost > 0
                            ? Formatters.currencyPkr(material.averageCost)
                            : '—',
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        label: AppStrings.stockValue,
                        value: material.hasStock
                            ? Formatters.currencyPkr(material.stockValue)
                            : '—',
                      ),
                      if (material.lastReceiptDate != null) ...[
                        const SizedBox(height: 12),
                        _SummaryRow(
                          label: AppStrings.lastReceipt,
                          value: DateFormat.yMMMd()
                              .format(material.lastReceiptDate!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SettingsSection(
                title: AppStrings.stockHistory,
                child: state.transactions.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          AppStrings.noStockHistory,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      )
                    : factoryId == null
                        ? Column(
                            children: state.transactions
                                .map(
                                  (transaction) => _TransactionTile(
                                    transaction: transaction,
                                  ),
                                )
                                .toList(),
                          )
                        : StreamBuilder<List<Supplier>>(
                            stream: getIt<SupplierRepository>()
                                .watchSuppliers(factoryId),
                            builder: (context, snapshot) {
                              final supplierNames = {
                                for (final supplier
                                    in snapshot.data ?? const <Supplier>[])
                                  supplier.id: supplier.name,
                              };

                              return Column(
                                children: state.transactions
                                    .map(
                                      (transaction) => _TransactionTile(
                                        transaction: transaction,
                                        supplierName: transaction.supplierId !=
                                                null
                                            ? supplierNames[
                                                transaction.supplierId]
                                            : null,
                                      ),
                                    )
                                    .toList(),
                              );
                            },
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
  const _TransactionTile({
    required this.transaction,
    this.supplierName,
  });

  final StockTransaction transaction;
  final String? supplierName;

  @override
  Widget build(BuildContext context) {
    final isIn = transaction.movementType == StockMovementType.stockIn;
    final color = isIn ? AppColors.success : AppColors.error;
    final prefix = isIn ? '+' : '−';
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    final subtitleParts = <String>[
      DateFormat.yMMMd().format(transaction.transactionDate),
      transaction.transactionNumber,
      if (isIn &&
          supplierName != null &&
          supplierName!.isNotEmpty)
        supplierName!,
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
        '$prefix${Formatters.stockQuantity(transaction.quantity, transaction.unit.label)}',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/finished_goods/finished_goods_detail_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../routes/route_paths.dart';
import '../../widgets/dialogs/app_input_dialog.dart';
import '../../widgets/dialogs/storage_location_dialog.dart';
import '../../widgets/finished_goods/finished_good_detail_hero.dart';
import '../../widgets/finished_goods/finished_good_inventory_history_section.dart';
import '../../widgets/finished_goods/finished_good_stock_actions_bar.dart';
import '../../widgets/job_work/job_work_detail_row.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

class FinishedGoodDetailScreen extends StatelessWidget {
  const FinishedGoodDetailScreen({required this.finishedGoodId, super.key});

  final String finishedGoodId;

  Future<void> _editReorderLevel(BuildContext context, double current) async {
    final result = await AppInputDialog.showNumber(
      context,
      title: AppStrings.setReorderLevel,
      fieldLabel: AppStrings.reorderLevel,
      helperText: AppStrings.reorderLevelHint,
      initialValue: current,
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
    final result = await StorageLocationDialog.show(
      context,
      currentLocation: currentLocation,
    );

    if (!context.mounted) return;

    context.read<FinishedGoodsDetailBloc>().add(
          FinishedGoodsLocationUpdated(result),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.locationUpdated)),
    );
  }

  JobWorkDetailRow _editableValueRow({
    required BuildContext context,
    required String label,
    required String value,
    required VoidCallback onEdit,
    required String editTooltip,
  }) {
    return JobWorkDetailRow(
      label: label,
      valueWidget: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 16),
              tooltip: editTooltip,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
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
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.stockItemDetails),
                Text(
                  item.productType.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: (Theme.of(context).appBarTheme.foregroundColor ??
                                Theme.of(context).colorScheme.onSurface)
                            .withValues(alpha: 0.78),
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              FinishedGoodDetailHero(item: item),
              FinishedGoodStockActionsBar(
                onAdjustIn: () => context.push(
                  RoutePaths.finishedGoodAdjustIn(item.id),
                ),
                onAdjustOut: () => context.push(
                  RoutePaths.finishedGoodAdjustOut(item.id),
                ),
              ),
              JobWorkDetailSection(
                title: AppStrings.stockItemDetails,
                icon: Icons.inventory_2_outlined,
                child: JobWorkDetailRows(
                  rows: [
                    _editableValueRow(
                      context: context,
                      label: AppStrings.reorderLevel,
                      value: Formatters.stockQuantity(
                        item.reorderLevel,
                        'sq. ft',
                      ),
                      onEdit: () => _editReorderLevel(context, item.reorderLevel),
                      editTooltip: AppStrings.setReorderLevel,
                    ),
                    _editableValueRow(
                      context: context,
                      label: AppStrings.storageLocation,
                      value: item.location ?? AppStrings.notSpecified,
                      onEdit: () => _editLocation(context, item.location),
                      editTooltip: AppStrings.setStorageLocation,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.averageCost,
                      value: item.averageCost > 0
                          ? '${Formatters.currencyPkr(item.averageCost)} / sq. ft'
                          : '—',
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.stockValue,
                      value: item.hasStock
                          ? Formatters.currencyPkr(item.stockValue)
                          : '—',
                      bold: item.hasStock,
                      highlight: item.hasStock,
                    ),
                    if (item.lastReceiptDate != null)
                      JobWorkDetailRow(
                        label: AppStrings.lastReceipt,
                        value: DateFormat.yMMMd().format(item.lastReceiptDate!),
                      ),
                  ],
                ),
              ),
              JobWorkDetailSection(
                title: AppStrings.productType,
                icon: Icons.layers_outlined,
                child: JobWorkDetailRows(
                  rows: [
                    JobWorkDetailRow(
                      label: AppStrings.productType,
                      value: item.productType.label,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.marbleVariety,
                      value: item.marbleVariety,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.grade,
                      value: item.grade.label,
                    ),
                    if (item.size != null && item.size!.isNotEmpty)
                      JobWorkDetailRow(
                        label: AppStrings.size,
                        value: item.size!,
                      ),
                    if (item.thickness != null && item.thickness!.isNotEmpty)
                      JobWorkDetailRow(
                        label: AppStrings.thickness,
                        value: item.thickness!,
                      ),
                  ],
                ),
              ),
              FinishedGoodInventoryHistorySection(
                transactions: state.transactions,
              ),
            ],
          ),
        );
      },
    );
  }
}

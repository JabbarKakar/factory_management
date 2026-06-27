import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../blocs/production/production_detail_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/settings_section.dart';

class ProductionBatchDetailScreen extends StatelessWidget {
  const ProductionBatchDetailScreen({required this.batchId, super.key});

  final String batchId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductionDetailBloc, ProductionDetailState>(
      builder: (context, state) {
        if (state.status == ProductionDetailStatus.loading &&
            state.batch == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.productionBatchDetails)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state.batch == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.productionBatchDetails)),
            body: Center(
              child: Text(
                state.errorMessage ?? AppStrings.productionBatchNotFound,
              ),
            ),
          );
        }

        final batch = state.batch!;
        final muted = Theme.of(context).colorScheme.onSurfaceVariant;

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.productionBatchDetails),
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Card(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batch.batchNumber,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${DateFormat.yMMMd().format(batch.productionDate)} · ${batch.shift.label}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: muted,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${batch.productType.label} · ${batch.marbleVariety}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              SettingsSection(
                title: AppStrings.rawMaterialConsumed,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: AppStrings.materialType,
                        value: batch.rawMaterialType.label,
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: AppStrings.quantityConsumed,
                        value: Formatters.stockQuantity(
                          batch.materialConsumed,
                          batch.materialUnit.label,
                        ),
                      ),
                      if (batch.materialCost != null && batch.materialCost! > 0) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          label: AppStrings.materialCost,
                          value: Formatters.currencyPkr(batch.materialCost!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SettingsSection(
                title: AppStrings.productionOutput,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (batch.size != null) ...[
                        _DetailRow(label: AppStrings.size, value: batch.size!),
                        const SizedBox(height: 12),
                      ],
                      if (batch.thickness != null) ...[
                        _DetailRow(
                          label: AppStrings.thickness,
                          value: batch.thickness!,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _DetailRow(
                        label: AppStrings.gradeA,
                        value: Formatters.stockQuantity(batch.gradeASqFt, 'sq. ft'),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: AppStrings.gradeB,
                        value: Formatters.stockQuantity(batch.gradeBSqFt, 'sq. ft'),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: AppStrings.gradeC,
                        value: Formatters.stockQuantity(batch.gradeCSqFt, 'sq. ft'),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: AppStrings.reject,
                        value: Formatters.stockQuantity(batch.rejectSqFt, 'sq. ft'),
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        label: AppStrings.totalUsableOutput,
                        value: Formatters.stockQuantity(
                          batch.totalUsableSqFt,
                          'sq. ft',
                        ),
                        emphasized: true,
                      ),
                      if (batch.wasteTons != null && batch.wasteTons! > 0) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          label: AppStrings.wasteGeneratedTons,
                          value: Formatters.stockQuantity(batch.wasteTons!, 'Ton'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (batch.supervisorName != null || batch.notes != null)
                SettingsSection(
                  title: AppStrings.optionalDetails,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (batch.supervisorName != null) ...[
                          _DetailRow(
                            label: AppStrings.supervisorName,
                            value: batch.supervisorName!,
                          ),
                          if (batch.notes != null) const SizedBox(height: 12),
                        ],
                        if (batch.notes != null)
                          _DetailRow(
                            label: AppStrings.notes,
                            value: batch.notes!,
                          ),
                      ],
                    ),
                  ),
                ),
              if (batch.stockTransactionId != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    AppStrings.productionStockLinked,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: muted)),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

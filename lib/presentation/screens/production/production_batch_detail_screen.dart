import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/production/production_detail_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/enums/quality_enums.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/job_work/job_work_detail_row.dart';
import '../../widgets/job_work/job_work_detail_section.dart';
import '../../widgets/production/production_batch_detail_hero.dart';
import '../../widgets/production/production_stock_linked_banner.dart';
import '../../widgets/quality/qc_reference_section.dart';

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

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.productionBatchDetails),
                Text(
                  batch.batchNumber,
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
            actions: [
              if (context.userCanEdit(AppModule.production))
                IconButton(
                  onPressed: () async {
                    final updated = await context.push<bool>(
                      RoutePaths.productionEdit(batch.id),
                    );
                    if (updated == true && context.mounted) {
                      context.read<ProductionDetailBloc>().add(
                            ProductionDetailWatchStarted(batchId),
                          );
                    }
                  },
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: AppStrings.editProductionBatch,
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              ProductionBatchDetailHero(batch: batch),
              JobWorkDetailSection(
                title: AppStrings.batchInformation,
                icon: Icons.info_outline_rounded,
                child: JobWorkDetailRows(
                  rows: [
                    JobWorkDetailRow(
                      label: AppStrings.productionDate,
                      value: DateFormat.yMMMd().format(batch.productionDate),
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.shift,
                      value: batch.shift.label,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.productType,
                      value: batch.productType.label,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.marbleVariety,
                      value: batch.marbleVariety,
                    ),
                    if (batch.size != null && batch.size!.isNotEmpty)
                      JobWorkDetailRow(
                        label: AppStrings.size,
                        value: batch.size!,
                      ),
                    if (batch.thickness != null && batch.thickness!.isNotEmpty)
                      JobWorkDetailRow(
                        label: AppStrings.thickness,
                        value: batch.thickness!,
                      ),
                  ],
                ),
              ),
              JobWorkDetailSection(
                title: AppStrings.rawMaterialConsumed,
                icon: Icons.inventory_2_outlined,
                child: JobWorkDetailRows(
                  rows: [
                    JobWorkDetailRow(
                      label: AppStrings.materialType,
                      value: batch.rawMaterialType.label,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.quantityConsumed,
                      value: Formatters.stockQuantity(
                        batch.materialConsumed,
                        batch.materialUnit.label,
                      ),
                    ),
                    if (batch.materialCost != null && batch.materialCost! > 0)
                      JobWorkDetailRow(
                        label: AppStrings.materialCost,
                        value: Formatters.currencyPkr(batch.materialCost!),
                        bold: true,
                        highlight: true,
                      ),
                  ],
                ),
              ),
              JobWorkDetailSection(
                title: AppStrings.productionOutput,
                icon: Icons.analytics_outlined,
                child: JobWorkDetailRows(
                  rows: [
                    JobWorkDetailRow(
                      label: AppStrings.gradeA,
                      value: Formatters.stockQuantity(batch.gradeASqFt, 'sq. ft'),
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.gradeB,
                      value: Formatters.stockQuantity(batch.gradeBSqFt, 'sq. ft'),
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.gradeC,
                      value: Formatters.stockQuantity(batch.gradeCSqFt, 'sq. ft'),
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.reject,
                      value: Formatters.stockQuantity(batch.rejectSqFt, 'sq. ft'),
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.totalUsableOutput,
                      value: Formatters.stockQuantity(
                        batch.totalUsableSqFt,
                        'sq. ft',
                      ),
                      bold: true,
                      highlight: true,
                    ),
                    if (batch.wasteTons != null && batch.wasteTons! > 0)
                      JobWorkDetailRow(
                        label: AppStrings.wasteGeneratedTons,
                        value: Formatters.stockQuantity(batch.wasteTons!, 'Ton'),
                      ),
                  ],
                ),
              ),
              if (batch.totalOutputSqFt > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: QcReferenceSection(
                    checks: state.qualityChecks,
                    onRecordQc: () => context.push(
                      RoutePaths.qualityChecksAddForReference(
                        refType: QcReferenceType.production,
                        referenceId: batch.id,
                      ),
                    ),
                  ),
                ),
              if (batch.supervisorName != null || batch.notes != null)
                JobWorkDetailSection(
                  title: AppStrings.optionalDetails,
                  icon: Icons.notes_outlined,
                  child: JobWorkDetailRows(
                    rows: [
                      if (batch.supervisorName != null)
                        JobWorkDetailRow(
                          label: AppStrings.supervisorName,
                          value: batch.supervisorName!,
                        ),
                      if (batch.notes != null)
                        JobWorkDetailRow(
                          label: AppStrings.notes,
                          value: batch.notes!,
                        ),
                    ],
                  ),
                ),
              if (batch.stockTransactionId != null)
                const ProductionStockLinkedBanner(),
            ],
          ),
        );
      },
    );
  }
}

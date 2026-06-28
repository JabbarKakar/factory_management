import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/quality/qc_detail_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/enums/quality_enums.dart';
import '../../routes/route_paths.dart';
import '../../widgets/job_work/job_work_detail_row.dart';
import '../../widgets/job_work/job_work_detail_section.dart';
import '../../widgets/quality/qc_detail_hero.dart';
import '../../widgets/quality/qc_reference_action_bar.dart';

class QcDetailScreen extends StatelessWidget {
  const QcDetailScreen({required this.qcId, super.key});

  final String qcId;

  String _sqFt(double value) => Formatters.stockQuantity(value, 'sq. ft');

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QcDetailBloc, QcDetailState>(
      builder: (context, state) {
        if (state.status == QcDetailStatus.loading ||
            state.status == QcDetailStatus.initial) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.qcInspectionDetails)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final check = state.check;
        if (check == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.qcInspectionDetails)),
            body: Center(
              child: Text(state.errorMessage ?? AppStrings.qcNotFound),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.qcInspectionDetails),
                Text(
                  check.qcNumber,
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
              QcDetailHero(check: check),
              QcReferenceActionBar(
                referenceType: check.referenceType,
                onPressed: () {
                  if (check.referenceType == QcReferenceType.production) {
                    context.push(RoutePaths.productionDetail(check.referenceId));
                  } else {
                    context.push(RoutePaths.jobWorkDetail(check.referenceId));
                  }
                },
              ),
              JobWorkDetailSection(
                title: AppStrings.qcInspectionDetails,
                icon: Icons.fact_check_outlined,
                child: JobWorkDetailRows(
                  rows: [
                    JobWorkDetailRow(
                      label: AppStrings.inspectionDate,
                      value: DateFormat.yMMMd().format(check.inspectionDate),
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.inspectorName,
                      value: check.inspectorName,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.qcReferenceType,
                      value: check.referenceType.label,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.qcReference,
                      value: check.referenceNumber,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.productType,
                      value: check.productLabel,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.marbleVariety,
                      value: check.marbleVariety,
                    ),
                    if (check.sizeThickness != null &&
                        check.sizeThickness!.isNotEmpty)
                      JobWorkDetailRow(
                        label: AppStrings.sizeThickness,
                        value: check.sizeThickness!,
                      ),
                    JobWorkDetailRow(
                      label: AppStrings.quantityInspected,
                      value: _sqFt(check.quantityInspected),
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.qcDisposition,
                      value: check.disposition.label,
                      bold: true,
                      highlight: true,
                    ),
                  ],
                ),
              ),
              JobWorkDetailSection(
                title: AppStrings.outputByGrade,
                icon: Icons.analytics_outlined,
                child: JobWorkDetailRows(
                  rows: [
                    JobWorkDetailRow(
                      label: AppStrings.gradeA,
                      value: _sqFt(check.gradeASqFt),
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.gradeB,
                      value: _sqFt(check.gradeBSqFt),
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.gradeC,
                      value: _sqFt(check.gradeCSqFt),
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.reject,
                      value: _sqFt(check.rejectSqFt),
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.totalUsableOutput,
                      value: _sqFt(check.totalUsableSqFt),
                      bold: true,
                      highlight: true,
                    ),
                  ],
                ),
              ),
              if (check.defects.isNotEmpty)
                JobWorkDetailSection(
                  title: AppStrings.defectsFound,
                  icon: Icons.report_problem_outlined,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: check.defects
                          .map(
                            (defect) => _DefectChip(label: defect.label),
                          )
                          .toList(),
                    ),
                  ),
                ),
              if (check.notes != null && check.notes!.isNotEmpty)
                JobWorkDetailSection(
                  title: AppStrings.notes,
                  icon: Icons.notes_outlined,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Text(
                      check.notes!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            height: 1.35,
                          ),
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

class _DefectChip extends StatelessWidget {
  const _DefectChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

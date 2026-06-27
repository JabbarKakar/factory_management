import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../blocs/quality/qc_detail_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/quality/qc_disposition_badge.dart';
import '../../widgets/settings_section.dart';

class QcDetailScreen extends StatelessWidget {
  const QcDetailScreen({required this.qcId, super.key});

  final String qcId;

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
          appBar: AppBar(title: const Text(AppStrings.qcInspectionDetails)),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              check.qcNumber,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          QcDispositionBadge(disposition: check.disposition),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${check.referenceType.label} · ${check.referenceNumber}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      if (check.referenceLabel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(check.referenceLabel),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        '${check.passRatePercent.toStringAsFixed(1)}% ${AppStrings.passRate}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              SettingsSection(
                title: AppStrings.qcInspectionDetails,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _Row(
                        AppStrings.inspectionDate,
                        DateFormat.yMMMd().format(check.inspectionDate),
                      ),
                      const SizedBox(height: 8),
                      _Row(AppStrings.inspectorName, check.inspectorName),
                      const SizedBox(height: 8),
                      _Row(AppStrings.productType, check.productLabel),
                      const SizedBox(height: 8),
                      _Row(AppStrings.marbleVariety, check.marbleVariety),
                      if (check.sizeThickness != null &&
                          check.sizeThickness!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _Row(AppStrings.sizeThickness, check.sizeThickness!),
                      ],
                      const SizedBox(height: 8),
                      _Row(
                        AppStrings.quantityInspected,
                        '${check.quantityInspected.toStringAsFixed(1)} sq.ft',
                      ),
                    ],
                  ),
                ),
              ),
              SettingsSection(
                title: AppStrings.outputByGrade,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _Row(
                        AppStrings.gradeA,
                        '${check.gradeASqFt.toStringAsFixed(1)} sq.ft',
                      ),
                      const SizedBox(height: 8),
                      _Row(
                        AppStrings.gradeB,
                        '${check.gradeBSqFt.toStringAsFixed(1)} sq.ft',
                      ),
                      const SizedBox(height: 8),
                      _Row(
                        AppStrings.gradeC,
                        '${check.gradeCSqFt.toStringAsFixed(1)} sq.ft',
                      ),
                      const SizedBox(height: 8),
                      _Row(
                        AppStrings.reject,
                        '${check.rejectSqFt.toStringAsFixed(1)} sq.ft',
                      ),
                      const SizedBox(height: 8),
                      _Row(
                        AppStrings.totalUsableOutput,
                        '${check.totalUsableSqFt.toStringAsFixed(1)} sq.ft',
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),
              if (check.defects.isNotEmpty)
                SettingsSection(
                  title: AppStrings.defectsFound,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: check.defects
                          .map(
                            (defect) => Chip(
                              label: Text(defect.label),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              if (check.notes != null && check.notes!.isNotEmpty)
                SettingsSection(
                  title: AppStrings.notes,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(check.notes!),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: TextStyle(color: muted)),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

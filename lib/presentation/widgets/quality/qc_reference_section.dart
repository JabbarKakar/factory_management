import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/quality_check.dart';
import '../../routes/route_paths.dart';
import '../settings_section.dart';
import 'qc_disposition_badge.dart';

class QcReferenceSection extends StatelessWidget {
  const QcReferenceSection({
    required this.checks,
    required this.onRecordQc,
    super.key,
  });

  final List<QualityCheck> checks;
  final VoidCallback onRecordQc;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: AppStrings.qualityInspections,
      child: checks.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.noQualityChecksForReference,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onRecordQc,
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text(AppStrings.recordQcInspection),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                for (final check in checks)
                  ListTile(
                    title: Text(check.qcNumber),
                    subtitle: Text(
                      '${DateFormat.yMMMd().format(check.inspectionDate)} · '
                      '${check.passRatePercent.toStringAsFixed(1)}% pass',
                    ),
                    trailing: QcDispositionBadge(disposition: check.disposition),
                    onTap: () =>
                        context.push(RoutePaths.qualityCheckDetail(check.id)),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onRecordQc,
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text(AppStrings.recordQcInspection),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

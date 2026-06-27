import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/quality_check.dart';
import '../../../domain/enums/quality_enums.dart';
import 'qc_disposition_badge.dart';

class QcListTile extends StatelessWidget {
  const QcListTile({
    required this.check,
    required this.onTap,
    super.key,
  });

  final QualityCheck check;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          check.referenceType == QcReferenceType.production
              ? Icons.precision_manufacturing_outlined
              : Icons.content_cut_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(check.qcNumber),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${check.referenceType.label} · ${check.referenceNumber}',
          ),
          Text(
            '${check.productLabel} · ${check.marbleVariety}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          Text(
            '${DateFormat.yMMMd().format(check.inspectionDate)} · '
            '${check.passRatePercent.toStringAsFixed(1)}% pass',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
      trailing: QcDispositionBadge(disposition: check.disposition),
      onTap: onTap,
    );
  }
}

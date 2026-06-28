import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/quality_enums.dart';
import '../dashboard/dashboard_surface.dart';

class QcReferenceActionBar extends StatelessWidget {
  const QcReferenceActionBar({
    required this.referenceType,
    required this.onPressed,
    super.key,
  });

  final QcReferenceType referenceType;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isProduction = referenceType == QcReferenceType.production;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: DashboardSurfaceCard(
        compact: true,
        borderRadius: 14,
        padding: const EdgeInsets.all(12),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(
            isProduction
                ? Icons.precision_manufacturing_outlined
                : Icons.content_cut_outlined,
            size: 16,
          ),
          label: Text(
            isProduction
                ? AppStrings.viewProductionBatch
                : AppStrings.viewJobWorkOrder,
            style: const TextStyle(fontSize: 12),
          ),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );
  }
}

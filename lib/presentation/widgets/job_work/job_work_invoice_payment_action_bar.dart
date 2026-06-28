import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../dashboard/dashboard_surface.dart';

class JobWorkInvoicePaymentActionBar extends StatelessWidget {
  const JobWorkInvoicePaymentActionBar({
    required this.onRecordPayment,
    this.enabled = true,
    super.key,
  });

  final VoidCallback onRecordPayment;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: DashboardSurfaceCard(
        compact: true,
        borderRadius: 14,
        padding: const EdgeInsets.all(12),
        child: FilledButton.icon(
          onPressed: enabled ? onRecordPayment : null,
          icon: const Icon(Icons.payments_outlined, size: 16),
          label: Text(
            AppStrings.recordPayment,
            style: const TextStyle(fontSize: 12),
          ),
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );
  }
}

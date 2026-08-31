import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import 'job_work_detail_row.dart';
import 'job_work_detail_section.dart';

class JobWorkCreditSection extends StatelessWidget {
  const JobWorkCreditSection({
    required this.amount,
    this.onManageCredit,
    this.manageEnabled = true,
    super.key,
  });

  final double amount;
  final VoidCallback? onManageCredit;
  final bool manageEnabled;

  @override
  Widget build(BuildContext context) {
    return JobWorkDetailSection(
      title: AppStrings.inCredit,
      icon: Icons.account_balance_wallet_outlined,
      action: onManageCredit == null
          ? null
          : FilledButton.tonal(
              onPressed: manageEnabled ? onManageCredit : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                AppStrings.manageCredit,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      child: JobWorkDetailRows(
        rows: [
          JobWorkDetailRow(
            label: AppStrings.availableCredit,
            value: Formatters.currencyPkr(amount),
            bold: true,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

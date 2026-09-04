import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/monthly_ledger.dart';
import '../../../domain/enums/labour_enums.dart';
import '../job_work/job_work_detail_row.dart';
import '../job_work/job_work_detail_section.dart';

class MonthlyLedgerBreakdownSection extends StatelessWidget {
  const MonthlyLedgerBreakdownSection({required this.ledger, super.key});

  final MonthlyLedger ledger;

  @override
  Widget build(BuildContext context) {
    return JobWorkDetailSection(
      title: AppStrings.monthLedgerDetail,
      icon: Icons.summarize_outlined,
      child: JobWorkDetailRows(
        rows: [
          JobWorkDetailRow(
            label: AppStrings.salaryType,
            value: ledger.wageType.label,
          ),
          JobWorkDetailRow(
            label: AppStrings.ledgerBaseRate,
            value: Formatters.currencyPkr(ledger.baseRate),
          ),
          if (ledger.wageType == SalaryType.dailyRate)
            JobWorkDetailRow(
              label: AppStrings.ledgerBillableDays,
              value: ledger.billableDays.toStringAsFixed(
                ledger.billableDays == ledger.billableDays.roundToDouble()
                    ? 0
                    : 1,
              ),
            ),
          if (ledger.openingBalance.abs() > 0.005)
            JobWorkDetailRow(
              label: AppStrings.ledgerOpeningBalance,
              value: Formatters.currencyPkr(ledger.openingBalance),
              highlight: true,
            ),
          if (ledger.adjustments.abs() > 0.005)
            JobWorkDetailRow(
              label: AppStrings.ledgerAdjustments,
              value: Formatters.currencyPkr(ledger.adjustments),
            ),
          JobWorkDetailRow(
            label: AppStrings.ledgerTotalPayable,
            value: Formatters.currencyPkr(ledger.totalPayable),
            bold: true,
            highlight: true,
          ),
          JobWorkDetailRow(
            label: AppStrings.totalPaidToDate,
            value: Formatters.currencyPkr(ledger.totalPaid),
            bold: true,
          ),
          JobWorkDetailRow(
            label: ledger.isOverpaid
                ? AppStrings.overpaidBalance
                : AppStrings.remainingBalance,
            value: Formatters.currencyPkr(ledger.remainingBalance.abs()),
            bold: true,
          ),
          if (ledger.closedAt != null)
            JobWorkDetailRow(
              label: AppStrings.ledgerClosedAt,
              value: DateFormat.yMMMd().add_jm().format(ledger.closedAt!),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/supplier_statement.dart';
import '../job_work/job_work_detail_row.dart';
import '../job_work/job_work_detail_section.dart';

class SupplierStatementLedgerSection extends StatelessWidget {
  const SupplierStatementLedgerSection({
    required this.statement,
    super.key,
  });

  final SupplierStatement statement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final dateFormat = DateFormat.yMMMd();

    return JobWorkDetailSection(
      title: 'Purchase & Payment Ledger',
      icon: Icons.receipt_long_outlined,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            JobWorkDetailRow(
              label: AppStrings.openingBalance,
              value: Formatters.currencyPkr(statement.openingBalance),
            ),
            if (statement.lines.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  AppStrings.noStatementActivity,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    height: 1.35,
                    color: muted,
                  ),
                ),
              )
            else ...[
              const SizedBox(height: 10),
              for (var i = 0; i < statement.lines.length; i++) ...[
                _SupplierStatementLineRow(
                  line: statement.lines[i],
                  dateFormat: dateFormat,
                ),
                if (i < statement.lines.length - 1) const SizedBox(height: 8),
              ],
            ],
            const SizedBox(height: 10),
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.22),
            ),
            const SizedBox(height: 10),
            JobWorkDetailRow(
              label: AppStrings.remainingPayable,
              value: Formatters.currencyPkr(statement.closingBalance),
              bold: true,
              highlight: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierStatementLineRow extends StatelessWidget {
  const _SupplierStatementLineRow({
    required this.line,
    required this.dateFormat,
  });

  final SupplierStatementLine line;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final scheme = Theme.of(context).colorScheme;
    final isPurchase = line.debit > 0;
    final amount = isPurchase ? line.debit : line.credit;
    final amountText = isPurchase
        ? '+${Formatters.currencyPkr(amount)}'
        : '-${Formatters.currencyPkr(amount)}';
    final amountColor = isPurchase ? scheme.error : AppColors.success;
    final icon = isPurchase
        ? Icons.shopping_bag_outlined
        : Icons.payments_outlined;

    String subtitle = '${dateFormat.format(line.date)} · ${line.reference}';
    if (line.quantity != null && line.quantity! > 0) {
      final unitStr = line.unit ?? '';
      final rateStr = line.unitPrice != null && line.unitPrice! > 0
          ? ' · @ ${Formatters.currencyPkr(line.unitPrice!)}'
          : '';
      subtitle =
          '${line.quantity!.toStringAsFixed(line.quantity! % 1 == 0 ? 0 : 2)} $unitStr$rateStr\n$subtitle';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: amountColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.25,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: muted,
                        fontSize: 11,
                        height: 1.25,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountText,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}

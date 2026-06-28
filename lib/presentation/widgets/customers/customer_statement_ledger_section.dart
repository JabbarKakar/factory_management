import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/customer_statement.dart';
import '../job_work/job_work_detail_row.dart';
import '../job_work/job_work_detail_section.dart';

class CustomerStatementLedgerSection extends StatelessWidget {
  const CustomerStatementLedgerSection({
    required this.statement,
    super.key,
  });

  final CustomerStatement statement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final dateFormat = DateFormat.yMMMd();

    return JobWorkDetailSection(
      title: AppStrings.accountLedger,
      icon: Icons.account_balance_wallet_outlined,
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
                _StatementLineRow(
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
              label: AppStrings.closingBalance,
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

class _StatementLineRow extends StatelessWidget {
  const _StatementLineRow({
    required this.line,
    required this.dateFormat,
  });

  final CustomerStatementLine line;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final scheme = Theme.of(context).colorScheme;
    final isDebit = line.debit > 0;
    final amount = isDebit ? line.debit : line.credit;
    final amountText = isDebit
        ? '+${Formatters.currencyPkr(amount)}'
        : '-${Formatters.currencyPkr(amount)}';
    final amountColor = isDebit ? scheme.error : AppColors.success;
    final icon = isDebit
        ? Icons.arrow_circle_up_outlined
        : Icons.payments_outlined;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: amountColor),
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
                  '${dateFormat.format(line.date)} · ${line.reference}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: muted,
                        fontSize: 11,
                        height: 1.2,
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

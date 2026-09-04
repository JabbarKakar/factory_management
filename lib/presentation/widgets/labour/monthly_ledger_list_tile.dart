import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/monthly_ledger.dart';
import '../../routes/route_paths.dart';
import 'monthly_ledger_status_badge.dart';

class MonthlyLedgerListTile extends StatelessWidget {
  const MonthlyLedgerListTile({
    required this.employeeId,
    required this.ledger,
    super.key,
  });

  final String employeeId;
  final MonthlyLedger ledger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);
    final accent = monthlyLedgerStatusAccent(ledger);
    const cardShape = BorderRadius.only(
      topRight: Radius.circular(14),
      bottomRight: Radius.circular(14),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(
            RoutePaths.employeeMonthLedger(employeeId, ledger.monthKey),
          ),
          borderRadius: cardShape,
          child: Ink(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: cardShape,
              border: Border.all(color: outline),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ColoredBox(color: accent, child: const SizedBox(width: 3)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  DateKeys.monthLabel(ledger.monthKey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              MonthlyLedgerStatusBadge(ledger: ledger),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${AppStrings.totalPaidToDate} ${Formatters.currencyPkr(ledger.totalPaid)}'
                            ' · ${ledger.isOverpaid ? AppStrings.overpaidBalance : AppStrings.remainingBalance} '
                            '${Formatters.currencyPkr(ledger.remainingBalance.abs())}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.chevron_right,
                      color: muted,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

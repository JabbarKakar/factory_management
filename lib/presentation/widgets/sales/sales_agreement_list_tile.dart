import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/sales_agreement.dart';
import '../../../domain/enums/sales_agreement_enums.dart';
import '../tile_options_menu.dart';

class SalesAgreementListTile extends StatelessWidget {
  const SalesAgreementListTile({
    required this.agreement,
    required this.onTap,
    this.menuActions = const [],
    this.isBusy = false,
    this.paidAmount,
    this.remainingAmount,
    super.key,
  });

  final SalesAgreement agreement;
  final VoidCallback onTap;
  final List<TileMenuAction> menuActions;
  final bool isBusy;
  final double? paidAmount;
  final double? remainingAmount;

  bool get _showPaymentStrip =>
      paidAmount != null && remainingAmount != null;

  bool get _isListMuted =>
      agreement.summaryStatus == SalesAgreementSummaryStatus.cancelled ||
      agreement.summaryStatus == SalesAgreementSummaryStatus.idle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = agreement.summaryStatus;
    final accent = _accentFor(status);
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);
    const cardShape = BorderRadius.only(
      topRight: Radius.circular(14),
      bottomRight: Radius.circular(14),
    );
    final orderCount = agreement.orderCount ?? 0;
    final activeCount = agreement.activeOrderCount ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Opacity(
        opacity: _isListMuted ? 0.72 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isBusy ? null : onTap,
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
                    Container(width: 3, color: accent),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          12,
                          11,
                          menuActions.isNotEmpty ? 2 : 6,
                          11,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    agreement.customerName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                if (menuActions.isNotEmpty)
                                  TileOptionsButton(
                                    isBusy: isBusy,
                                    actions: menuActions,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              agreement.agreementNumber,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _MetaChip(
                                  icon: Icons.flag_outlined,
                                  label: status.label,
                                ),
                                _MetaChip(
                                  icon: Icons.receipt_long_outlined,
                                  label:
                                      '$orderCount order${orderCount == 1 ? '' : 's'}',
                                ),
                                if (activeCount > 0)
                                  _MetaChip(
                                    icon: Icons.pending_outlined,
                                    label: '$activeCount active',
                                  ),
                              ],
                            ),
                            if (_showPaymentStrip) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _SummaryStrip(
                                      label:
                                          '${AppStrings.amountPaid}: ${Formatters.currencyPkrWhole(paidAmount!)}',
                                      color: AppColors.success,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _SummaryStrip(
                                      label:
                                          '${AppStrings.balanceDue}: ${Formatters.currencyPkrWhole(remainingAmount!)}',
                                      color: remainingAmount! > 0
                                          ? AppColors.warning
                                          : AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _accentFor(SalesAgreementSummaryStatus status) {
    return switch (status) {
      SalesAgreementSummaryStatus.active => AppColors.primary,
      SalesAgreementSummaryStatus.pendingDelivery => AppColors.warning,
      SalesAgreementSummaryStatus.idle => AppColors.textSecondary,
      SalesAgreementSummaryStatus.cancelled =>
        AppColors.error.withValues(alpha: 0.72),
    };
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

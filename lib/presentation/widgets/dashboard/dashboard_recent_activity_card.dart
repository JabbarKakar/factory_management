import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/dashboard_analytics.dart';
import 'dashboard_surface.dart';

class DashboardRecentActivityCard extends StatelessWidget {
  const DashboardRecentActivityCard({
    required this.items,
    super.key,
  });

  final List<RecentActivityItem> items;

  String _relativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.MMMd().format(timestamp);
  }

  String _collapsedSubtitle() {
    if (items.isEmpty) return AppStrings.recentActivityEmpty;
    if (items.length == 1) return '1 recent payment';
    return '${items.length} recent payments';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardSurfaceCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.history_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          title: Text(
            AppStrings.recentActivityTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          subtitle: Text(
            _collapsedSubtitle(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          children: [
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 32,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.45),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.recentActivityEmpty,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(items.length, (index) {
                final item = items[index];
                final isLast = index == items.length - 1;

                return _ActivityTimelineRow(
                  item: item,
                  isLast: isLast,
                  relativeTime: _relativeTime(item.timestamp),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ActivityTimelineRow extends StatelessWidget {
  const _ActivityTimelineRow({
    required this.item,
    required this.isLast,
    required this.relativeTime,
  });

  final RecentActivityItem item;
  final bool isLast;
  final String relativeTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.payments_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: theme.colorScheme.outline.withValues(alpha: 0.35),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          relativeTime,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.amount != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        Formatters.currencyPkr(item.amount!),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

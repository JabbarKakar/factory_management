import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/dashboard_pending_pickup.dart';
import '../../domain/enums/job_work_enums.dart';
import '../routes/route_paths.dart';
import 'dashboard/dashboard_surface.dart';

class PendingPickupsCard extends StatelessWidget {
  const PendingPickupsCard({
    required this.pendingPickups,
    required this.totalCount,
    super.key,
  });

  final List<DashboardPendingPickup> pendingPickups;
  final int totalCount;

  void _openList(BuildContext context) {
    context.go(
      RoutePaths.jobWorkList(filter: JobWorkListStageFilter.pendingPickup),
    );
  }

  void _openItem(BuildContext context, DashboardPendingPickup item) {
    if (item.hasLoad) {
      context.push(
        RoutePaths.jobWorkLoadDetail(
          jobWorkId: item.jobWorkId,
          loadId: item.loadId!,
        ),
      );
      return;
    }
    context.push(RoutePaths.jobWorkDetail(item.jobWorkId));
  }

  @override
  Widget build(BuildContext context) {
    if (totalCount == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.accentLight : AppColors.accent;
    final remaining = totalCount - pendingPickups.length;

    return DashboardSurfaceCard(
      compact: true,
      borderRadius: 14,
      padding: EdgeInsets.zero,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.16 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 18,
              color: accent,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.pendingPickups,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: -0.2,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _CountBadge(count: totalCount, accent: accent),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              AppStrings.pendingPickupsSubtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ),
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: isDark ? 0.35 : 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.28),
                ),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < pendingPickups.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        indent: 54,
                        endIndent: 12,
                        color:
                            theme.colorScheme.outline.withValues(alpha: 0.28),
                      ),
                    _PickupRow(
                      item: pendingPickups[i],
                      onTap: () => _openItem(context, pendingPickups[i]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _openList(context),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                remaining > 0
                    ? '+ $remaining more · ${AppStrings.viewAll}'
                    : AppStrings.viewAll,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count,
    required this.accent,
  });

  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(minWidth: 28),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.22 : 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              height: 1,
            ),
      ),
    );
  }
}

class _PickupRow extends StatelessWidget {
  const _PickupRow({
    required this.item,
    required this.onTap,
  });

  final DashboardPendingPickup item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = Formatters.userInitials(item.customerName);
    final mineBits = [
      if (item.mineLocation != null && item.mineLocation!.trim().isNotEmpty)
        item.mineLocation!.trim(),
      if (item.mineOwner != null && item.mineOwner!.trim().isNotEmpty)
        item.mineOwner!.trim(),
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                child: Text(
                  initials,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? AppColors.primaryDark
                        : AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.primaryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                    if (mineBits.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        mineBits.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.85),
                          fontSize: 10,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/enums/job_work_enums.dart';
import '../routes/route_paths.dart';
import '../widgets/job_work/job_work_status_badge.dart';
import 'dashboard/dashboard_surface.dart';

class PendingPickupsCard extends StatelessWidget {
  const PendingPickupsCard({
    required this.pendingPickups,
    required this.totalCount,
    super.key,
  });

  final List<JobWorkOrder> pendingPickups;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    if (totalCount == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final remaining = totalCount - pendingPickups.length;

    return DashboardSurfaceCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardSectionHeader(
            title: AppStrings.pendingPickups,
            subtitle: AppStrings.pendingPickupsSubtitle,
            icon: Icons.inventory_2_outlined,
            trailing: DashboardTextLink(
              label: AppStrings.viewAll,
              onPressed: () => context.go(
                RoutePaths.jobWorkList(
                  filter: JobWorkListStageFilter.pendingPickup,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$totalCount awaiting pickup',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...pendingPickups.map(
            (order) => _PickupRow(
              order: order,
              onTap: () => context.push(RoutePaths.jobWorkDetail(order.id)),
            ),
          ),
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Center(
                child: Text(
                  '+ $remaining more orders',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PickupRow extends StatelessWidget {
  const _PickupRow({
    required this.order,
    required this.onTap,
  });

  final JobWorkOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = Formatters.userInitials(order.customerName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.25),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      initials,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.jobWorkNumber,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  JobWorkStatusBadge(status: order.status, compact: true),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
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

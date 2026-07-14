import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/dashboard_pending_pickup.dart';
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

  final List<DashboardPendingPickup> pendingPickups;
  final int totalCount;

  static const double _wideBreakpoint = 900;
  static const double _mobileBreakpoint = 600;
  static const double _gridBreakpoint = 1100;

  @override
  Widget build(BuildContext context) {
    if (totalCount == 0) return const SizedBox.shrink();

    final remaining = totalCount - pendingPickups.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isWide = width >= _wideBreakpoint;
        final isMobile = width < _mobileBreakpoint;
        final useGrid = width >= _gridBreakpoint && pendingPickups.length > 1;

        final header = _PendingPickupsHeader(
          totalCount: totalCount,
          isMobile: isMobile,
          onViewAll: () => context.go(
            RoutePaths.jobWorkList(
              filter: JobWorkListStageFilter.pendingPickup,
            ),
          ),
        );

        final pickupList = _PickupList(
          items: pendingPickups,
          dense: isMobile,
          useGrid: useGrid,
        );

        final footer = remaining > 0
            ? Padding(
                padding: EdgeInsets.only(top: isMobile ? 6 : 8),
                child: Center(
                  child: Text(
                    '+ $remaining more loads',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 10 : 11,
                        ),
                  ),
                ),
              )
            : null;

        return DashboardSurfaceCard(
          compact: true,
          borderRadius: 14,
          padding: EdgeInsets.fromLTRB(
            isMobile ? 10 : (isWide ? 16 : 12),
            isMobile ? 10 : (isWide ? 16 : 12),
            isMobile ? 10 : (isWide ? 16 : 12),
            isMobile ? 8 : 10,
          ),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: header),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          pickupList,
                          if (footer != null) footer,
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header,
                    SizedBox(height: isMobile ? 8 : 10),
                    pickupList,
                    if (footer != null) footer,
                  ],
                ),
        );
      },
    );
  }
}

class _PendingPickupsHeader extends StatelessWidget {
  const _PendingPickupsHeader({
    required this.totalCount,
    required this.isMobile,
    required this.onViewAll,
  });

  final int totalCount;
  final bool isMobile;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countLabel = '$totalCount awaiting pickup';

    if (!isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardSectionHeader(
            title: AppStrings.pendingPickups,
            subtitle: AppStrings.pendingPickupsSubtitle,
            icon: Icons.inventory_2_outlined,
            trailing: DashboardTextLink(
              label: AppStrings.viewAll,
              onPressed: onViewAll,
            ),
          ),
          const SizedBox(height: 8),
          _CountChip(label: countLabel),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            size: 15,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.pendingPickups,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  DashboardTextLink(
                    label: AppStrings.viewAll,
                    onPressed: onViewAll,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _CountChip(label: countLabel, dense: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, this.dense = false});

  final String label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
              fontSize: dense ? 9 : 10,
            ),
      ),
    );
  }
}

class _PickupList extends StatelessWidget {
  const _PickupList({
    required this.items,
    required this.dense,
    required this.useGrid,
  });

  final List<DashboardPendingPickup> items;
  final bool dense;
  final bool useGrid;

  void _open(BuildContext context, DashboardPendingPickup item) {
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
    if (useGrid) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          mainAxisExtent: 72,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _PickupRow(
            item: item,
            dense: true,
            compact: true,
            onTap: () => _open(context, item),
          );
        },
      );
    }

    return Column(
      children: [
        for (final item in items)
          _PickupRow(
            item: item,
            dense: dense,
            onTap: () => _open(context, item),
          ),
      ],
    );
  }
}

class _PickupRow extends StatelessWidget {
  const _PickupRow({
    required this.item,
    required this.onTap,
    this.dense = false,
    this.compact = false,
  });

  final DashboardPendingPickup item;
  final VoidCallback onTap;
  final bool dense;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = Formatters.userInitials(item.customerName);
    final avatarRadius = dense ? 14.0 : 18.0;
    final showMineDetails =
        !compact && (item.mineLocation != null || item.mineOwner != null);

    return Padding(
      padding: EdgeInsets.only(bottom: dense ? 6 : 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(dense ? 10 : 12),
          child: Ink(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(dense ? 10 : 12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.25),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: dense ? 8 : 10,
                vertical: dense ? 6 : 9,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    SizedBox(width: dense ? 8 : 10),
                    CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        initials,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: dense ? 10 : 11,
                        ),
                      ),
                    ),
                    SizedBox(width: dense ? 8 : 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.primaryLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: dense ? 12 : 13,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            item.customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: dense ? 10 : 11,
                              height: 1.1,
                            ),
                          ),
                          if (showMineDetails) ...[
                            const SizedBox(height: 1),
                            Text(
                              [
                                if (item.mineLocation != null)
                                  item.mineLocation!,
                                if (item.mineOwner != null) item.mineOwner!,
                              ].join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: dense ? 9 : 10,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!dense) ...[
                      const SizedBox(width: 6),
                      JobWorkStatusBadge(status: item.status, compact: true),
                    ],
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: dense ? 16 : 18,
                      color: theme.colorScheme.onSurfaceVariant,
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
}

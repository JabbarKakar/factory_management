import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../domain/entities/job_work_order.dart';
import '../routes/route_paths.dart';
import '../widgets/job_work/job_work_status_badge.dart';

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.pendingPickups,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(
                    RoutePaths.jobWorkList(filter: 'pendingPickup'),
                  ),
                  child: const Text(AppStrings.viewAll),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.pendingPickupsSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            ...pendingPickups.map((order) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  order.jobWorkNumber,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(order.customerName),
                trailing: JobWorkStatusBadge(status: order.status, compact: true),
                onTap: () => context.push(RoutePaths.jobWorkDetail(order.id)),
              );
            }),
            if (totalCount > pendingPickups.length)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ ${totalCount - pendingPickups.length} more',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

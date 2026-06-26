import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/entities/job_work_order.dart';
import 'job_work_status_badge.dart';

class JobWorkListTile extends StatelessWidget {
  const JobWorkListTile({
    required this.order,
    required this.onTap,
    super.key,
  });

  final JobWorkOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.jobWorkNumber,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  JobWorkStatusBadge(status: order.status, compact: true),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.customerName,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${order.marbleVariety} · ${order.totalTons.toStringAsFixed(2)} tons · ${order.blockCount} blocks',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: muted,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.content_cut, size: 16, color: muted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${order.cuttingStrategy.label} → ${order.targetProduct.label}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: muted,
                          ),
                    ),
                  ),
                  Text(
                    Formatters.currencyPkr(order.negotiatedFinalAmount),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/entities/sales_order.dart';
import 'sales_order_status_badge.dart';

class SalesOrderListTile extends StatelessWidget {
  const SalesOrderListTile({
    required this.order,
    required this.onTap,
    super.key,
  });

  final SalesOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final itemSummary = order.lineItems.isEmpty
        ? 'No line items'
        : order.lineItems
            .map((item) => item.marbleVariety)
            .where((name) => name.isNotEmpty)
            .take(2)
            .join(', ');

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
                      order.orderNumber,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  SalesOrderStatusBadge(status: order.status, compact: true),
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
                '${order.orderSource.label} · ${order.lineItems.length} item${order.lineItems.length == 1 ? '' : 's'}'
                '${itemSummary.isNotEmpty ? ' · $itemSummary' : ''}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: muted,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 16, color: muted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.paymentTerms.label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: muted,
                          ),
                    ),
                  ),
                  Text(
                    Formatters.currencyPkr(order.grandTotal),
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

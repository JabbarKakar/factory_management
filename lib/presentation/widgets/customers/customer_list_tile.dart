import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/entities/customer.dart';
import 'customer_balance_indicator.dart';
import 'service_type_chip.dart';

class CustomerListTile extends StatelessWidget {
  const CustomerListTile({
    required this.customer,
    required this.onTap,
    super.key,
  });

  final Customer customer;
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer.phone,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: muted,
                              ),
                        ),
                      ],
                    ),
                  ),
                  CustomerBalanceIndicator(status: customer.balanceStatus),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ServiceTypeChip(
                    serviceType: customer.serviceType,
                    compact: true,
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.location_on_outlined, size: 14, color: muted),
                  const SizedBox(width: 2),
                  Text(
                    customer.displayLocation,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: muted,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    Formatters.currencyPkr(customer.balance),
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

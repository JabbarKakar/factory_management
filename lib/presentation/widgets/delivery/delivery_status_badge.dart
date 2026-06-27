import 'package:flutter/material.dart';

import '../../../domain/enums/delivery_enums.dart';

class DeliveryStatusBadge extends StatelessWidget {
  const DeliveryStatusBadge({
    required this.status,
    super.key,
  });

  final DeliveryStatus status;

  Color _color(BuildContext context) {
    return switch (status) {
      DeliveryStatus.scheduled => Colors.blue,
      DeliveryStatus.loaded => Colors.indigo,
      DeliveryStatus.inTransit => Colors.orange,
      DeliveryStatus.delivered => Colors.green,
      DeliveryStatus.partiallyDelivered => Colors.teal,
      DeliveryStatus.failed => Colors.red,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

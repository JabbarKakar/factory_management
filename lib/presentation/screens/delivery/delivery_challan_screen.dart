import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../blocs/delivery/delivery_detail_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/delivery/delivery_status_badge.dart';

class DeliveryChallanScreen extends StatelessWidget {
  const DeliveryChallanScreen({required this.deliveryId, super.key});

  final String deliveryId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeliveryDetailBloc, DeliveryDetailState>(
      builder: (context, state) {
        final delivery = state.delivery;
        if (delivery == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.deliveryChallan)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text(AppStrings.deliveryChallan)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DELIVERY CHALLAN',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _ChallanRow(
                        label: 'Challan #',
                        value: delivery.deliveryNumber,
                      ),
                      _ChallanRow(
                        label: 'Sales Order',
                        value: delivery.salesOrderNumber,
                      ),
                      _ChallanRow(
                        label: 'Customer',
                        value: delivery.customerName,
                      ),
                      _ChallanRow(
                        label: 'Delivery Date',
                        value: DateFormat.yMMMd().format(delivery.scheduledDate),
                      ),
                      _ChallanRow(
                        label: 'Address',
                        value: delivery.deliveryAddress,
                      ),
                      const SizedBox(height: 12),
                      DeliveryStatusBadge(status: delivery.status),
                      const Divider(height: 32),
                      Text(
                        AppStrings.itemsToDeliver,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...delivery.lineItems.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.displayLabel,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                '${item.quantityDelivered ?? item.quantity} ${item.quantityUnit.label}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 32),
                      if (delivery.vehicleNumber != null)
                        _ChallanRow(
                          label: AppStrings.deliveryVehicleNumber,
                          value: delivery.vehicleNumber!,
                        ),
                      if (delivery.driverName != null)
                        _ChallanRow(
                          label: AppStrings.driverName,
                          value: delivery.driverName!,
                        ),
                      if (delivery.loadingSupervisor != null)
                        _ChallanRow(
                          label: AppStrings.loadingSupervisor,
                          value: delivery.loadingSupervisor!,
                        ),
                      if (delivery.notes != null && delivery.notes!.isNotEmpty)
                        _ChallanRow(
                          label: AppStrings.notes,
                          value: delivery.notes!,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChallanRow extends StatelessWidget {
  const _ChallanRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

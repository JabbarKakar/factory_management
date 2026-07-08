import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/delivery/delivery_detail_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/delivery_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/delivery/delivery_status_badge.dart';
import '../../widgets/settings_section.dart';

class DeliveryDetailScreen extends StatelessWidget {
  const DeliveryDetailScreen({required this.deliveryId, super.key});

  final String deliveryId;

  Future<void> _advanceStatus(
    BuildContext context,
    DeliveryStatus nextStatus,
  ) async {
    context.read<DeliveryDetailBloc>().add(
          DeliveryDetailStatusAdvanceRequested(nextStatus),
        );
  }

  Future<void> _markFailed(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.markDeliveryFailedTitle,
      message: AppStrings.markDeliveryFailedMessage,
      confirmLabel: AppStrings.markDeliveryFailed,
      destructive: true,
    );
    if (confirmed && context.mounted) {
      context.read<DeliveryDetailBloc>().add(
            const DeliveryDetailMarkFailedRequested(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeliveryDetailBloc, DeliveryDetailState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!)),
          );
        }
        if (state.status == DeliveryDetailStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        if (state.status == DeliveryDetailStatus.loading ||
            state.status == DeliveryDetailStatus.initial) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.deliveryDetails)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final delivery = state.delivery;
        if (delivery == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.deliveryDetails)),
            body: Center(
              child: Text(state.errorMessage ?? AppStrings.deliveryNotFound),
            ),
          );
        }

        final nextStatus = delivery.status.nextStatus;
        final isSaving = state.status == DeliveryDetailStatus.saving;
        final canEditDelivery = context.userCanEdit(AppModule.delivery);
        final canEditThisDelivery =
            canEditDelivery && delivery.status.canEditLogistics;

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.deliveryDetails),
            actions: [
              if (canEditThisDelivery)
                IconButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final updated = await context.push<bool>(
                            RoutePaths.deliveryEdit(delivery.id),
                          );
                          if (updated == true && context.mounted) {
                            context.read<DeliveryDetailBloc>().add(
                                  DeliveryDetailWatchStarted(
                                    deliveryId,
                                    driverEmployeeId:
                                        readDriverEmployeeId(context),
                                  ),
                                );
                          }
                        },
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: AppStrings.editDelivery,
                ),
              IconButton(
                onPressed: () => context.push(
                  RoutePaths.deliveryChallan(delivery.id),
                ),
                icon: const Icon(Icons.description_outlined),
                tooltip: AppStrings.viewChallan,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Card(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              delivery.deliveryNumber,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DeliveryStatusBadge(status: delivery.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        delivery.customerName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        delivery.salesOrderNumber,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (nextStatus != null && canEditDelivery) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonal(
                            onPressed: isSaving
                                ? null
                                : () => _advanceStatus(context, nextStatus),
                            child: Text(delivery.status.advanceActionLabel),
                          ),
                        ),
                      ],
                      if (delivery.status.canConfirmDelivery &&
                          canEditDelivery) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: isSaving
                                ? null
                                : () => context.push(
                                      RoutePaths.deliveryConfirm(delivery.id),
                                    ),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text(AppStrings.confirmDelivery),
                          ),
                        ),
                      ],
                      if (delivery.status.isActive && canEditDelivery) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                isSaving ? null : () => _markFailed(context),
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text(AppStrings.markDeliveryFailed),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(
                            RoutePaths.deliveryChallan(delivery.id),
                          ),
                          icon: const Icon(Icons.description_outlined),
                          label: const Text(AppStrings.viewChallan),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(
                            RoutePaths.salesDetail(delivery.salesOrderId),
                          ),
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: const Text(AppStrings.linkedSalesOrder),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SettingsSection(
                title: AppStrings.deliveryDetails,
                child: Column(
                  children: [
                    ListTile(
                      title: const Text(AppStrings.deliveryAddress),
                      subtitle: Text(delivery.deliveryAddress),
                    ),
                    ListTile(
                      title: const Text(AppStrings.scheduledDeliveryDate),
                      trailing: Text(
                        DateFormat.yMMMd().format(delivery.scheduledDate),
                      ),
                    ),
                    if (delivery.actualDeliveryDate != null)
                      ListTile(
                        title: const Text(AppStrings.actualDeliveryDate),
                        trailing: Text(
                          DateFormat.yMMMd().format(delivery.actualDeliveryDate!),
                        ),
                      ),
                    if (delivery.vehicleNumber != null)
                      ListTile(
                        title: const Text(AppStrings.deliveryVehicleNumber),
                        trailing: Text(delivery.vehicleNumber!),
                      ),
                    if (delivery.driverName != null)
                      ListTile(
                        title: const Text(AppStrings.driverName),
                        trailing: Text(delivery.driverName!),
                      ),
                    if (delivery.loadingSupervisor != null)
                      ListTile(
                        title: const Text(AppStrings.loadingSupervisor),
                        trailing: Text(delivery.loadingSupervisor!),
                      ),
                  ],
                ),
              ),
              SettingsSection(
                title: AppStrings.itemsToDeliver,
                child: Column(
                  children: delivery.lineItems.map((item) {
                    final delivered = item.quantityDelivered;
                    return ListTile(
                      title: Text(item.displayLabel),
                      subtitle: Text(
                        delivered == null
                            ? '${item.quantity} ${item.quantityUnit.label} scheduled'
                            : '$delivered / ${item.quantity} ${item.quantityUnit.label} delivered',
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (delivery.notes != null && delivery.notes!.isNotEmpty)
                SettingsSection(
                  title: AppStrings.notes,
                  child: ListTile(title: Text(delivery.notes!)),
                ),
            ],
          ),
        );
      },
    );
  }
}

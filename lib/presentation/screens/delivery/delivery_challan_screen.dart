import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../blocs/delivery/delivery_detail_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../data/services/export/delivery_challan_pdf_exporter.dart';
import '../../../domain/entities/delivery.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../utils/export_actions.dart';
import '../../utils/export_factory_name.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/delivery/delivery_status_badge.dart';
import '../../widgets/export_menu_button.dart';

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

        final canExport = context.userCanExport(AppModule.sales) ||
            context.userCanExport(AppModule.delivery);

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.deliveryChallan),
            actions: [
              if (canExport)
                ExportMenuButton(
                  onExportPdf: (origin) => _exportPdf(
                    context,
                    delivery: delivery,
                    shareOrigin: origin,
                  ),
                  onPrint: () => _printPdf(context, delivery: delivery),
                ),
            ],
          ),
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
                        AppStrings.deliveryChallanTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _ChallanRow(
                        label: AppStrings.challanNumber,
                        value: delivery.deliveryNumber,
                      ),
                      _ChallanRow(
                        label: AppStrings.orderNumber,
                        value: delivery.salesOrderNumber,
                      ),
                      _ChallanRow(
                        label: AppStrings.customers,
                        value: delivery.customerName,
                      ),
                      _ChallanRow(
                        label: AppStrings.scheduledDateLabel,
                        value: DateFormat.yMMMd().format(delivery.scheduledDate),
                      ),
                      if (delivery.actualDeliveryDate != null)
                        _ChallanRow(
                          label: AppStrings.actualDispatchDate,
                          value: DateFormat.yMMMd()
                              .format(delivery.actualDeliveryDate!),
                        ),
                      _ChallanRow(
                        label: AppStrings.deliveryAddress,
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
                      const SizedBox(height: 8),
                      _ChallanItemsTable(delivery: delivery),
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
                      if (delivery.receiverName != null &&
                          delivery.receiverName!.isNotEmpty)
                        _ChallanRow(
                          label: AppStrings.receiverName,
                          value: delivery.receiverName!,
                        ),
                      if (delivery.notes != null && delivery.notes!.isNotEmpty)
                        _ChallanRow(
                          label: AppStrings.notes,
                          value: delivery.notes!,
                        ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.loadingSupervisor,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 32),
                                const Divider(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  delivery.receiverName != null &&
                                          delivery.receiverName!.isNotEmpty
                                      ? '${AppStrings.receiverName}: ${delivery.receiverName}'
                                      : AppStrings.customerSignature,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 32),
                                const Divider(),
                              ],
                            ),
                          ),
                        ],
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

  Future<void> _exportPdf(
    BuildContext context, {
    required Delivery delivery,
    Rect? shareOrigin,
  }) async {
    final factoryName = await resolveExportFactoryName(context);
    final doc = await getIt<DeliveryChallanPdfExporter>().buildDeliveryChallanPdf(
      delivery: delivery,
      factoryName: factoryName,
    );
    await ExportActions.sharePdf(
      document: doc,
      filename: '${delivery.deliveryNumber}-challan.pdf',
      sharePositionOrigin: shareOrigin,
    );
  }

  Future<void> _printPdf(
    BuildContext context, {
    required Delivery delivery,
  }) async {
    final factoryName = await resolveExportFactoryName(context);
    final doc = await getIt<DeliveryChallanPdfExporter>().buildDeliveryChallanPdf(
      delivery: delivery,
      factoryName: factoryName,
    );
    await ExportActions.printPdf(
      document: doc,
      filename: '${delivery.deliveryNumber}-challan.pdf',
    );
  }
}

class _ChallanItemsTable extends StatelessWidget {
  const _ChallanItemsTable({required this.delivery});

  final Delivery delivery;

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 10,
        );
    final cellStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 11,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(AppStrings.stockDescription, style: headerStyle)),
                Expanded(child: Text(AppStrings.scheduledPiecesShort, style: headerStyle, textAlign: TextAlign.center)),
                Expanded(child: Text(AppStrings.dispatchPiecesShort, style: headerStyle, textAlign: TextAlign.center)),
                Expanded(child: Text(AppStrings.dispatchSquareFeetShort, style: headerStyle, textAlign: TextAlign.center)),
              ],
            ),
          ),
          const Divider(height: 1),
          for (var i = 0; i < delivery.lineItems.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(delivery.lineItems[i].displayLabel, style: cellStyle),
                  ),
                  Expanded(
                    child: Text(
                      '${delivery.lineItems[i].pieces}',
                      style: cellStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      delivery.status.isTerminal
                          ? '${delivery.lineItems[i].effectivePieces}'
                          : '—',
                      style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      delivery.status.isTerminal
                          ? delivery.lineItems[i].effectiveSquareFeet.toStringAsFixed(2)
                          : '—',
                      style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            if (i < delivery.lineItems.length - 1) const Divider(height: 1),
          ],
        ],
      ),
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

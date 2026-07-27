import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/factory_repository.dart';
import '../../../data/repositories/job_work_collection_repository.dart';
import '../../../data/services/export/job_work_collection_slip_pdf_exporter.dart';
import '../../../domain/entities/job_work_collection.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../utils/export_actions.dart';
import '../../utils/export_factory_name.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/export_menu_button.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

class JobWorkCollectionSlipScreen extends StatefulWidget {
  const JobWorkCollectionSlipScreen({required this.collectionId, super.key});

  final String collectionId;

  @override
  State<JobWorkCollectionSlipScreen> createState() =>
      _JobWorkCollectionSlipScreenState();
}

class _JobWorkCollectionSlipScreenState
    extends State<JobWorkCollectionSlipScreen> {
  late final Future<JobWorkCollection?> _future;

  @override
  void initState() {
    super.initState();
    _future =
        getIt<JobWorkCollectionRepository>().getCollection(widget.collectionId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<JobWorkCollection?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.collectionSlip)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final collection = snapshot.data;
        if (collection == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.collectionSlip)),
            body: const Center(child: Text(AppStrings.collectionNotFound)),
          );
        }

        final canExport = context.userCanExport(AppModule.jobWork);

        final hasReceiverDetails = (collection.receiverName?.isNotEmpty == true) ||
            (collection.receiverPhone?.isNotEmpty == true) ||
            (collection.receiverAddress?.isNotEmpty == true) ||
            (collection.receiverEmail?.isNotEmpty == true);

        final hasTransportDetails = (collection.vehicleNumber?.isNotEmpty == true) ||
            (collection.driverName?.isNotEmpty == true) ||
            (collection.driverPhone?.isNotEmpty == true) ||
            (collection.driverCnic?.isNotEmpty == true) ||
            (collection.vehicleType?.isNotEmpty == true);

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.collectionSlip),
            actions: [
              if (canExport)
                ExportMenuButton(
                  onExportPdf: (origin) => _exportPdf(
                    context,
                    collection: collection,
                    shareOrigin: origin,
                  ),
                  onPrint: () => _printPdf(context, collection: collection),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            children: [
              // Top Header Card Banner
              Card(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.collectionSlipTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              collection.collectionNumber,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                theme.colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          collection.status.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 1. Order & Collection Info Section
              JobWorkDetailSection(
                title: AppStrings.collectionDetails,
                icon: Icons.assignment_outlined,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      _SlipRow(
                        label: AppStrings.slipNumber,
                        value: collection.collectionNumber,
                      ),
                      _SlipRow(
                        label: AppStrings.jobWorkNumber,
                        value: collection.jobWorkNumber,
                      ),
                      if (collection.loadNumber != null &&
                          collection.loadNumber!.isNotEmpty)
                        _SlipRow(
                          label: AppStrings.load,
                          value: collection.loadNumber!,
                        ),
                      _SlipRow(
                        label: AppStrings.customers,
                        value: collection.customerName,
                      ),
                      _SlipRow(
                        label: AppStrings.collectionDate,
                        value:
                            DateFormat.yMMMd().format(collection.collectedAt),
                      ),
                      _SlipRow(
                        label: AppStrings.statusLabel,
                        value: collection.status.label,
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Receiver / Consignee Details Section
              if (hasReceiverDetails)
                JobWorkDetailSection(
                  title: AppStrings.receiverDetails,
                  icon: Icons.person_outlined,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      children: [
                        if (collection.receiverName != null &&
                            collection.receiverName!.isNotEmpty)
                          _SlipRow(
                            label: AppStrings.receiverName,
                            value: collection.receiverName!,
                          ),
                        if (collection.receiverPhone != null &&
                            collection.receiverPhone!.isNotEmpty)
                          _SlipRow(
                            label: AppStrings.receiverPhone,
                            value: collection.receiverPhone!,
                          ),
                        if (collection.receiverAddress != null &&
                            collection.receiverAddress!.isNotEmpty)
                          _SlipRow(
                            label: AppStrings.deliveryAddress,
                            value: collection.receiverAddress!,
                          ),
                        if (collection.receiverEmail != null &&
                            collection.receiverEmail!.isNotEmpty)
                          _SlipRow(
                            label: AppStrings.receiverEmail,
                            value: collection.receiverEmail!,
                          ),
                      ],
                    ),
                  ),
                ),

              // 3. Transport & Vehicle Details Section
              if (hasTransportDetails)
                JobWorkDetailSection(
                  title: AppStrings.transportAndVehicleInfo,
                  icon: Icons.local_shipping_outlined,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      children: [
                        if (collection.vehicleNumber != null &&
                            collection.vehicleNumber!.isNotEmpty)
                          _SlipRow(
                            label: AppStrings.vehicleNumber,
                            value: collection.vehicleNumber!,
                          ),
                        if (collection.driverName != null &&
                            collection.driverName!.isNotEmpty)
                          _SlipRow(
                            label: AppStrings.driverName,
                            value: collection.driverName!,
                          ),
                        if (collection.driverPhone != null &&
                            collection.driverPhone!.isNotEmpty)
                          _SlipRow(
                            label: AppStrings.driverPhone,
                            value: collection.driverPhone!,
                          ),
                        if (collection.driverCnic != null &&
                            collection.driverCnic!.isNotEmpty)
                          _SlipRow(
                            label: AppStrings.driverCnic,
                            value: collection.driverCnic!,
                          ),
                        if (collection.vehicleType != null &&
                            collection.vehicleType!.isNotEmpty)
                          _SlipRow(
                            label: AppStrings.vehicleType,
                            value: collection.vehicleType!,
                          ),
                      ],
                    ),
                  ),
                ),

              // 4. Items Collected Section
              JobWorkDetailSection(
                title: AppStrings.itemsCollected,
                icon: Icons.inventory_2_outlined,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SlipItemsTable(collection: collection),
                      const SizedBox(height: 12),
                      _SlipRow(
                        label: AppStrings.totalPieces,
                        value: '${collection.totalPieces}',
                        isBold: true,
                      ),
                      _SlipRow(
                        label: AppStrings.totalSquareFeet,
                        value: collection.totalSquareFeet.toStringAsFixed(2),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Notes Section (if available)
              if (collection.notes != null && collection.notes!.isNotEmpty)
                JobWorkDetailSection(
                  title: AppStrings.notes,
                  icon: Icons.notes_outlined,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      collection.notes!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),

              // 6. Signatures Section
              JobWorkDetailSection(
                title: 'Signatures & Clearances',
                icon: Icons.draw_outlined,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SignatureBlock(
                          label: AppStrings.factorySignature,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _SignatureBlock(
                          label: collection.receiverName != null &&
                                  collection.receiverName!.isNotEmpty
                              ? '${AppStrings.receiverName}: ${collection.receiverName}'
                              : AppStrings.customerSignature,
                        ),
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
    required JobWorkCollection collection,
    Rect? shareOrigin,
  }) async {
    final factoryName = await resolveExportFactoryName(context);
    final factoryRepo = getIt.isRegistered<FactoryRepository>()
        ? getIt<FactoryRepository>()
        : null;
    final profile = factoryRepo != null && collection.factoryId.isNotEmpty
        ? await factoryRepo.getFactory(collection.factoryId)
        : null;

    Uint8List? logoBytes;
    try {
      final byteData = await rootBundle.load('assets/images/app_logo.png');
      logoBytes = byteData.buffer.asUint8List();
    } catch (_) {}

    final doc =
        await getIt<JobWorkCollectionSlipPdfExporter>().buildCollectionSlipPdf(
      collection: collection,
      factoryProfile: profile,
      logoBytes: logoBytes,
      factoryName: factoryName,
    );
    await ExportActions.sharePdf(
      document: doc,
      filename: '${collection.collectionNumber}-slip.pdf',
      sharePositionOrigin: shareOrigin,
    );
  }

  Future<void> _printPdf(
    BuildContext context, {
    required JobWorkCollection collection,
  }) async {
    final factoryName = await resolveExportFactoryName(context);
    final factoryRepo = getIt.isRegistered<FactoryRepository>()
        ? getIt<FactoryRepository>()
        : null;
    final profile = factoryRepo != null && collection.factoryId.isNotEmpty
        ? await factoryRepo.getFactory(collection.factoryId)
        : null;

    Uint8List? logoBytes;
    try {
      final byteData = await rootBundle.load('assets/images/app_logo.png');
      logoBytes = byteData.buffer.asUint8List();
    } catch (_) {}

    final doc =
        await getIt<JobWorkCollectionSlipPdfExporter>().buildCollectionSlipPdf(
      collection: collection,
      factoryProfile: profile,
      logoBytes: logoBytes,
      factoryName: factoryName,
    );
    await ExportActions.printPdf(
      document: doc,
      filename: '${collection.collectionNumber}-slip.pdf',
    );
  }
}

class _SlipRow extends StatelessWidget {
  const _SlipRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlipItemsTable extends StatelessWidget {
  const _SlipItemsTable({required this.collection});

  final JobWorkCollection collection;

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 11,
        );
    final cellStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 12,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(AppStrings.stockSize, style: headerStyle),
                ),
                Expanded(
                  child: Text(
                    AppStrings.collectPiecesShort,
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    AppStrings.collectSquareFeetShort,
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final item in collection.lineItems) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(item.displayLabel, style: cellStyle),
                  ),
                  Expanded(
                    child: Text(
                      '${item.pieces}',
                      style: cellStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.squareFeet.toStringAsFixed(2),
                      style: cellStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _SignatureBlock extends StatelessWidget {
  const _SignatureBlock({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 36,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(
                      alpha: 0.45,
                    ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/job_work_collection_repository.dart';
import '../../../data/services/export/job_work_collection_slip_pdf_exporter.dart';
import '../../../domain/entities/job_work_collection.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../utils/export_actions.dart';
import '../../utils/export_factory_name.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/export_menu_button.dart';

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
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.collectionSlipTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _SlipRow(
                        label: AppStrings.slipNumber,
                        value: collection.collectionNumber,
                      ),
                      _SlipRow(
                        label: AppStrings.jobWorkNumber,
                        value: collection.jobWorkNumber,
                      ),
                      _SlipRow(
                        label: AppStrings.customers,
                        value: collection.customerName,
                      ),
                      _SlipRow(
                        label: AppStrings.collectionDate,
                        value: DateFormat.yMMMd().format(collection.collectedAt),
                      ),
                      _SlipRow(
                        label: AppStrings.statusLabel,
                        value: collection.status.label,
                      ),
                      if (collection.receiverName != null &&
                          collection.receiverName!.isNotEmpty)
                        _SlipRow(
                          label: AppStrings.receiverName,
                          value: collection.receiverName!,
                        ),
                      if (collection.notes != null &&
                          collection.notes!.isNotEmpty)
                        _SlipRow(
                          label: AppStrings.notes,
                          value: collection.notes!,
                        ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.itemsCollected,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _SlipItemsTable(collection: collection),
                      const SizedBox(height: 16),
                      _SlipRow(
                        label: AppStrings.totalPieces,
                        value: '${collection.totalPieces}',
                      ),
                      _SlipRow(
                        label: AppStrings.totalSquareFeet,
                        value: collection.totalSquareFeet.toStringAsFixed(2),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: _SignatureBlock(
                              label: AppStrings.factorySignature,
                            ),
                          ),
                          const SizedBox(width: 16),
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
    final doc =
        await getIt<JobWorkCollectionSlipPdfExporter>().buildCollectionSlipPdf(
      collection: collection,
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
    final doc =
        await getIt<JobWorkCollectionSlipPdfExporter>().buildCollectionSlipPdf(
      collection: collection,
      factoryName: factoryName,
    );
    await ExportActions.printPdf(
      document: doc,
      filename: '${collection.collectionNumber}-slip.pdf',
    );
  }
}

class _SlipRow extends StatelessWidget {
  const _SlipRow({required this.label, required this.value});

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
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
              ),
        ),
      ],
    );
  }
}

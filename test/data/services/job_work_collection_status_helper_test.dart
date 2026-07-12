import 'package:factory_management/data/services/job_work_collection_quantity_helper.dart';
import 'package:factory_management/data/services/job_work_collection_status_helper.dart';
import 'package:factory_management/domain/entities/job_work_collection.dart';
import 'package:factory_management/domain/entities/job_work_load.dart';
import 'package:factory_management/domain/entities/job_work_order.dart';
import 'package:factory_management/domain/entities/job_work_output.dart';
import 'package:factory_management/domain/entities/stock_output.dart';
import 'package:factory_management/domain/enums/customer_enums.dart';
import 'package:factory_management/domain/enums/job_work_collection_enums.dart';
import 'package:factory_management/domain/enums/job_work_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  JobWorkOrder buildOrder({
    JobWorkStatus status = JobWorkStatus.ready,
    JobWorkOutput? output,
    String? invoiceId,
  }) {
    return JobWorkOrder(
      id: 'jw-1',
      jobWorkNumber: 'JW-001',
      factoryId: 'factory-1',
      customerId: 'customer-1',
      customerName: 'Customer',
      status: status,
      receivedDate: DateTime(2026, 1, 1),
      marbleVariety: 'Black Galaxy',
      blockCount: 1,
      totalTons: 10,
      cuttingStrategy: CuttingStrategy.bridgeSaw,
      targetProduct: TargetProduct.tiles,
      thickness: '18mm',
      finish: FinishType.polished,
      pricingModel: PricingModel.perSqFt,
      agreedRate: 50,
      advanceReceived: 0,
      balanceDue: 0,
      paymentTerms: PaymentTerms.cash,
      createdAt: DateTime(2026, 1, 1),
      output: output,
      invoiceId: invoiceId,
    );
  }

  const output = JobWorkOutput(
    smallStockOutputs: [
      StockOutput(size: '12x12', pieces: 100, squareFeet: 100),
    ],
    recordedAt: null,
  );

  JobWorkCollection buildCollection({required int pieces}) {
    return JobWorkCollection(
      id: 'col-1',
      collectionNumber: 'JC-1',
      factoryId: 'factory-1',
      jobWorkOrderId: 'jw-1',
      jobWorkNumber: 'JW-001',
      customerId: 'customer-1',
      customerName: 'Customer',
      collectedAt: DateTime(2026, 7, 1),
      status: JobWorkCollectionStatus.collected,
      lineItems: [
        JobWorkCollectionLineItem(
          size: '12x12',
          pieces: pieces,
          squareFeet: pieces.toDouble(),
        ),
      ],
      createdAt: DateTime(2026, 7, 1),
    );
  }

  group('JobWorkCollectionStatusHelper', () {
    test('inCutting + partial → partiallyCollected when output exists', () {
      final order = buildOrder(
        status: JobWorkStatus.inCutting,
        output: output,
      );
      expect(
        JobWorkCollectionStatusHelper.resolveTargetStatus(
          order: order,
          collections: [buildCollection(pieces: 40)],
        ),
        JobWorkStatus.partiallyCollected,
      );
    });

    test('qc + partial → partiallyCollected when output exists', () {
      final order = buildOrder(
        status: JobWorkStatus.qc,
        output: output,
      );
      expect(
        JobWorkCollectionStatusHelper.resolveTargetStatus(
          order: order,
          collections: [buildCollection(pieces: 40)],
        ),
        JobWorkStatus.partiallyCollected,
      );
    });

    test('inCutting without produced stock stays unchanged', () {
      final order = buildOrder(status: JobWorkStatus.inCutting);
      expect(
        JobWorkCollectionStatusHelper.resolveTargetStatus(
          order: order,
          collections: [buildCollection(pieces: 40)],
        ),
        isNull,
      );
    });

    test('received stays protected from collection sync', () {
      final order = buildOrder(
        status: JobWorkStatus.received,
        output: output,
      );
      expect(
        JobWorkCollectionStatusHelper.resolveTargetStatus(
          order: order,
          collections: [buildCollection(pieces: 40)],
        ),
        isNull,
      );
    });

    test('ready + partial → partiallyCollected', () {
      final order = buildOrder(status: JobWorkStatus.ready, output: output);
      expect(
        JobWorkCollectionStatusHelper.resolveTargetStatus(
          order: order,
          collections: [buildCollection(pieces: 40)],
        ),
        JobWorkStatus.partiallyCollected,
      );
    });

    test('paid + full → collected', () {
      final order = buildOrder(status: JobWorkStatus.paid, output: output);
      expect(
        JobWorkCollectionStatusHelper.resolveTargetStatus(
          order: order,
          collections: [buildCollection(pieces: 100)],
        ),
        JobWorkStatus.collected,
      );
    });

    test('partiallyCollected + full → collected', () {
      final order = buildOrder(
        status: JobWorkStatus.partiallyCollected,
        output: output,
      );
      expect(
        JobWorkCollectionStatusHelper.resolveTargetStatus(
          order: order,
          collections: [buildCollection(pieces: 100)],
        ),
        JobWorkStatus.collected,
      );
    });

    test('invoiced + partial → partiallyCollected', () {
      final order = buildOrder(
        status: JobWorkStatus.invoiced,
        output: output,
        invoiceId: 'inv-1',
      );
      expect(
        JobWorkCollectionStatusHelper.resolveTargetStatus(
          order: order,
          collections: [buildCollection(pieces: 10)],
        ),
        JobWorkStatus.partiallyCollected,
      );
    });
  });

  group('completion path', () {
    test('Mark Material Collected is retired from nextCompletionStatus', () {
      expect(JobWorkStatus.paid.nextCompletionStatus, isNull);
      expect(
        JobWorkStatus.collected.nextCompletionStatus,
        JobWorkStatus.closed,
      );
    });

    test('partiallyCollected can still collect material', () {
      expect(JobWorkStatus.partiallyCollected.canCollectMaterial, isTrue);
      expect(
        JobWorkCollectionQuantityHelper.canOpenCollectMaterial(
          buildOrder(
            status: JobWorkStatus.partiallyCollected,
            output: output,
          ),
          [buildCollection(pieces: 40)],
        ),
        isTrue,
      );
    });
  });

  group('resolveTargetStatusForLoad', () {
    test('ready + partial → partiallyCollected on Load only', () {
      final load = JobWorkLoad.fromLegacyOrder(
        buildOrder(status: JobWorkStatus.ready, output: output),
        id: 'load-1',
        loadNumber: 'JWL-1',
      ).copyWith(status: JobWorkStatus.ready, output: output);

      expect(
        JobWorkCollectionStatusHelper.resolveTargetStatusForLoad(
          load: load,
          collections: [
            buildCollection(pieces: 40).copyWith(
              loadId: 'load-1',
              loadNumber: 'JWL-1',
            ),
          ],
        ),
        JobWorkStatus.partiallyCollected,
      );
    });

    test('inCutting + partial → partiallyCollected on Load', () {
      final load = JobWorkLoad.fromLegacyOrder(
        buildOrder(status: JobWorkStatus.inCutting, output: output),
        id: 'load-1',
        loadNumber: 'JWL-1',
      ).copyWith(status: JobWorkStatus.inCutting, output: output);

      expect(
        JobWorkCollectionStatusHelper.resolveTargetStatusForLoad(
          load: load,
          collections: [
            buildCollection(pieces: 40).copyWith(
              loadId: 'load-1',
              loadNumber: 'JWL-1',
            ),
          ],
        ),
        JobWorkStatus.partiallyCollected,
      );
    });

    test('ready + full → collected on Load', () {
      final load = JobWorkLoad.fromLegacyOrder(
        buildOrder(status: JobWorkStatus.ready, output: output),
        id: 'load-1',
        loadNumber: 'JWL-1',
      ).copyWith(status: JobWorkStatus.ready, output: output);

      expect(
        JobWorkCollectionStatusHelper.resolveTargetStatusForLoad(
          load: load,
          collections: [
            buildCollection(pieces: 100).copyWith(
              loadId: 'load-1',
              loadNumber: 'JWL-1',
            ),
          ],
        ),
        JobWorkStatus.collected,
      );
    });
  });
}
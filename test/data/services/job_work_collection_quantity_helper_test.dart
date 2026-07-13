import 'package:factory_management/data/services/job_work_collection_quantity_helper.dart';
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
    JobWorkStatus status = JobWorkStatus.inCutting,
    JobWorkOutput? output,
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
    );
  }

  JobWorkCollection buildCollection({
    required List<JobWorkCollectionLineItem> lineItems,
  }) {
    return JobWorkCollection(
      id: 'col-1',
      collectionNumber: 'JC-2026-0001',
      factoryId: 'factory-1',
      jobWorkOrderId: 'jw-1',
      jobWorkNumber: 'JW-001',
      customerId: 'customer-1',
      customerName: 'Customer',
      collectedAt: DateTime(2026, 7, 1),
      status: JobWorkCollectionStatus.collected,
      lineItems: lineItems,
      createdAt: DateTime(2026, 7, 1),
    );
  }

  group('JobWorkStatus.canCollectMaterial', () {
    test('allows from inCutting through paid and partiallyCollected', () {
      expect(JobWorkStatus.inCutting.canCollectMaterial, isTrue);
      expect(JobWorkStatus.qc.canCollectMaterial, isTrue);
      expect(JobWorkStatus.ready.canCollectMaterial, isTrue);
      expect(JobWorkStatus.invoiced.canCollectMaterial, isTrue);
      expect(JobWorkStatus.paid.canCollectMaterial, isTrue);
      expect(JobWorkStatus.partiallyCollected.canCollectMaterial, isTrue);
    });

    test('blocks before cutting and after collected', () {
      expect(JobWorkStatus.agreed.canCollectMaterial, isFalse);
      expect(JobWorkStatus.received.canCollectMaterial, isFalse);
      expect(JobWorkStatus.collected.canCollectMaterial, isFalse);
      expect(JobWorkStatus.closed.canCollectMaterial, isFalse);
      expect(JobWorkStatus.cancelled.canCollectMaterial, isFalse);
    });
  });

  group('JobWorkCollectionQuantityHelper', () {
    final output = JobWorkOutput(
      smallStockOutputs: const [
        StockOutput(size: '12x12', pieces: 100, squareFeet: 100),
      ],
      largeStockOutputs: const [
        StockOutput(size: '24x24', pieces: 40, squareFeet: 160),
      ],
      recordedAt: DateTime(2026, 6, 1),
    );

    test('computes remaining after partial collection', () {
      final order = buildOrder(output: output);
      final collections = [
        buildCollection(
          lineItems: const [
            JobWorkCollectionLineItem(
              size: '12x12',
              pieces: 30,
              squareFeet: 30,
            ),
          ],
        ),
      ];

      final totals =
          JobWorkCollectionQuantityHelper.orderTotals(order, collections);
      expect(totals.totalPieces, 140);
      expect(totals.collectedPieces, 30);
      expect(totals.remainingPieces, 110);

      final remaining =
          JobWorkCollectionQuantityHelper.remainingLines(order, collections);
      expect(remaining.length, 2);
      final small = remaining.firstWhere((line) => line.size == '12x12');
      expect(small.remainingPieces, 70);
    });

    test('canOpenCollectMaterial requires status and remaining stock', () {
      final order = buildOrder(
        status: JobWorkStatus.inCutting,
        output: output,
      );
      expect(
        JobWorkCollectionQuantityHelper.canOpenCollectMaterial(order, const []),
        isTrue,
      );
      expect(
        JobWorkCollectionQuantityHelper.isPendingPickup(order, const []),
        isTrue,
      );

      final agreed = buildOrder(status: JobWorkStatus.agreed, output: output);
      expect(
        JobWorkCollectionQuantityHelper.canOpenCollectMaterial(
          agreed,
          const [],
        ),
        isFalse,
      );

      final fullyCollected = [
        buildCollection(
          lineItems: const [
            JobWorkCollectionLineItem(
              size: '12x12',
              pieces: 100,
              squareFeet: 100,
            ),
            JobWorkCollectionLineItem(
              size: '24x24',
              pieces: 40,
              squareFeet: 160,
            ),
          ],
        ),
      ];
      expect(
        JobWorkCollectionQuantityHelper.canOpenCollectMaterial(
          order,
          fullyCollected,
        ),
        isFalse,
      );
      expect(
        JobWorkCollectionQuantityHelper.isPendingPickup(order, fullyCollected),
        isFalse,
      );
    });

    test('pickup overdue uses remaining + wait clock, not updatedAt', () {
      final readyOrder = buildOrder(
        status: JobWorkStatus.ready,
        output: output,
      ).copyWith(
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 7, 9),
        execution: JobWorkExecution(
          cuttingCompletionDate: DateTime(2026, 6, 20),
        ),
      );

      expect(
        JobWorkCollectionQuantityHelper.isPickupOverdue(
          readyOrder,
          const [],
          reference: DateTime(2026, 7, 10),
        ),
        isTrue,
      );
      expect(
        JobWorkCollectionQuantityHelper.pickupDaysWaiting(
          readyOrder,
          const [],
          reference: DateTime(2026, 7, 10),
        ),
        20,
      );

      // Mid-cutting with remaining is pending but not customer-facing overdue.
      final cuttingOrder = buildOrder(
        status: JobWorkStatus.inCutting,
        output: output,
      ).copyWith(createdAt: DateTime(2026, 1, 1));
      expect(
        JobWorkCollectionQuantityHelper.isPendingPickup(cuttingOrder, const []),
        isTrue,
      );
      expect(
        JobWorkCollectionQuantityHelper.isPickupOverdue(
          cuttingOrder,
          const [],
          reference: DateTime(2026, 7, 10),
        ),
        isFalse,
      );

      // Partial collection resets wait clock to last collectedAt.
      final partial = [
        buildCollection(
          lineItems: const [
            JobWorkCollectionLineItem(
              size: '12x12',
              pieces: 40,
              squareFeet: 40,
            ),
          ],
        ).copyWith(collectedAt: DateTime(2026, 7, 5)),
      ];
      final partialOrder = buildOrder(
        status: JobWorkStatus.partiallyCollected,
        output: output,
      );
      expect(
        JobWorkCollectionQuantityHelper.isPickupOverdue(
          partialOrder,
          partial,
          reference: DateTime(2026, 7, 10),
        ),
        isFalse,
      );
      expect(
        JobWorkCollectionQuantityHelper.isPickupOverdue(
          partialOrder,
          partial,
          reference: DateTime(2026, 7, 13),
        ),
        isTrue,
      );
    });

    test('remaining and collect eligibility are scoped per Load', () {
      final loadA = JobWorkLoad.fromLegacyOrder(
        buildOrder(status: JobWorkStatus.ready, output: null),
        id: 'load-a',
        loadNumber: 'JWL-A',
        loadSequence: 1,
      ).copyWith(
        status: JobWorkStatus.ready,
        output: JobWorkOutput(
          smallStockOutputs: const [
            StockOutput(size: '12x12', pieces: 100, squareFeet: 100),
          ],
          recordedAt: DateTime(2026, 6, 1),
        ),
      );
      final loadB = JobWorkLoad.fromLegacyOrder(
        buildOrder(status: JobWorkStatus.ready, output: null),
        id: 'load-b',
        loadNumber: 'JWL-B',
        loadSequence: 2,
      ).copyWith(
        status: JobWorkStatus.ready,
        output: JobWorkOutput(
          smallStockOutputs: const [
            StockOutput(size: '12x12', pieces: 50, squareFeet: 50),
          ],
          recordedAt: DateTime(2026, 6, 1),
        ),
      );

      final collections = [
        buildCollection(
          lineItems: const [
            JobWorkCollectionLineItem(
              size: '12x12',
              pieces: 40,
              squareFeet: 40,
            ),
          ],
        ).copyWith(loadId: 'load-a', loadNumber: 'JWL-A'),
      ];

      final totalsA =
          JobWorkCollectionQuantityHelper.loadTotals(loadA, collections);
      expect(totalsA.collectedPieces, 40);
      expect(totalsA.remainingPieces, 60);

      final totalsB =
          JobWorkCollectionQuantityHelper.loadTotals(loadB, collections);
      expect(totalsB.collectedPieces, 0);
      expect(totalsB.remainingPieces, 50);

      expect(
        JobWorkCollectionQuantityHelper.canOpenCollectMaterialForLoad(
          loadA,
          collections,
        ),
        isTrue,
      );
      expect(
        JobWorkCollectionQuantityHelper.isPendingPickupForOrder(
          order: buildOrder(status: JobWorkStatus.ready),
          collections: collections,
          loads: [loadA, loadB],
        ),
        isTrue,
      );

      final fullyA = [
        collections.first.copyWith(
          lineItems: const [
            JobWorkCollectionLineItem(
              size: '12x12',
              pieces: 100,
              squareFeet: 100,
            ),
          ],
        ),
      ];
      expect(
        JobWorkCollectionQuantityHelper.canOpenCollectMaterialForLoad(
          loadA,
          fullyA,
        ),
        isFalse,
      );
      expect(
        JobWorkCollectionQuantityHelper.canOpenCollectMaterialForLoad(
          loadB,
          fullyA,
        ),
        isTrue,
      );
    });

    test('displayStatusForOrder prefers Load collection statuses', () {
      final order = buildOrder(status: JobWorkStatus.ready);
      final readyLoad = JobWorkLoad.fromLegacyOrder(
        order,
        id: 'load-ready',
        loadNumber: 'JWL-R',
        loadSequence: 1,
      ).copyWith(status: JobWorkStatus.ready);
      final partialLoad = JobWorkLoad.fromLegacyOrder(
        order,
        id: 'load-partial',
        loadNumber: 'JWL-P',
        loadSequence: 2,
      ).copyWith(status: JobWorkStatus.partiallyCollected);

      expect(
        JobWorkCollectionQuantityHelper.displayStatusForOrder(
          order: order,
          loads: [readyLoad, partialLoad],
        ),
        JobWorkStatus.partiallyCollected,
      );

      final collectedLoads = [
        readyLoad.copyWith(status: JobWorkStatus.collected),
        partialLoad.copyWith(status: JobWorkStatus.collected),
      ];
      expect(
        JobWorkCollectionQuantityHelper.displayStatusForOrder(
          order: order,
          loads: collectedLoads,
        ),
        JobWorkStatus.collected,
      );

      expect(
        JobWorkCollectionQuantityHelper.displayStatusForOrder(
          order: order.copyWith(status: JobWorkStatus.cancelled),
          loads: [readyLoad],
        ),
        JobWorkStatus.cancelled,
      );

      expect(
        JobWorkCollectionQuantityHelper.displayStatusForOrder(
          order: order,
          loads: const [],
        ),
        JobWorkStatus.ready,
      );
    });

    test('zero remaining pieces clears sq.ft rounding dust', () {
      final dustOutput = JobWorkOutput(
        smallStockOutputs: const [
          StockOutput(size: '4x24', pieces: 270, squareFeet: 180.01),
        ],
        recordedAt: DateTime(2026, 6, 1),
      );
      final order = buildOrder(output: dustOutput);
      final collections = [
        buildCollection(
          lineItems: const [
            // Recomputed sq.ft from pieces leaves 0.01 against produced 180.01.
            JobWorkCollectionLineItem(
              size: '4x24',
              pieces: 270,
              squareFeet: 180.00,
            ),
          ],
        ),
      ];

      final totals =
          JobWorkCollectionQuantityHelper.orderTotals(order, collections);
      expect(totals.remainingPieces, 0);
      expect(totals.remainingSquareFeet, 0);
      expect(totals.isFullyCollected, isTrue);
      expect(
        JobWorkCollectionQuantityHelper.remainingLines(order, collections),
        isEmpty,
      );
      expect(
        JobWorkCollectionQuantityHelper.canOpenCollectMaterial(
          order,
          collections,
        ),
        isFalse,
      );
    });
  });
}

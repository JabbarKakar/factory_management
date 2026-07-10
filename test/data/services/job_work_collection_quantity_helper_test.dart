import 'package:factory_management/data/services/job_work_collection_quantity_helper.dart';
import 'package:factory_management/domain/entities/job_work_collection.dart';
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
    });
  });
}

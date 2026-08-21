import 'package:factory_management/core/utils/job_work_collection_slip_totals.dart';
import 'package:factory_management/domain/entities/job_work_collection.dart';
import 'package:factory_management/domain/entities/job_work_order.dart';
import 'package:factory_management/domain/enums/customer_enums.dart';
import 'package:factory_management/domain/enums/job_work_collection_enums.dart';
import 'package:factory_management/domain/enums/job_work_enums.dart';
import 'package:flutter_test/flutter_test.dart';

JobWorkCollection _collection(
  List<JobWorkCollectionLineItem> items,
) {
  return JobWorkCollection(
    id: 'col-1',
    collectionNumber: 'JC-1',
    factoryId: 'factory-1',
    jobWorkOrderId: 'jw-1',
    jobWorkNumber: 'JW-1',
    customerId: 'cust-1',
    customerName: 'Customer',
    collectedAt: DateTime(2026, 8, 21),
    status: JobWorkCollectionStatus.collected,
    lineItems: items,
    createdAt: DateTime(2026, 8, 21),
  );
}

JobWorkOrder _order({
  double smallStockPrice = 20,
  double largeStockPrice = 40,
}) {
  return JobWorkOrder(
    id: 'jw-1',
    jobWorkNumber: 'JW-1',
    factoryId: 'factory-1',
    customerId: 'cust-1',
    customerName: 'Customer',
    status: JobWorkStatus.ready,
    receivedDate: DateTime(2026, 1, 1),
    marbleVariety: 'Travertine',
    blockCount: 1,
    totalTons: 10,
    cuttingStrategy: CuttingStrategy.gangSaw,
    targetProduct: TargetProduct.sizeCutting,
    thickness: '2 cm',
    finish: FinishType.polished,
    pricingModel: PricingModel.perSqFt,
    agreedRate: 0,
    smallStockPrice: smallStockPrice,
    largeStockPrice: largeStockPrice,
    advanceReceived: 0,
    balanceDue: 0,
    paymentTerms: PaymentTerms.cash,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('JobWorkCollectionSlipTotals', () {
    test('splits catalog sizes and sums feet and amounts', () {
      final totals = JobWorkCollectionSlipTotals.fromCollection(
        collection: _collection(const [
          JobWorkCollectionLineItem(
            size: '4x12',
            pieces: 10,
            squareFeet: 3.33,
            isSmall: true,
          ),
          JobWorkCollectionLineItem(
            size: '6x24',
            pieces: 5,
            squareFeet: 5,
            isSmall: true,
          ),
          JobWorkCollectionLineItem(
            size: '12x36',
            pieces: 8,
            squareFeet: 24,
            isSmall: false,
          ),
        ]),
        order: _order(),
      );

      expect(totals.smallItems.map((item) => item.size), ['4x12', '6x24']);
      expect(totals.largeItems.map((item) => item.size), ['12x36']);
      expect(totals.smallSqFt, closeTo(8.33, 0.001));
      expect(totals.largeSqFt, 24);
      expect(totals.smallAmount, closeTo(8.33 * 20, 0.001));
      expect(totals.largeAmount, 24 * 40);
      expect(totals.grandAmount, closeTo((8.33 * 20) + (24 * 40), 0.001));
    });

    test('treats 12x catalog sizes as large even if isSmall is true', () {
      final totals = JobWorkCollectionSlipTotals.fromCollection(
        collection: _collection(const [
          JobWorkCollectionLineItem(
            size: '12x12',
            pieces: 100,
            squareFeet: 100,
            isSmall: true,
          ),
        ]),
        order: _order(),
      );

      expect(totals.smallItems, isEmpty);
      expect(totals.largeSqFt, 100);
      expect(totals.largeAmount, 4000);
      expect(totals.grandAmount, 4000);
    });
  });
}

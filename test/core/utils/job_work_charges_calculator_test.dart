import 'package:flutter_test/flutter_test.dart';

import 'package:factory_management/core/utils/job_work_charges_calculator.dart';
import 'package:factory_management/core/utils/stock_output_calculator.dart';
import 'package:factory_management/domain/entities/job_work_order.dart';
import 'package:factory_management/domain/entities/job_work_output.dart';
import 'package:factory_management/domain/enums/customer_enums.dart';
import 'package:factory_management/domain/enums/job_work_enums.dart';

JobWorkOrder _baseOrder() {
  return JobWorkOrder(
    id: 'jw-1',
    jobWorkNumber: 'JW-2026-0001',
    factoryId: 'factory-1',
    customerId: 'customer-1',
    customerName: 'Test Customer',
    status: JobWorkStatus.inCutting,
    receivedDate: DateTime(2026, 1, 1),
    marbleVariety: 'Travertine',
    blockCount: 10,
    totalTons: 50,
    cuttingStrategy: CuttingStrategy.gangSaw,
    targetProduct: TargetProduct.sizeCutting,
    smallSizes: const ['4x12'],
    thickness: '2 cm',
    finish: FinishType.polished,
    pricingModel: PricingModel.perSqFt,
    agreedRate: 73,
    smallStockPrice: 73,
    advanceReceived: 0,
    balanceDue: 0,
    paymentTerms: PaymentTerms.cash,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('multi-shift final cutting charges', () {
    test('sums grand totals from every shift', () {
      final shiftOne = JobWorkShiftLog.create(
        shiftDate: DateTime(2026, 7, 1),
        shiftName: 'Day (AM)',
        smallStockOutputs: [
          StockOutputCalculator.compute(
            size: '4x12',
            pieces: 100,
            pricePerSqFt: 73,
          ),
        ],
      );
      final shiftTwo = JobWorkShiftLog.create(
        shiftDate: DateTime(2026, 7, 2),
        shiftName: 'Night (PM)',
        smallStockOutputs: [
          StockOutputCalculator.compute(
            size: '4x12',
            pieces: 80,
            pricePerSqFt: 73,
          ),
        ],
      );

      final output = JobWorkOutput.aggregateFromShifts([shiftOne, shiftTwo]);
      final charges = JobWorkChargesCalculator.calculate(
        order: _baseOrder(),
        output: output,
        shiftLogs: [shiftOne, shiftTwo],
      );

      final expected = shiftOne.grandCuttingTotal + shiftTwo.grandCuttingTotal;
      expect(charges, closeTo(expected, 0.01));
      expect(output.grandCuttingTotal, closeTo(expected, 0.01));
    });

    test('aggregated output matches sum of non-overlapping shift stocks', () {
      final shiftOne = JobWorkShiftLog.create(
        shiftDate: DateTime(2026, 7, 1),
        smallStockOutputs: [
          StockOutputCalculator.compute(
            size: '4x12',
            pieces: 20,
            pricePerSqFt: 73,
          ),
        ],
      );
      final shiftTwo = JobWorkShiftLog.create(
        shiftDate: DateTime(2026, 7, 2),
        smallStockOutputs: [
          StockOutputCalculator.compute(
            size: '6x36',
            pieces: 15,
            pricePerSqFt: 73,
          ),
        ],
      );

      final output = JobWorkOutput.aggregateFromShifts([shiftOne, shiftTwo]);
      final charges = JobWorkChargesCalculator.calculate(
        order: _baseOrder(),
        output: output,
        shiftLogs: [shiftOne, shiftTwo],
      );

      expect(
        charges,
        closeTo(shiftOne.grandCuttingTotal + shiftTwo.grandCuttingTotal, 0.01),
      );
    });
  });
}

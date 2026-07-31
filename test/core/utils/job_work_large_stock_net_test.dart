import 'package:factory_management/core/utils/job_work_large_stock_net.dart';
import 'package:factory_management/domain/entities/stock_output.dart';
import 'package:factory_management/domain/enums/job_work_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JobWorkLargeStockNet', () {
    final large = [
      const StockOutput(
        size: '12x24',
        pieces: 50,
        squareFeet: 100,
        pricePerSqFt: 40,
        amount: 4000,
      ),
      const StockOutput(
        size: '16x24',
        pieces: 10,
        squareFeet: 26.67,
        pricePerSqFt: 40,
        amount: 1066.8,
      ),
    ];

    test('does not deduct when waste unit is tons', () {
      final net = JobWorkLargeStockNet.netSquareFeet(
        largeOutputs: large,
        wasteAmount: 10,
        yieldAmount: 5,
        wasteUnit: WasteUnit.tons,
      );
      expect(net, JobWorkLargeStockNet.grossSquareFeet(large));
    });

    test('deducts waste + yield from large stock when unit is sq.ft', () {
      final gross = JobWorkLargeStockNet.grossSquareFeet(large);
      final net = JobWorkLargeStockNet.netSquareFeet(
        largeOutputs: large,
        wasteAmount: 10,
        yieldAmount: 5,
        wasteUnit: WasteUnit.sqFt,
      );
      expect(net, closeTo(gross - 15, 0.01));
    });

    test('scales net amount by net/gross ratio', () {
      final netAmt = JobWorkLargeStockNet.netAmount(
        largeOutputs: large,
        wasteAmount: 10,
        yieldAmount: 5,
        wasteUnit: WasteUnit.sqFt,
      );
      final grossAmt = JobWorkLargeStockNet.grossAmount(large);
      final grossSq = JobWorkLargeStockNet.grossSquareFeet(large);
      expect(netAmt, closeTo(grossAmt * ((grossSq - 15) / grossSq), 0.05));
    });

    test('flags when waste + yield exceeds gross large', () {
      expect(
        JobWorkLargeStockNet.deductionExceedsGross(
          largeOutputs: large,
          wasteAmount: 200,
          yieldAmount: 50,
          wasteUnit: WasteUnit.sqFt,
        ),
        isTrue,
      );
      expect(
        JobWorkLargeStockNet.deductionExceedsGross(
          largeOutputs: large,
          wasteAmount: 5,
          yieldAmount: 5,
          wasteUnit: WasteUnit.sqFt,
        ),
        isFalse,
      );
    });
  });
}

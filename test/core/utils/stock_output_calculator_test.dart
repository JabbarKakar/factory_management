import 'package:flutter_test/flutter_test.dart';

import 'package:factory_management/core/utils/stock_output_calculator.dart';

void main() {
  group('StockOutputCalculator', () {
    test('computes square feet per 4x12 piece', () {
      expect(StockOutputCalculator.squareFeetPerPiece('4x12'), closeTo(0.33, 0.01));
    });

    test('computes total square feet and amount for multiple pieces', () {
      final output = StockOutputCalculator.compute(
        size: '4x12',
        pieces: 100,
        pricePerSqFt: 45,
      );

      expect(output.squareFeet, closeTo(33.33, 0.01));
      expect(output.amount, closeTo(1499.85, 0.01));
    });

    test('computes 12x24 at 50 pieces', () {
      final output = StockOutputCalculator.compute(
        size: '12x24',
        pieces: 50,
        pricePerSqFt: 45,
      );

      expect(output.squareFeet, 100);
      expect(output.amount, 4500);
    });

    test('rejects negative pieces and prices', () {
      final output = StockOutputCalculator.compute(
        size: '4x12',
        pieces: -5,
        pricePerSqFt: -10,
      );

      expect(output.pieces, 0);
      expect(output.pricePerSqFt, 0);
      expect(output.squareFeet, 0);
      expect(output.amount, 0);
    });
  });
}

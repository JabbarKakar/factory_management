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

    test('computeFromSquareFeet keeps entered sq ft and derives pieces/amount',
        () {
      final output = StockOutputCalculator.computeFromSquareFeet(
        size: '4x12',
        squareFeet: 45,
        pricePerSqFt: 80,
      );

      expect(output.squareFeet, 45);
      expect(output.pieces, 136); // 45 / 0.33 rounded
      expect(output.amount, 3600); // 45 * 80
    });

    test('computeFromSquareFeet totals match sum of entered values', () {
      final a = StockOutputCalculator.computeFromSquareFeet(
        size: '4x12',
        squareFeet: 45,
        pricePerSqFt: 80,
      );
      final b = StockOutputCalculator.computeFromSquareFeet(
        size: '4x24',
        squareFeet: 45,
        pricePerSqFt: 80,
      );
      final c = StockOutputCalculator.computeFromSquareFeet(
        size: '4x36',
        squareFeet: 23,
        pricePerSqFt: 80,
      );

      expect(
        StockOutputCalculator.totalSquareFeet([a, b, c]),
        113,
      );
      expect(
        StockOutputCalculator.grandTotal([a, b, c]),
        9040, // 113 * 80
      );
    });

    test('computeFromSquareFeet returns zero when sq ft is zero', () {
      final output = StockOutputCalculator.computeFromSquareFeet(
        size: '12x24',
        squareFeet: 0,
        pricePerSqFt: 80,
      );

      expect(output.pieces, 0);
      expect(output.squareFeet, 0);
      expect(output.amount, 0);
    });
  });
}

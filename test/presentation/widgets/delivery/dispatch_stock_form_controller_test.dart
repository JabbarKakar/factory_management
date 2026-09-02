import 'package:factory_management/domain/enums/sales_enums.dart';
import 'package:factory_management/presentation/widgets/delivery/dispatch_stock_form_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DispatchStockRow buildRow({
    int maxRemainingPieces = 10,
    int initialPieces = 0,
    int? initialPiecesDelivered,
  }) {
    return DispatchStockRow(
      productType: SalesProductType.tile,
      marbleVariety: 'Black Galaxy',
      size: '12x12',
      orderedPieces: 20,
      orderedSquareFeet: 20,
      maxRemainingPieces: maxRemainingPieces,
      maxRemainingSquareFeet: 20,
      initialPieces: initialPieces,
      initialPiecesDelivered: initialPiecesDelivered,
    );
  }

  group('DispatchStockRow excess', () {
    test('schedule exceeds when pieces are above remaining', () {
      final row = buildRow(maxRemainingPieces: 4, initialPieces: 5);
      expect(row.exceedsRemaining, isTrue);
      expect(row.exceedsScheduled, isFalse);
      row.dispose();
    });

    test('schedule does not exceed at remaining cap', () {
      final row = buildRow(maxRemainingPieces: 4, initialPieces: 4);
      expect(row.exceedsRemaining, isFalse);
      row.dispose();
    });

    test('confirm exceeds when delivered is above scheduled', () {
      final row = buildRow(
        maxRemainingPieces: 8,
        initialPieces: 3,
        initialPiecesDelivered: 4,
      );
      expect(row.exceedsScheduled, isTrue);
      expect(row.exceedsRemaining, isFalse);
      row.dispose();
    });
  });
}

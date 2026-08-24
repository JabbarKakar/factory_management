import 'package:factory_management/domain/enums/document_sequence.dart';
import 'package:factory_management/domain/enums/inventory_enums.dart';
import 'package:factory_management/domain/enums/raw_material_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DocumentSequence.format', () {
    test('pads to four digits', () {
      expect(
        DocumentSequence.jobWorkOrder.format(year: 2026, value: 1),
        'JW-2026-0001',
      );
      expect(
        DocumentSequence.jobWorkOrder.format(year: 2026, value: 842),
        'JW-2026-0842',
      );
    });

    test('keeps every digit past four', () {
      expect(
        DocumentSequence.salesInvoice.format(year: 2026, value: 12345),
        'INV-2026-12345',
      );
    });
  });

  group('DocumentSequence.highestIssued', () {
    test('returns 0 when nothing matches', () {
      expect(
        DocumentSequence.jobWorkOrder.highestIssued(year: 2026, numbers: []),
        0,
      );
    });

    test('picks the maximum regardless of order', () {
      expect(
        DocumentSequence.jobWorkOrder.highestIssued(
          year: 2026,
          numbers: ['JW-2026-0007', 'JW-2026-0112', 'JW-2026-0043'],
        ),
        112,
      );
    });

    test('ignores other years', () {
      expect(
        DocumentSequence.jobWorkOrder.highestIssued(
          year: 2026,
          numbers: ['JW-2025-9999', 'JW-2026-0003'],
        ),
        3,
      );
    });

    test('ignores malformed and hand-edited numbers', () {
      expect(
        DocumentSequence.jobWorkOrder.highestIssued(
          year: 2026,
          numbers: [
            'JW-2026-0004',
            'JW-2026-ABCD',
            'JW-2026',
            '',
            'legacy-JW-2026-9999',
            'JW-2026-0002-revised',
          ],
        ),
        4,
      );
    });

    test('tolerates surrounding whitespace', () {
      expect(
        DocumentSequence.jobWorkOrder
            .highestIssued(year: 2026, numbers: [' JW-2026-0021 ']),
        21,
      );
    });

    test('does not confuse INV with INV-IN', () {
      // Same year, prefixes where one is a prefix of the other.
      expect(
        DocumentSequence.salesInvoice.highestIssued(
          year: 2026,
          numbers: ['INV-IN-2026-0500'],
        ),
        0,
      );
      expect(
        DocumentSequence.finishedGoodProductionIn.highestIssued(
          year: 2026,
          numbers: ['INV-2026-0500'],
        ),
        0,
      );
    });

    test('separates the four raw-material movement series', () {
      const numbers = [
        'STK-IN-2026-0011',
        'STK-OUT-2026-0022',
        'STK-ADJ-IN-2026-0033',
        'STK-ADJ-OUT-2026-0044',
      ];
      expect(
        DocumentSequence.rawMaterialStockIn
            .highestIssued(year: 2026, numbers: numbers),
        11,
      );
      expect(
        DocumentSequence.rawMaterialStockOut
            .highestIssued(year: 2026, numbers: numbers),
        22,
      );
      expect(
        DocumentSequence.rawMaterialAdjustmentIn
            .highestIssued(year: 2026, numbers: numbers),
        33,
      );
      expect(
        DocumentSequence.rawMaterialAdjustmentOut
            .highestIssued(year: 2026, numbers: numbers),
        44,
      );
    });
  });

  group('sequence registry', () {
    test('counter keys are unique', () {
      final keys = DocumentSequence.values.map((s) => s.key).toSet();
      expect(keys, hasLength(DocumentSequence.values.length));
    });

    test('prefix is unique within a collection', () {
      final pairs = DocumentSequence.values
          .map((s) => '${s.collection}/${s.prefix}')
          .toSet();
      expect(pairs, hasLength(DocumentSequence.values.length));
    });

    test('a filter field and value are declared together', () {
      for (final sequence in DocumentSequence.values) {
        expect(
          sequence.filterField == null,
          sequence.filterValue == null,
          reason: '${sequence.key} declares only half of its filter',
        );
      }
    });
  });

  group('movement type mapping', () {
    test('stock movements map to the matching prefixes', () {
      expect(
        StockMovementType.stockIn.documentSequence.prefix,
        'STK-IN',
      );
      expect(
        StockMovementType.stockOut.documentSequence.prefix,
        'STK-OUT',
      );
      expect(
        StockMovementType.adjustmentIn.documentSequence.prefix,
        'STK-ADJ-IN',
      );
      expect(
        StockMovementType.adjustmentOut.documentSequence.prefix,
        'STK-ADJ-OUT',
      );
    });

    test('inventory movements map to the matching prefixes', () {
      expect(
        InventoryMovementType.productionIn.documentSequence.prefix,
        'INV-IN',
      );
      expect(
        InventoryMovementType.adjustmentIn.documentSequence.prefix,
        'INV-ADJ-IN',
      );
      expect(
        InventoryMovementType.adjustmentOut.documentSequence.prefix,
        'INV-ADJ-OUT',
      );
    });

    test('filter values match the enum values stored in Firestore', () {
      for (final type in StockMovementType.values) {
        expect(type.documentSequence.filterValue, type.firestoreValue);
      }
      for (final type in InventoryMovementType.values) {
        expect(type.documentSequence.filterValue, type.firestoreValue);
      }
    });
  });
}

import 'inventory_enums.dart';
import 'raw_material_enums.dart';

/// Every human-facing document number in the app.
///
/// Each value owns one counter document (`counters/{factoryId}__{key}`) and
/// knows how to find the numbers it already issued, so the seed migration can
/// resume an existing deployment without a hand-written table.
enum DocumentSequence {
  jobWorkOrder(
    key: 'jobWorkOrder',
    prefix: 'JW',
    collection: 'jobWorkOrders',
    numberField: 'jobWorkNumber',
  ),
  jobWorkLoad(
    key: 'jobWorkLoad',
    prefix: 'JWL',
    collection: 'jobWorkLoads',
    numberField: 'loadNumber',
  ),
  jobWorkInvoice(
    key: 'jobWorkInvoice',
    prefix: 'JWI',
    collection: 'jobWorkInvoices',
    numberField: 'invoiceNumber',
  ),
  jobWorkCollection(
    key: 'jobWorkCollection',
    prefix: 'JC',
    collection: 'jobWorkCollections',
    numberField: 'collectionNumber',
  ),
  salesAgreement(
    key: 'salesAgreement',
    prefix: 'SA',
    collection: 'salesAgreements',
    numberField: 'agreementNumber',
  ),
  salesOrder(
    key: 'salesOrder',
    prefix: 'ORD',
    collection: 'salesOrders',
    numberField: 'orderNumber',
  ),
  salesInvoice(
    key: 'salesInvoice',
    prefix: 'INV',
    collection: 'salesInvoices',
    numberField: 'invoiceNumber',
  ),
  delivery(
    key: 'delivery',
    prefix: 'DEL',
    collection: 'deliveries',
    numberField: 'deliveryNumber',
  ),
  expense(
    key: 'expense',
    prefix: 'EXP',
    collection: 'expenses',
    numberField: 'expenseNumber',
  ),
  supplier(
    key: 'supplier',
    prefix: 'SUP',
    collection: 'suppliers',
    numberField: 'supplierNumber',
  ),
  employee(
    key: 'employee',
    prefix: 'EMP',
    collection: 'employees',
    numberField: 'employeeNumber',
  ),
  equipment(
    key: 'equipment',
    prefix: 'EQP',
    collection: 'equipment',
    numberField: 'equipmentNumber',
  ),
  qualityCheck(
    key: 'qualityCheck',
    prefix: 'QC',
    collection: 'qualityChecks',
    numberField: 'qcNumber',
  ),
  productionBatch(
    key: 'productionBatch',
    prefix: 'PRD',
    collection: 'productionBatches',
    numberField: 'batchNumber',
  ),

  /// Raw-material stock movements. Production stock-out shares
  /// [rawMaterialStockOut] because it writes the same `STK-OUT` series into
  /// `stockTransactions`.
  rawMaterialStockIn(
    key: 'rawMaterialStockIn',
    prefix: 'STK-IN',
    collection: 'stockTransactions',
    numberField: 'transactionNumber',
    filterField: 'movementType',
    filterValue: 'stockIn',
  ),
  rawMaterialStockOut(
    key: 'rawMaterialStockOut',
    prefix: 'STK-OUT',
    collection: 'stockTransactions',
    numberField: 'transactionNumber',
    filterField: 'movementType',
    filterValue: 'stockOut',
  ),
  rawMaterialAdjustmentIn(
    key: 'rawMaterialAdjustmentIn',
    prefix: 'STK-ADJ-IN',
    collection: 'stockTransactions',
    numberField: 'transactionNumber',
    filterField: 'movementType',
    filterValue: 'adjustmentIn',
  ),
  rawMaterialAdjustmentOut(
    key: 'rawMaterialAdjustmentOut',
    prefix: 'STK-ADJ-OUT',
    collection: 'stockTransactions',
    numberField: 'transactionNumber',
    filterField: 'movementType',
    filterValue: 'adjustmentOut',
  ),

  finishedGoodProductionIn(
    key: 'finishedGoodProductionIn',
    prefix: 'INV-IN',
    collection: 'inventoryTransactions',
    numberField: 'transactionNumber',
    filterField: 'movementType',
    filterValue: 'productionIn',
  ),
  finishedGoodAdjustmentIn(
    key: 'finishedGoodAdjustmentIn',
    prefix: 'INV-ADJ-IN',
    collection: 'inventoryTransactions',
    numberField: 'transactionNumber',
    filterField: 'movementType',
    filterValue: 'adjustmentIn',
  ),
  finishedGoodAdjustmentOut(
    key: 'finishedGoodAdjustmentOut',
    prefix: 'INV-ADJ-OUT',
    collection: 'inventoryTransactions',
    numberField: 'transactionNumber',
    filterField: 'movementType',
    filterValue: 'adjustmentOut',
  );

  const DocumentSequence({
    required this.key,
    required this.prefix,
    required this.collection,
    required this.numberField,
    this.filterField,
    this.filterValue,
  });

  /// Stable identifier stored on the counter document. Never rename: doing so
  /// restarts the series at 1.
  final String key;

  /// Human-facing prefix, e.g. `JW` in `JW-2026-0001`.
  final String prefix;

  /// Collection the seed migration scans for already-issued numbers.
  final String collection;

  /// Field on that collection holding the formatted number.
  final String numberField;

  /// Optional equality filter, for collections that hold several series.
  final String? filterField;
  final String? filterValue;

  static const int padWidth = 4;

  String format({required int year, required int value}) =>
      '$prefix-$year-${value.toString().padLeft(padWidth, '0')}';

  /// Highest value already issued for [year], or 0 when [numbers] has none.
  ///
  /// Anything that does not match `PREFIX-YEAR-<digits>` exactly is ignored, so
  /// hand-edited or legacy numbers cannot drag the counter backwards.
  int highestIssued({required int year, required Iterable<String> numbers}) {
    final pattern = RegExp('^${RegExp.escape(prefix)}-$year-(\\d+)\$');
    var highest = 0;
    for (final number in numbers) {
      final match = pattern.firstMatch(number.trim());
      if (match == null) continue;
      final value = int.tryParse(match.group(1)!);
      if (value != null && value > highest) highest = value;
    }
    return highest;
  }
}

extension StockMovementDocumentSequence on StockMovementType {
  /// Production stock-out and raw-material stock-out deliberately share one
  /// counter: both write `STK-OUT` numbers into `stockTransactions`.
  DocumentSequence get documentSequence => switch (this) {
        StockMovementType.stockIn => DocumentSequence.rawMaterialStockIn,
        StockMovementType.stockOut => DocumentSequence.rawMaterialStockOut,
        StockMovementType.adjustmentIn =>
          DocumentSequence.rawMaterialAdjustmentIn,
        StockMovementType.adjustmentOut =>
          DocumentSequence.rawMaterialAdjustmentOut,
      };
}

extension InventoryMovementDocumentSequence on InventoryMovementType {
  DocumentSequence get documentSequence => switch (this) {
        InventoryMovementType.productionIn =>
          DocumentSequence.finishedGoodProductionIn,
        InventoryMovementType.adjustmentIn =>
          DocumentSequence.finishedGoodAdjustmentIn,
        InventoryMovementType.adjustmentOut =>
          DocumentSequence.finishedGoodAdjustmentOut,
      };
}

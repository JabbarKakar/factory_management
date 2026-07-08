import '../../domain/entities/inventory_transaction.dart';
import '../../domain/entities/stock_transaction.dart';
import '../../domain/enums/inventory_enums.dart';
import '../../domain/enums/raw_material_enums.dart';

abstract final class StockCorrectionHelper {
  static bool isProductionLinkedStockOut(StockTransaction transaction) {
    return transaction.movementType == StockMovementType.stockOut &&
        (transaction.notes?.toLowerCase().contains('production batch') ??
            false);
  }

  static bool canCorrectStockTransaction(StockTransaction transaction) {
    return !isProductionLinkedStockOut(transaction);
  }

  static bool canCorrectInventoryTransaction(
    InventoryTransaction transaction,
  ) {
    return transaction.movementType != InventoryMovementType.productionIn;
  }

  static StockMovementType inverseStockMovement(StockMovementType type) {
    return switch (type) {
      StockMovementType.stockIn ||
      StockMovementType.adjustmentIn =>
        StockMovementType.adjustmentOut,
      StockMovementType.stockOut ||
      StockMovementType.adjustmentOut =>
        StockMovementType.adjustmentIn,
    };
  }

  static InventoryMovementType inverseInventoryMovement(
    InventoryMovementType type,
  ) {
    return switch (type) {
      InventoryMovementType.adjustmentIn =>
        InventoryMovementType.adjustmentOut,
      InventoryMovementType.adjustmentOut ||
      InventoryMovementType.productionIn =>
        InventoryMovementType.adjustmentIn,
    };
  }

  static String correctionReasonPrefix(String transactionNumber) =>
      'Correction for $transactionNumber';
}

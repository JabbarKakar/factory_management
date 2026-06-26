class RawMaterialStockService {
  double calculateWeightedAverageCost({
    required double currentStock,
    required double currentAverageCost,
    required double incomingQuantity,
    required double incomingUnitCost,
  }) {
    if (incomingQuantity <= 0) return currentAverageCost;
    if (currentStock <= 0) return incomingUnitCost;

    final currentValue = currentStock * currentAverageCost;
    final incomingValue = incomingQuantity * incomingUnitCost;
    return (currentValue + incomingValue) / (currentStock + incomingQuantity);
  }

  void validateStockOut({
    required double currentStock,
    required double quantity,
  }) {
    if (quantity <= 0) {
      throw const RawMaterialStockException('Quantity must be greater than zero.');
    }
    if (quantity > currentStock) {
      throw RawMaterialStockException(
        'Cannot remove ${quantity.toStringAsFixed(quantity == quantity.roundToDouble() ? 0 : 2)} — only ${currentStock.toStringAsFixed(currentStock == currentStock.roundToDouble() ? 0 : 2)} in stock.',
      );
    }
  }
}

class RawMaterialStockException implements Exception {
  const RawMaterialStockException(this.message);

  final String message;

  @override
  String toString() => message;
}

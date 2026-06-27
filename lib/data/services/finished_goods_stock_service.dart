class FinishedGoodsStockException implements Exception {
  const FinishedGoodsStockException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FinishedGoodsStockService {
  double calculateWeightedAverageCost({
    required double currentQuantity,
    required double currentAverageCost,
    required double incomingQuantity,
    required double incomingUnitCost,
  }) {
    if (incomingQuantity <= 0) return currentAverageCost;
    if (currentQuantity <= 0) return incomingUnitCost;

    final currentValue = currentQuantity * currentAverageCost;
    final incomingValue = incomingQuantity * incomingUnitCost;
    return (currentValue + incomingValue) /
        (currentQuantity + incomingQuantity);
  }

  void validateStockOut({
    required double currentQuantity,
    required double quantity,
  }) {
    if (quantity <= 0) {
      throw const FinishedGoodsStockException(
        'Quantity must be greater than zero.',
      );
    }
    if (quantity > currentQuantity) {
      throw FinishedGoodsStockException(
        'Insufficient stock. Available: ${currentQuantity.toStringAsFixed(currentQuantity == currentQuantity.roundToDouble() ? 0 : 2)} sq. ft',
      );
    }
  }
}

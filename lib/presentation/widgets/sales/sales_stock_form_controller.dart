import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/stock_output_calculator.dart';
import '../../../domain/entities/stock_output.dart';

/// Form state for sales stock entry: square feet + per-size price → pieces + amount.
class SalesStockFormController {
  SalesStockFormController({
    required List<String> smallSizes,
    required List<String> largeSizes,
    double smallPricePerSqFt = 0,
    double largePricePerSqFt = 0,
    List<StockOutput> initialSmall = const [],
    List<StockOutput> initialLarge = const [],
  })  : _smallSizes = List<String>.from(smallSizes),
        _largeSizes = List<String>.from(largeSizes),
        _smallSizeSet = smallSizes.toSet() {
    final smallBySize = StockOutputCalculator.indexBySize(initialSmall);
    final largeBySize = StockOutputCalculator.indexBySize(initialLarge);

    for (final size in _smallSizes) {
      _initRow(
        size,
        smallBySize[size],
        fallbackPricePerSqFt: smallPricePerSqFt,
      );
    }
    for (final size in _largeSizes) {
      _initRow(
        size,
        largeBySize[size],
        fallbackPricePerSqFt: largePricePerSqFt,
      );
    }
  }

  final List<String> _smallSizes;
  final List<String> _largeSizes;
  final Set<String> _smallSizeSet;
  final Map<String, TextEditingController> _sqFtControllers = {};
  final Map<String, TextEditingController> _priceControllers = {};
  final List<VoidCallback> _listeners = [];

  List<String> get smallSizes => List.unmodifiable(_smallSizes);
  List<String> get largeSizes => List.unmodifiable(_largeSizes);

  /// Representative small-section price (first active row) for legacy line fields.
  double get smallPricePerSqFt {
    for (final output in activeSmallOutputs) {
      if (output.pricePerSqFt > 0) return output.pricePerSqFt;
    }
    return 0;
  }

  /// Representative large-section price (first active row) for legacy line fields.
  double get largePricePerSqFt {
    for (final output in activeLargeOutputs) {
      if (output.pricePerSqFt > 0) return output.pricePerSqFt;
    }
    return 0;
  }

  void addListener(VoidCallback listener) => _listeners.add(listener);

  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void _initRow(
    String size,
    StockOutput? existing, {
    required double fallbackPricePerSqFt,
  }) {
    final sqFt = TextEditingController(
      text: existing != null && existing.squareFeet > 0
          ? ThousandsTextInputFormatter.format(existing.squareFeet)
          : '',
    );
    final seededPrice = existing != null && existing.pricePerSqFt > 0
        ? existing.pricePerSqFt
        : fallbackPricePerSqFt;
    final price = TextEditingController(text: _formatPrice(seededPrice));
    sqFt.addListener(_notify);
    price.addListener(_notify);
    _sqFtControllers[size] = sqFt;
    _priceControllers[size] = price;
  }

  void _notify() {
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
  }

  String _formatPrice(double value) {
    if (value <= 0) return '';
    return ThousandsTextInputFormatter.format(value);
  }

  double _parsePriceText(String text) {
    final value = ThousandsTextInputFormatter.tryParseDouble(text);
    if (value == null || value < 0) return 0;
    return value;
  }

  double _parseSqFt(String size) {
    final value =
        ThousandsTextInputFormatter.tryParseDouble(_sqFtControllers[size]!.text);
    if (value == null || value < 0) return 0;
    return value;
  }

  double pricePerSqFtFor(String size) =>
      _parsePriceText(_priceControllers[size]!.text);

  bool isSmallSize(String size) => _smallSizeSet.contains(size);

  StockOutput outputForSize(String size) {
    return StockOutputCalculator.computeFromSquareFeet(
      size: size,
      squareFeet: _parseSqFt(size),
      pricePerSqFt: pricePerSqFtFor(size),
    );
  }

  List<StockOutput> buildSmallOutputs() =>
      _smallSizes.map(outputForSize).toList();

  List<StockOutput> buildLargeOutputs() =>
      _largeSizes.map(outputForSize).toList();

  List<StockOutput> get activeSmallOutputs => buildSmallOutputs()
      .where((output) => output.squareFeet > 0)
      .toList();

  List<StockOutput> get activeLargeOutputs => buildLargeOutputs()
      .where((output) => output.squareFeet > 0)
      .toList();

  List<StockOutput> get activeOutputs => [
        ...activeSmallOutputs,
        ...activeLargeOutputs,
      ];

  int get smallTotalPieces =>
      StockOutputCalculator.totalPieces(activeSmallOutputs);

  int get largeTotalPieces =>
      StockOutputCalculator.totalPieces(activeLargeOutputs);

  int get totalPieces => smallTotalPieces + largeTotalPieces;

  double get smallTotalSquareFeet =>
      StockOutputCalculator.totalSquareFeet(activeSmallOutputs);

  double get largeTotalSquareFeet =>
      StockOutputCalculator.totalSquareFeet(activeLargeOutputs);

  double get totalSquareFeet =>
      StockOutputCalculator.totalSquareFeet(activeOutputs);

  double get smallTotalAmount =>
      StockOutputCalculator.grandTotal(activeSmallOutputs);

  double get largeTotalAmount =>
      StockOutputCalculator.grandTotal(activeLargeOutputs);

  double get grandTotal => StockOutputCalculator.grandTotal(activeOutputs);

  bool get hasContent => activeOutputs.isNotEmpty && grandTotal > 0;

  bool get hasSmallSqFtEntry =>
      buildSmallOutputs().any((output) => output.squareFeet > 0);

  bool get hasLargeSqFtEntry =>
      buildLargeOutputs().any((output) => output.squareFeet > 0);

  TextEditingController sqFtControllerFor(String size) =>
      _sqFtControllers[size]!;

  TextEditingController priceControllerFor(String size) =>
      _priceControllers[size]!;

  void dispose() {
    for (final controller in _sqFtControllers.values) {
      controller.dispose();
    }
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    _listeners.clear();
  }
}

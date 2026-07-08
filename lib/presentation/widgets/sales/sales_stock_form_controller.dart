import 'package:flutter/material.dart';

import '../../../core/utils/stock_output_calculator.dart';
import '../../../domain/entities/stock_output.dart';

/// Form state for sales stock entry: square feet in → pieces + amount out.
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
    _smallPriceController = TextEditingController(
      text: _formatPrice(smallPricePerSqFt),
    );
    _largePriceController = TextEditingController(
      text: _formatPrice(largePricePerSqFt),
    );
    _smallPriceController.addListener(_notify);
    _largePriceController.addListener(_notify);

    final smallBySize = StockOutputCalculator.indexBySize(initialSmall);
    final largeBySize = StockOutputCalculator.indexBySize(initialLarge);

    for (final size in _smallSizes) {
      _initRow(size, smallBySize[size]);
    }
    for (final size in _largeSizes) {
      _initRow(size, largeBySize[size]);
    }
  }

  final List<String> _smallSizes;
  final List<String> _largeSizes;
  final Set<String> _smallSizeSet;
  late final TextEditingController _smallPriceController;
  late final TextEditingController _largePriceController;
  final Map<String, TextEditingController> _sqFtControllers = {};
  final List<VoidCallback> _listeners = [];

  List<String> get smallSizes => List.unmodifiable(_smallSizes);
  List<String> get largeSizes => List.unmodifiable(_largeSizes);

  TextEditingController get smallPriceController => _smallPriceController;

  TextEditingController get largePriceController => _largePriceController;

  double get smallPricePerSqFt => _parsePriceText(_smallPriceController.text);

  double get largePricePerSqFt => _parsePriceText(_largePriceController.text);

  void addListener(VoidCallback listener) => _listeners.add(listener);

  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void _initRow(String size, StockOutput? existing) {
    final sqFt = TextEditingController(
      text: existing != null && existing.squareFeet > 0
          ? existing.squareFeet.toStringAsFixed(2)
          : '',
    );
    sqFt.addListener(_notify);
    _sqFtControllers[size] = sqFt;
  }

  void _notify() {
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
  }

  String _formatPrice(double value) {
    if (value <= 0) return '';
    final rounded = value.round();
    if ((value - rounded).abs() < 0.01) return rounded.toString();
    return value.toStringAsFixed(2);
  }

  double _parsePriceText(String text) {
    final value = double.tryParse(text.trim());
    if (value == null || value < 0) return 0;
    return value;
  }

  double _parseSqFt(String size) {
    final value = double.tryParse(_sqFtControllers[size]!.text.trim());
    if (value == null || value < 0) return 0;
    return value;
  }

  double pricePerSqFtFor(String size) {
    if (_smallSizeSet.contains(size)) return smallPricePerSqFt;
    return largePricePerSqFt;
  }

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

  TextEditingController sqFtControllerFor(String size) => _sqFtControllers[size]!;

  void dispose() {
    _smallPriceController.dispose();
    _largePriceController.dispose();
    for (final controller in _sqFtControllers.values) {
      controller.dispose();
    }
    _listeners.clear();
  }
}

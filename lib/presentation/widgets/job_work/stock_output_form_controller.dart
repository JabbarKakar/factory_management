import 'package:flutter/material.dart';

import '../../../core/utils/stock_output_calculator.dart';
import '../../../domain/entities/stock_output.dart';

/// Mutable form state for per-stock production entry.
class StockOutputFormController {
  StockOutputFormController({
    required List<String> smallSizes,
    required List<String> largeSizes,
    required double defaultSmallPrice,
    required double defaultLargePrice,
    List<StockOutput> initialSmall = const [],
    List<StockOutput> initialLarge = const [],
  })  : _smallSizes = List<String>.from(smallSizes),
        _largeSizes = List<String>.from(largeSizes) {
    final smallBySize = StockOutputCalculator.indexBySize(initialSmall);
    final largeBySize = StockOutputCalculator.indexBySize(initialLarge);

    for (final size in _smallSizes) {
      _initRow(size, smallBySize[size], defaultSmallPrice);
    }
    for (final size in _largeSizes) {
      _initRow(size, largeBySize[size], defaultLargePrice);
    }
  }

  final List<String> _smallSizes;
  final List<String> _largeSizes;
  final Map<String, TextEditingController> _piecesControllers = {};
  final Map<String, TextEditingController> _priceControllers = {};
  final List<VoidCallback> _listeners = [];

  List<String> get smallSizes => List.unmodifiable(_smallSizes);
  List<String> get largeSizes => List.unmodifiable(_largeSizes);

  void addListener(VoidCallback listener) => _listeners.add(listener);

  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void _initRow(String size, StockOutput? existing, double defaultPrice) {
    final pieces = TextEditingController(
      text: existing != null && existing.pieces > 0
          ? existing.pieces.toString()
          : '',
    );
    final price = TextEditingController(
      text: _formatPrice(existing?.pricePerSqFt ?? defaultPrice),
    );
    pieces.addListener(_notify);
    price.addListener(_notify);
    _piecesControllers[size] = pieces;
    _priceControllers[size] = price;
  }

  String _formatPrice(double value) {
    if (value <= 0) return '';
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  }

  void _notify() {
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
  }

  int _parsePieces(String size) {
    final value = int.tryParse(_piecesControllers[size]!.text.trim());
    if (value == null || value < 0) return 0;
    return value;
  }

  double _parsePrice(String size) {
    final value = double.tryParse(_priceControllers[size]!.text.trim());
    if (value == null || value < 0) return 0;
    return value;
  }

  StockOutput outputForSize(String size) {
    return StockOutputCalculator.compute(
      size: size,
      pieces: _parsePieces(size),
      pricePerSqFt: _parsePrice(size),
    );
  }

  List<StockOutput> buildSmallOutputs() =>
      _smallSizes.map(outputForSize).toList();

  List<StockOutput> buildLargeOutputs() =>
      _largeSizes.map(outputForSize).toList();

  List<StockOutput> get allOutputs => [
        ...buildSmallOutputs(),
        ...buildLargeOutputs(),
      ];

  List<StockOutput> get activeOutputs =>
      allOutputs.where((output) => output.hasProduction).toList();

  int get totalPieces => StockOutputCalculator.totalPieces(activeOutputs);

  double get totalSquareFeet =>
      StockOutputCalculator.totalSquareFeet(activeOutputs);

  double get grandCuttingTotal =>
      StockOutputCalculator.grandTotal(activeOutputs);

  bool get hasProduction => activeOutputs.isNotEmpty;

  TextEditingController piecesControllerFor(String size) =>
      _piecesControllers[size]!;

  TextEditingController priceControllerFor(String size) =>
      _priceControllers[size]!;

  void dispose() {
    for (final controller in _piecesControllers.values) {
      controller.dispose();
    }
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    _listeners.clear();
  }
}

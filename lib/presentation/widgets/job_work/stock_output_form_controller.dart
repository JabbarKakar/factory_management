import 'package:flutter/material.dart';

import '../../../core/utils/stock_output_calculator.dart';
import '../../../domain/entities/stock_output.dart';

/// Mutable form state for per-stock production entry.
class StockOutputFormController {
  StockOutputFormController({
    required List<String> smallSizes,
    required List<String> largeSizes,
    required double smallPricePerSqFt,
    required double largePricePerSqFt,
    List<StockOutput> initialSmall = const [],
    List<StockOutput> initialLarge = const [],
  })  : _smallSizes = List<String>.from(smallSizes),
        _largeSizes = List<String>.from(largeSizes),
        _smallPricePerSqFt = smallPricePerSqFt,
        _largePricePerSqFt = largePricePerSqFt,
        _smallSizeSet = smallSizes.toSet(),
        _largeSizeSet = largeSizes.toSet() {
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
  final double _smallPricePerSqFt;
  final double _largePricePerSqFt;
  final Set<String> _smallSizeSet;
  final Set<String> _largeSizeSet;
  final Map<String, TextEditingController> _piecesControllers = {};
  final List<VoidCallback> _listeners = [];

  List<String> get smallSizes => List.unmodifiable(_smallSizes);
  List<String> get largeSizes => List.unmodifiable(_largeSizes);
  double get smallPricePerSqFt => _smallPricePerSqFt;
  double get largePricePerSqFt => _largePricePerSqFt;

  void addListener(VoidCallback listener) => _listeners.add(listener);

  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void _initRow(String size, StockOutput? existing) {
    final pieces = TextEditingController(
      text: existing != null && existing.pieces > 0
          ? existing.pieces.toString()
          : '',
    );
    pieces.addListener(_notify);
    _piecesControllers[size] = pieces;
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

  double pricePerSqFtFor(String size) {
    if (_smallSizeSet.contains(size)) return _smallPricePerSqFt;
    if (_largeSizeSet.contains(size)) return _largePricePerSqFt;
    return 0;
  }

  bool isSmallSize(String size) => _smallSizeSet.contains(size);

  StockOutput outputForSize(String size) {
    return StockOutputCalculator.compute(
      size: size,
      pieces: _parsePieces(size),
      pricePerSqFt: pricePerSqFtFor(size),
    );
  }

  List<StockOutput> buildSmallOutputs() =>
      _smallSizes.map(outputForSize).toList();

  List<StockOutput> buildLargeOutputs() =>
      _largeSizes.map(outputForSize).toList();

  List<StockOutput> get activeSmallOutputs =>
      buildSmallOutputs().where((output) => output.hasProduction).toList();

  List<StockOutput> get activeLargeOutputs =>
      buildLargeOutputs().where((output) => output.hasProduction).toList();

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

  double get grandCuttingTotal =>
      StockOutputCalculator.grandTotal(activeOutputs);

  bool get hasProduction => activeOutputs.isNotEmpty;

  TextEditingController piecesControllerFor(String size) =>
      _piecesControllers[size]!;

  void dispose() {
    for (final controller in _piecesControllers.values) {
      controller.dispose();
    }
    _listeners.clear();
  }
}

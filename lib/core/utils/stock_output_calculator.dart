import '../../domain/entities/stock_output.dart';

/// Square-foot and amount math for inch-based stock sizes (e.g. 4x12).
abstract final class StockOutputCalculator {
  static const double squareInchesPerSquareFoot = 144;

  static (double width, double height)? parseSizeInches(String size) {
    final normalized = size.toLowerCase().replaceAll('×', 'x').trim();
    final parts = normalized.split('x');
    if (parts.length != 2) return null;

    final width = double.tryParse(parts[0].trim());
    final height = double.tryParse(parts[1].trim());
    if (width == null || height == null || width <= 0 || height <= 0) {
      return null;
    }
    return (width, height);
  }

  static double squareFeetPerPiece(String size) {
    final dimensions = parseSizeInches(size);
    if (dimensions == null) return 0;
    final (width, height) = dimensions;
    return _roundSqFt((width * height) / squareInchesPerSquareFoot);
  }

  static StockOutput compute({
    required String size,
    required int pieces,
    required double pricePerSqFt,
  }) {
    final safePieces = pieces < 0 ? 0 : pieces;
    final safePrice = pricePerSqFt < 0 ? 0.0 : pricePerSqFt;
    final dimensions = parseSizeInches(size);
    final squareFeet = dimensions == null
        ? 0.0
        : _roundSqFt(
            (dimensions.$1 * dimensions.$2 * safePieces) /
                squareInchesPerSquareFoot,
          );
    final amount = _roundAmount(squareFeet * safePrice);

    return StockOutput(
      size: size,
      pieces: safePieces,
      squareFeet: squareFeet,
      pricePerSqFt: safePrice,
      amount: amount,
    );
  }

  /// Sales orders: user enters square feet; pieces and amount are derived.
  ///
  /// Keeps the entered [squareFeet] as the source of truth for totals/amount.
  /// Pieces are estimated from size (display only) and must not rewrite sq. ft.
  static StockOutput computeFromSquareFeet({
    required String size,
    required double squareFeet,
    required double pricePerSqFt,
  }) {
    final safeSqFt = squareFeet < 0 ? 0.0 : _roundSqFt(squareFeet);
    final safePrice = pricePerSqFt < 0 ? 0.0 : pricePerSqFt;
    final sqFtPerPiece = squareFeetPerPiece(size);
    final pieces = safeSqFt <= 0 || sqFtPerPiece <= 0
        ? 0
        : (safeSqFt / sqFtPerPiece).round();
    final amount = _roundAmount(safeSqFt * safePrice);

    return StockOutput(
      size: size,
      pieces: pieces,
      squareFeet: safeSqFt,
      pricePerSqFt: safePrice,
      amount: amount,
    );
  }

  static List<StockOutput> rowsForSizes({
    required List<String> sizes,
    required Map<String, StockOutput> existing,
    required double defaultPricePerSqFt,
  }) {
    return sizes
        .map((size) {
          final stored = existing[size];
          if (stored != null && stored.hasProduction) return stored;
          return StockOutput(
            size: size,
            pricePerSqFt: stored?.pricePerSqFt ?? defaultPricePerSqFt,
          );
        })
        .toList();
  }

  static Map<String, StockOutput> indexBySize(Iterable<StockOutput> outputs) {
    return {for (final output in outputs) output.size: output};
  }

  static List<StockOutput> mergeBySize(Iterable<StockOutput> outputs) {
    final merged = <String, StockOutput>{};
    for (final output in outputs) {
      if (!output.hasProduction) continue;
      final current = merged[output.size];
      if (current == null) {
        merged[output.size] = output;
        continue;
      }
      final pieces = current.pieces + output.pieces;
      final pricePerSqFt =
          output.pricePerSqFt > 0 ? output.pricePerSqFt : current.pricePerSqFt;
      final dimensions = parseSizeInches(output.size);
      final squareFeet = dimensions == null
          ? _roundSqFt(current.squareFeet + output.squareFeet)
          : _roundSqFt(
              (dimensions.$1 * dimensions.$2 * pieces) /
                  squareInchesPerSquareFoot,
            );
      merged[output.size] = StockOutput(
        size: output.size,
        pieces: pieces,
        squareFeet: squareFeet,
        pricePerSqFt: pricePerSqFt,
        amount: _roundAmount(squareFeet * pricePerSqFt),
      );
    }
    return merged.values.toList();
  }

  static int totalPieces(Iterable<StockOutput> outputs) =>
      outputs.fold<int>(0, (sum, output) => sum + output.pieces);

  static double totalSquareFeet(Iterable<StockOutput> outputs) =>
      _roundSqFt(outputs.fold<double>(0, (sum, output) => sum + output.squareFeet));

  static double grandTotal(Iterable<StockOutput> outputs) =>
      _roundAmount(outputs.fold<double>(0, (sum, output) => sum + output.amount));

  static double _roundSqFt(double value) =>
      double.parse(value.toStringAsFixed(2));

  static double _roundAmount(double value) =>
      double.parse(value.toStringAsFixed(2));
}

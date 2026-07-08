import 'package:equatable/equatable.dart';

/// Production and cutting charges for a single stock size.
class StockOutput extends Equatable {
  const StockOutput({
    required this.size,
    this.pieces = 0,
    this.squareFeet = 0,
    this.pricePerSqFt = 0,
    this.amount = 0,
  });

  final String size;
  final int pieces;
  final double squareFeet;
  final double pricePerSqFt;
  final double amount;

  bool get hasProduction => pieces > 0;

  /// True when either pieces or square feet have been entered (sales or job work).
  bool get hasEntry => pieces > 0 || squareFeet > 0;

  StockOutput copyWith({
    String? size,
    int? pieces,
    double? squareFeet,
    double? pricePerSqFt,
    double? amount,
  }) {
    return StockOutput(
      size: size ?? this.size,
      pieces: pieces ?? this.pieces,
      squareFeet: squareFeet ?? this.squareFeet,
      pricePerSqFt: pricePerSqFt ?? this.pricePerSqFt,
      amount: amount ?? this.amount,
    );
  }

  Map<String, dynamic> toMap() => {
        'size': size,
        'pieces': pieces,
        'squareFeet': squareFeet,
        'pricePerSqFt': pricePerSqFt,
        'amount': amount,
      };

  factory StockOutput.fromMap(Map<String, dynamic> data) {
    return StockOutput(
      size: data['size'] as String? ?? '',
      pieces: (data['pieces'] as num?)?.toInt() ?? 0,
      squareFeet: (data['squareFeet'] as num?)?.toDouble() ?? 0,
      pricePerSqFt: (data['pricePerSqFt'] as num?)?.toDouble() ?? 0,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [size, pieces, squareFeet, pricePerSqFt, amount];
}

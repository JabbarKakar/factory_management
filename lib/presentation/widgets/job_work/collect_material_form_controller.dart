import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/job_work_sizes.dart';
import '../../../core/utils/stock_output_calculator.dart';
import '../../../data/services/job_work_collection_quantity_helper.dart';
import '../../../domain/entities/job_work_collection.dart';
import '../../../domain/entities/stock_output.dart';

class CollectMaterialRow {
  CollectMaterialRow({
    required this.size,
    required this.producedPieces,
    required this.producedSquareFeet,
    required this.maxRemainingPieces,
    required this.maxRemainingSquareFeet,
    int initialPieces = 0,
  }) : piecesController = TextEditingController(
          text: initialPieces > 0 ? initialPieces.toString() : '',
        );

  final String size;
  final int producedPieces;
  final double producedSquareFeet;
  final int maxRemainingPieces;
  final double maxRemainingSquareFeet;
  final TextEditingController piecesController;

  bool get isSmall => JobWorkSizes.isSmall(size);

  int get collectPieces {
    final parsed = int.tryParse(piecesController.text.trim());
    return parsed ?? 0;
  }

  StockOutput outputForPieces(int pieces) {
    return StockOutputCalculator.compute(
      size: size,
      pieces: pieces,
      pricePerSqFt: 0,
    );
  }

  double get collectSquareFeet => outputForPieces(collectPieces).squareFeet;

  int get remainingPiecesAfterCollect =>
      math.max(0, maxRemainingPieces - collectPieces);

  double get remainingSquareFeetAfterCollect => math.max(
        0,
        maxRemainingSquareFeet - collectSquareFeet,
      );

  bool get hasCollectQuantity => collectPieces > 0;

  JobWorkCollectionLineItem toLineItem() {
    return JobWorkCollectionLineItem(
      size: size,
      pieces: collectPieces,
      squareFeet: collectSquareFeet,
      isSmall: isSmall,
    );
  }

  void dispose() {
    piecesController.dispose();
  }
}

class CollectMaterialFormController extends ChangeNotifier {
  CollectMaterialFormController._(this.rows, {this.orderTotals});

  final List<CollectMaterialRow> rows;
  final JobWorkCollectionTotals? orderTotals;

  factory CollectMaterialFormController.fromRemainingLines({
    required List<JobWorkCollectionRemainingLine> remainingLines,
    JobWorkCollectionTotals? orderTotals,
  }) {
    final rows = remainingLines
        .where(
          (line) =>
              line.remainingPieces > 0 || line.remainingSquareFeet > 0,
        )
        .map(
          (line) => CollectMaterialRow(
            size: line.size,
            producedPieces: line.producedPieces,
            producedSquareFeet: line.producedSquareFeet,
            maxRemainingPieces: line.remainingPieces,
            maxRemainingSquareFeet: line.remainingSquareFeet,
          ),
        )
        .toList();

    return CollectMaterialFormController._(
      rows,
      orderTotals: orderTotals,
    );
  }

  bool get hasRows => rows.isNotEmpty;

  bool get hasCollectQuantity => rows.any((row) => row.hasCollectQuantity);

  int get totalCollectPieces =>
      rows.fold<int>(0, (sum, row) => sum + row.collectPieces);

  double get totalCollectSquareFeet =>
      rows.fold<double>(0, (sum, row) => sum + row.collectSquareFeet);

  List<CollectMaterialRow> get smallRows =>
      rows.where((row) => row.isSmall).toList();

  List<CollectMaterialRow> get largeRows =>
      rows.where((row) => !row.isSmall).toList();

  int remainingPiecesAfterCollect(int collectPieces) {
    final totals = orderTotals;
    if (totals == null) return 0;
    return math.max(
      0,
      totals.totalPieces - totals.collectedPieces - collectPieces,
    );
  }

  double remainingSquareFeetAfterCollect(double collectSquareFeet) {
    final totals = orderTotals;
    if (totals == null) return 0;
    return math.max(
      0,
      totals.totalSquareFeet - totals.collectedSquareFeet - collectSquareFeet,
    );
  }

  List<JobWorkCollectionLineItem> buildLineItems() {
    return rows
        .where((row) => row.hasCollectQuantity)
        .map((row) => row.toLineItem())
        .toList();
  }

  void notifyChanged() => notifyListeners();

  void dispose() {
    for (final row in rows) {
      row.dispose();
    }
    super.dispose();
  }
}

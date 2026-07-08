import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/job_work_sizes.dart';
import '../../../core/utils/stock_output_calculator.dart';
import '../../../data/services/delivery_quantity_helper.dart';
import '../../../domain/entities/delivery.dart';
import '../../../domain/entities/stock_output.dart';
import '../../../domain/enums/sales_enums.dart';

class DispatchStockRow {
  DispatchStockRow({
    required this.productType,
    required this.marbleVariety,
    required this.size,
    required this.orderedPieces,
    required this.orderedSquareFeet,
    required this.maxRemainingPieces,
    required this.maxRemainingSquareFeet,
    int initialPieces = 0,
    int? initialPiecesDelivered,
  })  : piecesController = TextEditingController(
          text: initialPieces > 0 ? initialPieces.toString() : '',
        ),
        piecesDeliveredController = TextEditingController(
          text: initialPiecesDelivered != null && initialPiecesDelivered > 0
              ? initialPiecesDelivered.toString()
              : initialPieces > 0
                  ? initialPieces.toString()
                  : '',
        );

  final SalesProductType productType;
  final String marbleVariety;
  final String size;
  final int orderedPieces;
  final double orderedSquareFeet;
  final int maxRemainingPieces;
  final double maxRemainingSquareFeet;
  final TextEditingController piecesController;
  final TextEditingController piecesDeliveredController;

  bool get isSmall => JobWorkSizes.isSmall(size);

  int get scheduledPieces {
    final parsed = int.tryParse(piecesController.text.trim());
    return parsed ?? 0;
  }

  int get deliveredPieces {
    final parsed = int.tryParse(piecesDeliveredController.text.trim());
    return parsed ?? 0;
  }

  StockOutput outputForPieces(int pieces) {
    return StockOutputCalculator.compute(
      size: size,
      pieces: pieces,
      pricePerSqFt: 0,
    );
  }

  double get scheduledSquareFeet => outputForPieces(scheduledPieces).squareFeet;

  double get deliveredSquareFeet => outputForPieces(deliveredPieces).squareFeet;

  int get remainingPiecesAfterSchedule =>
      math.max(0, maxRemainingPieces - scheduledPieces);

  double get remainingSquareFeetAfterSchedule => math.max(
        0,
        maxRemainingSquareFeet - scheduledSquareFeet,
      );

  int get remainingPiecesAfterDelivered =>
      math.max(0, maxRemainingPieces - deliveredPieces);

  double get remainingSquareFeetAfterDelivered => math.max(
        0,
        maxRemainingSquareFeet - deliveredSquareFeet,
      );

  bool get hasScheduledDispatch => scheduledPieces > 0;

  DeliveryLineItem toScheduledLineItem() {
    return DeliveryLineItem(
      productType: productType,
      marbleVariety: marbleVariety,
      sizeThickness: size,
      pieces: scheduledPieces,
      squareFeet: scheduledSquareFeet,
    );
  }

  DeliveryLineItem toConfirmedLineItem() {
    return DeliveryLineItem(
      productType: productType,
      marbleVariety: marbleVariety,
      sizeThickness: size,
      pieces: scheduledPieces,
      squareFeet: scheduledSquareFeet,
      piecesDelivered: deliveredPieces,
      squareFeetDelivered: deliveredSquareFeet,
    );
  }

  void dispose() {
    piecesController.dispose();
    piecesDeliveredController.dispose();
  }
}

class DispatchLineItemGroup {
  const DispatchLineItemGroup({
    required this.productType,
    required this.marbleVariety,
    required this.rows,
  });

  final SalesProductType productType;
  final String marbleVariety;
  final List<DispatchStockRow> rows;

  List<DispatchStockRow> get smallRows =>
      rows.where((row) => row.isSmall).toList();

  List<DispatchStockRow> get largeRows =>
      rows.where((row) => !row.isSmall).toList();

  int get totalDispatchPieces =>
      rows.fold<int>(0, (sum, row) => sum + row.scheduledPieces);

  double get totalDispatchSquareFeet =>
      rows.fold<double>(0, (sum, row) => sum + row.scheduledSquareFeet);
}

class DispatchStockFormController extends ChangeNotifier {
  DispatchStockFormController._(this.groups, {this.orderDispatchTotals});

  final List<DispatchLineItemGroup> groups;
  final OrderDispatchTotals? orderDispatchTotals;

  factory DispatchStockFormController.fromRemainingLines({
    required List<DeliveryRemainingLine> remainingLines,
    List<DeliveryLineItem> scheduledItems = const [],
    OrderDispatchTotals? orderDispatchTotals,
  }) {
    DeliveryLineItem? scheduledFor(DeliveryLineItem template) {
      for (final item in scheduledItems) {
        if (item.productType == template.productType &&
            item.marbleVariety == template.marbleVariety &&
            item.sizeThickness == template.sizeThickness) {
          return item;
        }
      }
      return null;
    }

    final grouped = <String, List<DispatchStockRow>>{};
    for (final line in remainingLines) {
      if (line.remainingPieces <= 0 && line.remainingSquareFeet <= 0) {
        continue;
      }
      final scheduled = scheduledFor(line.lineItem);
      final key =
          '${line.lineItem.productType.name}|${line.lineItem.marbleVariety}';
      grouped.putIfAbsent(key, () => []).add(
            DispatchStockRow(
              productType: line.lineItem.productType,
              marbleVariety: line.lineItem.marbleVariety,
              size: line.lineItem.sizeThickness,
              orderedPieces: line.orderedPieces,
              orderedSquareFeet: line.orderedSquareFeet,
              maxRemainingPieces:
                  line.remainingPieces + (scheduled?.pieces ?? 0),
              maxRemainingSquareFeet:
                  line.remainingSquareFeet + (scheduled?.squareFeet ?? 0),
              initialPieces: scheduled?.pieces ?? 0,
            ),
          );
    }

    final groups = grouped.entries.map((entry) {
      final rows = entry.value;
      return DispatchLineItemGroup(
        productType: rows.first.productType,
        marbleVariety: rows.first.marbleVariety,
        rows: rows,
      );
    }).toList();

    return DispatchStockFormController._(
      groups,
      orderDispatchTotals: orderDispatchTotals,
    );
  }

  factory DispatchStockFormController.fromDeliveryLineItems({
    required List<DeliveryLineItem> lineItems,
    OrderDispatchTotals? orderDispatchTotals,
  }) {
    final grouped = <String, List<DispatchStockRow>>{};
    for (final item in lineItems) {
      final key = '${item.productType.name}|${item.marbleVariety}';
      grouped.putIfAbsent(key, () => []).add(
            DispatchStockRow(
              productType: item.productType,
              marbleVariety: item.marbleVariety,
              size: item.sizeThickness,
              orderedPieces: item.pieces,
              orderedSquareFeet: item.squareFeet,
              maxRemainingPieces: item.pieces,
              maxRemainingSquareFeet: item.squareFeet,
              initialPieces: item.pieces,
            ),
          );
    }

    final groups = grouped.entries.map((entry) {
      final rows = entry.value;
      return DispatchLineItemGroup(
        productType: rows.first.productType,
        marbleVariety: rows.first.marbleVariety,
        rows: rows,
      );
    }).toList();

    return DispatchStockFormController._(
      groups,
      orderDispatchTotals: orderDispatchTotals,
    );
  }

  factory DispatchStockFormController.forConfirm({
    required List<DeliveryLineItem> lineItems,
    OrderDispatchTotals? orderDispatchTotals,
  }) {
    final grouped = <String, List<DispatchStockRow>>{};
    for (final item in lineItems) {
      final key = '${item.productType.name}|${item.marbleVariety}';
      grouped.putIfAbsent(key, () => []).add(
            DispatchStockRow(
              productType: item.productType,
              marbleVariety: item.marbleVariety,
              size: item.sizeThickness,
              orderedPieces: item.pieces,
              orderedSquareFeet: item.squareFeet,
              maxRemainingPieces: item.pieces,
              maxRemainingSquareFeet: item.squareFeet,
              initialPieces: item.pieces,
              initialPiecesDelivered: item.piecesDelivered ?? item.pieces,
            ),
          );
    }

    final groups = grouped.entries.map((entry) {
      final rows = entry.value;
      return DispatchLineItemGroup(
        productType: rows.first.productType,
        marbleVariety: rows.first.marbleVariety,
        rows: rows,
      );
    }).toList();

    return DispatchStockFormController._(
      groups,
      orderDispatchTotals: orderDispatchTotals,
    );
  }

  List<DispatchStockRow> get allRows =>
      groups.expand((group) => group.rows).toList();

  bool get hasRows => allRows.isNotEmpty;

  bool get hasScheduledDispatch =>
      allRows.any((row) => row.hasScheduledDispatch);

  int get totalDispatchPieces =>
      allRows.fold<int>(0, (sum, row) => sum + row.scheduledPieces);

  double get totalDispatchSquareFeet =>
      allRows.fold<double>(0, (sum, row) => sum + row.scheduledSquareFeet);

  int get totalDeliveredPieces =>
      allRows.fold<int>(0, (sum, row) => sum + row.deliveredPieces);

  double get totalDeliveredSquareFeet =>
      allRows.fold<double>(0, (sum, row) => sum + row.deliveredSquareFeet);

  int remainingPiecesAfterDispatch(int scheduledPieces) {
    final totals = orderDispatchTotals;
    if (totals == null) return 0;
    return math.max(
      0,
      totals.totalPieces - totals.dispatchedPieces - scheduledPieces,
    );
  }

  double remainingSquareFeetAfterDispatch(double scheduledSquareFeet) {
    final totals = orderDispatchTotals;
    if (totals == null) return 0;
    return math.max(
      0,
      totals.totalSquareFeet - totals.dispatchedSquareFeet - scheduledSquareFeet,
    );
  }

  List<DeliveryLineItem> buildScheduledLineItems() {
    return allRows
        .where((row) => row.hasScheduledDispatch)
        .map((row) => row.toScheduledLineItem())
        .toList();
  }

  List<DeliveryLineItem> buildConfirmedLineItems() {
    return allRows
        .where((row) => row.hasScheduledDispatch)
        .map((row) => row.toConfirmedLineItem())
        .toList();
  }

  void addListenerSafe(VoidCallback listener) {
    addListener(listener);
    for (final row in allRows) {
      row.piecesController.addListener(listener);
      row.piecesDeliveredController.addListener(listener);
    }
  }

  void removeListenerSafe(VoidCallback listener) {
    removeListener(listener);
    for (final row in allRows) {
      row.piecesController.removeListener(listener);
      row.piecesDeliveredController.removeListener(listener);
    }
  }

  @override
  void dispose() {
    for (final row in allRows) {
      row.dispose();
    }
    groups.clear();
    super.dispose();
  }
}

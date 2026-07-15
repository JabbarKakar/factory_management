import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/stock_output_calculator.dart';
import '../../../domain/entities/stock_output.dart';
import '../forms/app_form_fields.dart';
import 'stock_output_form_controller.dart';

class StockOutputRecordingPanel extends StatefulWidget {
  const StockOutputRecordingPanel({
    required this.controller,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final StockOutputFormController controller;
  final VoidCallback onChanged;
  final bool enabled;

  @override
  State<StockOutputRecordingPanel> createState() =>
      _StockOutputRecordingPanelState();
}

class _StockOutputRecordingPanelState extends State<StockOutputRecordingPanel> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChanged);
    super.dispose();
  }

  void _handleChanged() {
    widget.onChanged();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.smallSizes.isNotEmpty)
          _StockSection(
            title: AppStrings.smallSizes,
            sizes: controller.smallSizes,
            controller: controller,
            enabled: widget.enabled,
            totalSquareFeet: controller.smallTotalSquareFeet,
            totalAmount: controller.smallTotalAmount,
            totalPieces: controller.smallTotalPieces,
          ),
        if (controller.largeSizes.isNotEmpty) ...[
          if (controller.smallSizes.isNotEmpty) const SizedBox(height: 14),
          _StockSection(
            title: AppStrings.largeSizes,
            sizes: controller.largeSizes,
            controller: controller,
            enabled: widget.enabled,
            totalSquareFeet: controller.largeTotalSquareFeet,
            totalAmount: controller.largeTotalAmount,
            totalPieces: controller.largeTotalPieces,
          ),
        ],
        const SizedBox(height: 10),
        _GrandTotalsCard(
          totalPieces: controller.totalPieces,
          totalSquareFeet: controller.totalSquareFeet,
          grandCuttingTotal: controller.grandCuttingTotal,
        ),
      ],
    );
  }
}

class StockOutputReadOnlyPanel extends StatelessWidget {
  const StockOutputReadOnlyPanel({
    required this.smallOutputs,
    required this.largeOutputs,
    this.remainingPiecesBySize,
    this.remainingSquareFeetBySize,
    this.showCollected = false,
    this.sizesInExpansionTile = false,
    super.key,
  });

  final List<StockOutput> smallOutputs;
  final List<StockOutput> largeOutputs;

  /// When set (with [remainingSquareFeetBySize]), shows Remaining Pcs/Sq.Ft.
  final Map<String, int>? remainingPiecesBySize;
  final Map<String, double>? remainingSquareFeetBySize;

  /// When true (and remaining maps are set), also shows Collected Pcs/Sq.Ft.
  final bool showCollected;

  /// When true, renders small and large sizes tables inside a single ExpansionTile below grand totals
  final bool sizesInExpansionTile;

  bool get _showRemaining =>
      remainingPiecesBySize != null && remainingSquareFeetBySize != null;

  bool get _showCollected => showCollected && _showRemaining;

  int _remainingPieces(StockOutput output) {
    final map = remainingPiecesBySize;
    if (map == null) return output.pieces;
    return map[output.size] ?? 0;
  }

  double _remainingSquareFeet(StockOutput output) {
    final map = remainingSquareFeetBySize;
    if (map == null) return output.squareFeet;
    return map[output.size] ?? 0;
  }

  int _collectedPieces(StockOutput output) =>
      math.max(0, output.pieces - _remainingPieces(output));

  double _collectedSquareFeet(StockOutput output) =>
      math.max(0.0, output.squareFeet - _remainingSquareFeet(output));

  int _sumRemainingPieces(List<StockOutput> outputs) =>
      outputs.fold<int>(0, (sum, o) => sum + _remainingPieces(o));

  double _sumRemainingSquareFeet(List<StockOutput> outputs) =>
      outputs.fold<double>(0, (sum, o) => sum + _remainingSquareFeet(o));

  int _sumCollectedPieces(List<StockOutput> outputs) =>
      outputs.fold<int>(0, (sum, o) => sum + _collectedPieces(o));

  double _sumCollectedSquareFeet(List<StockOutput> outputs) =>
      outputs.fold<double>(0, (sum, o) => sum + _collectedSquareFeet(o));

  @override
  Widget build(BuildContext context) {
    final activeSmall =
        smallOutputs.where((output) => output.hasProduction).toList();
    final activeLarge =
        largeOutputs.where((output) => output.hasProduction).toList();

    if (activeSmall.isEmpty && activeLarge.isEmpty) {
      return Text(
        AppStrings.noStockProductionYet,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    final allActive = [...activeSmall, ...activeLarge];

    final grandTotalsCard = _GrandTotalsCard(
      totalPieces: StockOutputCalculator.totalPieces(allActive),
      totalSquareFeet: StockOutputCalculator.totalSquareFeet(allActive),
      grandCuttingTotal: StockOutputCalculator.grandTotal(allActive),
      remainingPieces:
          _showRemaining ? _sumRemainingPieces(allActive) : null,
      remainingSquareFeet:
          _showRemaining ? _sumRemainingSquareFeet(allActive) : null,
      collectedPieces:
          _showCollected ? _sumCollectedPieces(allActive) : null,
      collectedSquareFeet:
          _showCollected ? _sumCollectedSquareFeet(allActive) : null,
    );

    if (sizesInExpansionTile) {
      final theme = Theme.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          grandTotalsCard,
          const SizedBox(height: 10),
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                AppStrings.productionDetails,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              children: [
                if (activeSmall.isNotEmpty)
                  _ReadOnlyStockSection(
                    title: AppStrings.smallSizes,
                    outputs: activeSmall,
                    showRemaining: _showRemaining,
                    showCollected: _showCollected,
                    remainingPiecesOf: _remainingPieces,
                    remainingSquareFeetOf: _remainingSquareFeet,
                    collectedPiecesOf: _collectedPieces,
                    collectedSquareFeetOf: _collectedSquareFeet,
                    totalSquareFeet:
                        StockOutputCalculator.totalSquareFeet(activeSmall),
                    totalAmount: StockOutputCalculator.grandTotal(activeSmall),
                    totalPieces: StockOutputCalculator.totalPieces(activeSmall),
                    totalRemainingPieces: _sumRemainingPieces(activeSmall),
                    totalRemainingSquareFeet: _sumRemainingSquareFeet(activeSmall),
                    totalCollectedPieces: _sumCollectedPieces(activeSmall),
                    totalCollectedSquareFeet: _sumCollectedSquareFeet(activeSmall),
                  ),
                if (activeLarge.isNotEmpty) ...[
                  if (activeSmall.isNotEmpty) const SizedBox(height: 14),
                  _ReadOnlyStockSection(
                    title: AppStrings.largeSizes,
                    outputs: activeLarge,
                    showRemaining: _showRemaining,
                    showCollected: _showCollected,
                    remainingPiecesOf: _remainingPieces,
                    remainingSquareFeetOf: _remainingSquareFeet,
                    collectedPiecesOf: _collectedPieces,
                    collectedSquareFeetOf: _collectedSquareFeet,
                    totalSquareFeet:
                        StockOutputCalculator.totalSquareFeet(activeLarge),
                    totalAmount: StockOutputCalculator.grandTotal(activeLarge),
                    totalPieces: StockOutputCalculator.totalPieces(activeLarge),
                    totalRemainingPieces: _sumRemainingPieces(activeLarge),
                    totalRemainingSquareFeet: _sumRemainingSquareFeet(activeLarge),
                    totalCollectedPieces: _sumCollectedPieces(activeLarge),
                    totalCollectedSquareFeet: _sumCollectedSquareFeet(activeLarge),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (activeSmall.isNotEmpty)
          _ReadOnlyStockSection(
            title: AppStrings.smallSizes,
            outputs: activeSmall,
            showRemaining: _showRemaining,
            showCollected: _showCollected,
            remainingPiecesOf: _remainingPieces,
            remainingSquareFeetOf: _remainingSquareFeet,
            collectedPiecesOf: _collectedPieces,
            collectedSquareFeetOf: _collectedSquareFeet,
            totalSquareFeet:
                StockOutputCalculator.totalSquareFeet(activeSmall),
            totalAmount: StockOutputCalculator.grandTotal(activeSmall),
            totalPieces: StockOutputCalculator.totalPieces(activeSmall),
            totalRemainingPieces: _sumRemainingPieces(activeSmall),
            totalRemainingSquareFeet: _sumRemainingSquareFeet(activeSmall),
            totalCollectedPieces: _sumCollectedPieces(activeSmall),
            totalCollectedSquareFeet: _sumCollectedSquareFeet(activeSmall),
          ),
        if (activeLarge.isNotEmpty) ...[
          if (activeSmall.isNotEmpty) const SizedBox(height: 14),
          _ReadOnlyStockSection(
            title: AppStrings.largeSizes,
            outputs: activeLarge,
            showRemaining: _showRemaining,
            showCollected: _showCollected,
            remainingPiecesOf: _remainingPieces,
            remainingSquareFeetOf: _remainingSquareFeet,
            collectedPiecesOf: _collectedPieces,
            collectedSquareFeetOf: _collectedSquareFeet,
            totalSquareFeet:
                StockOutputCalculator.totalSquareFeet(activeLarge),
            totalAmount: StockOutputCalculator.grandTotal(activeLarge),
            totalPieces: StockOutputCalculator.totalPieces(activeLarge),
            totalRemainingPieces: _sumRemainingPieces(activeLarge),
            totalRemainingSquareFeet: _sumRemainingSquareFeet(activeLarge),
            totalCollectedPieces: _sumCollectedPieces(activeLarge),
            totalCollectedSquareFeet: _sumCollectedSquareFeet(activeLarge),
          ),
        ],
        const SizedBox(height: 10),
        grandTotalsCard,
      ],
    );
  }
}

class _StockSection extends StatelessWidget {
  const _StockSection({
    required this.title,
    required this.sizes,
    required this.controller,
    required this.enabled,
    required this.totalSquareFeet,
    required this.totalAmount,
    required this.totalPieces,
  });

  final String title;
  final List<String> sizes;
  final StockOutputFormController controller;
  final bool enabled;
  final double totalSquareFeet;
  final double totalAmount;
  final int totalPieces;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: title),
        const SizedBox(height: 6),
        _StockTable(
          rows: sizes
              .map(
                (size) => _StockRowData(
                  size: size,
                  output: controller.outputForSize(size),
                  pricePerSqFt: controller.pricePerSqFtFor(size),
                  piecesController: controller.piecesControllerFor(size),
                ),
              )
              .toList(),
          enabled: enabled,
          showRemaining: false,
        ),
        const SizedBox(height: 8),
        _SectionTotalsBar(
          sectionLabel: title == AppStrings.smallSizes
              ? AppStrings.smallStock
              : AppStrings.largeStock,
          totalPieces: totalPieces,
          totalSquareFeet: totalSquareFeet,
          totalAmount: totalAmount,
        ),
      ],
    );
  }
}

class _ReadOnlyStockSection extends StatelessWidget {
  const _ReadOnlyStockSection({
    required this.title,
    required this.outputs,
    required this.totalSquareFeet,
    required this.totalAmount,
    required this.totalPieces,
    required this.showRemaining,
    required this.showCollected,
    required this.remainingPiecesOf,
    required this.remainingSquareFeetOf,
    required this.collectedPiecesOf,
    required this.collectedSquareFeetOf,
    required this.totalRemainingPieces,
    required this.totalRemainingSquareFeet,
    required this.totalCollectedPieces,
    required this.totalCollectedSquareFeet,
  });

  final String title;
  final List<StockOutput> outputs;
  final double totalSquareFeet;
  final double totalAmount;
  final int totalPieces;
  final bool showRemaining;
  final bool showCollected;
  final int Function(StockOutput output) remainingPiecesOf;
  final double Function(StockOutput output) remainingSquareFeetOf;
  final int Function(StockOutput output) collectedPiecesOf;
  final double Function(StockOutput output) collectedSquareFeetOf;
  final int totalRemainingPieces;
  final double totalRemainingSquareFeet;
  final int totalCollectedPieces;
  final double totalCollectedSquareFeet;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: title),
        const SizedBox(height: 6),
        _StockTable(
          rows: outputs
              .map(
                (output) => _StockRowData(
                  size: output.size,
                  output: output,
                  pricePerSqFt: output.pricePerSqFt,
                  remainingPieces:
                      showRemaining ? remainingPiecesOf(output) : null,
                  remainingSquareFeet:
                      showRemaining ? remainingSquareFeetOf(output) : null,
                  collectedPieces:
                      showCollected ? collectedPiecesOf(output) : null,
                  collectedSquareFeet:
                      showCollected ? collectedSquareFeetOf(output) : null,
                ),
              )
              .toList(),
          enabled: false,
          showRemaining: showRemaining,
          showCollected: showCollected,
        ),
        const SizedBox(height: 8),
        _SectionTotalsBar(
          sectionLabel: title == AppStrings.smallSizes
              ? AppStrings.smallStock
              : AppStrings.largeStock,
          totalPieces: totalPieces,
          totalSquareFeet: totalSquareFeet,
          totalAmount: totalAmount,
          remainingPieces: showRemaining ? totalRemainingPieces : null,
          remainingSquareFeet:
              showRemaining ? totalRemainingSquareFeet : null,
          collectedPieces: showCollected ? totalCollectedPieces : null,
          collectedSquareFeet:
              showCollected ? totalCollectedSquareFeet : null,
        ),
      ],
    );
  }
}

class _StockRowData {
  const _StockRowData({
    required this.size,
    required this.output,
    required this.pricePerSqFt,
    this.piecesController,
    this.remainingPieces,
    this.remainingSquareFeet,
    this.collectedPieces,
    this.collectedSquareFeet,
  });

  final String size;
  final StockOutput output;
  final double pricePerSqFt;
  final TextEditingController? piecesController;
  final int? remainingPieces;
  final double? remainingSquareFeet;
  final int? collectedPieces;
  final double? collectedSquareFeet;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
    );
  }
}

class _StockTable extends StatelessWidget {
  const _StockTable({
    required this.rows,
    required this.enabled,
    this.showRemaining = false,
    this.showCollected = false,
  });

  final List<_StockRowData> rows;
  final bool enabled;
  final bool showRemaining;
  final bool showCollected;

  static const _outlineAlpha = 0.24;
  static const _rowGap = 4.0;

  @override
  Widget build(BuildContext context) {
    final outline =
        Theme.of(context).colorScheme.outline.withValues(alpha: _outlineAlpha);

    final table = DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TableHeaderRow(
              showRemaining: showRemaining,
              showCollected: showCollected,
            ),
            for (var i = 0; i < rows.length; i++) ...[
              Divider(height: 1, thickness: 1, color: outline),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: _rowGap,
                ),
                child: _StockDataRow(
                  row: rows[i],
                  enabled: enabled,
                  showRemaining: showRemaining,
                  showCollected: showCollected,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (!showCollected) return table;

    final minWidth = math.max(
      MediaQuery.sizeOf(context).width - 48,
      780.0,
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: SizedBox(width: minWidth, child: table),
      ),
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({
    this.showRemaining = false,
    this.showCollected = false,
  });

  final bool showRemaining;
  final bool showCollected;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 9,
          height: 1.1,
        );

    final labels = showCollected
        ? const [
            AppStrings.stockSize,
            AppStrings.pieces,
            AppStrings.collectedPiecesShort,
            AppStrings.remainingPiecesShort,
            AppStrings.sqFtShort,
            AppStrings.collectedSquareFeetShort,
            AppStrings.remainingSquareFeetShort,
            AppStrings.pricePerSqFt,
            AppStrings.amount,
          ]
        : showRemaining
            ? const [
                AppStrings.stockSize,
                AppStrings.pieces,
                AppStrings.remainingPiecesShort,
                AppStrings.sqFtShort,
                AppStrings.remainingSquareFeetShort,
                AppStrings.pricePerSqFt,
                AppStrings.amount,
              ]
            : const [
                AppStrings.stockSize,
                AppStrings.pieces,
                AppStrings.sqFtShort,
                AppStrings.pricePerSqFt,
                AppStrings.amount,
              ];
    final flex = showCollected
        ? const [10, 8, 10, 10, 9, 11, 11, 8, 11]
        : showRemaining
            ? const [12, 10, 11, 11, 12, 11, 14]
            : const [14, 13, 14, 14, 18];

    return Container(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.55),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            _HeaderCell(label: labels[i], flex: flex[i], style: style),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    required this.flex,
    required this.style,
  });

  final String label;
  final int flex;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          label,
          style: style,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }
}

class _StockDataRow extends StatelessWidget {
  const _StockDataRow({
    required this.row,
    required this.enabled,
    this.showRemaining = false,
    this.showCollected = false,
  });

  final _StockRowData row;
  final bool enabled;
  final bool showRemaining;
  final bool showCollected;

  @override
  Widget build(BuildContext context) {
    final valueStyle = AppFormFields.valueStyle(context).copyWith(
      fontSize: 11,
      height: 1.1,
    );
    final flex = showCollected
        ? const [10, 8, 10, 10, 9, 11, 11, 8, 11]
        : showRemaining
            ? const [12, 10, 11, 11, 12, 11, 14]
            : const [14, 13, 14, 14, 18];

    var col = 0;
    Widget next(Widget child) => _CompactCell(flex: flex[col++], child: child);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        next(
          Text(
            row.size,
            style: valueStyle.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ),
        next(
          row.piecesController == null
              ? _CellText(
                  text: row.output.pieces > 0 ? '${row.output.pieces}' : '—',
                  style: valueStyle,
                )
              : TextFormField(
                  controller: row.piecesController,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: valueStyle,
                  textAlign: TextAlign.center,
                  decoration: _piecesDecoration(context),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final parsed = int.tryParse(value.trim());
                    if (parsed == null || parsed < 0) {
                      return AppStrings.piecesCannotBeNegative;
                    }
                    return null;
                  },
                ),
        ),
        if (showCollected)
          next(
            _CellText(
              text: '${row.collectedPieces ?? 0}',
              style: valueStyle.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        if (showRemaining)
          next(
            _CellText(
              text: '${row.remainingPieces ?? 0}',
              style: valueStyle.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        next(
          _CellText(
            text: row.output.squareFeet > 0
                ? row.output.squareFeet.toStringAsFixed(2)
                : '—',
            style: valueStyle,
          ),
        ),
        if (showCollected)
          next(
            _CellText(
              text: (row.collectedSquareFeet ?? 0).toStringAsFixed(2),
              style: valueStyle.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        if (showRemaining)
          next(
            _CellText(
              text: (row.remainingSquareFeet ?? 0).toStringAsFixed(2),
              style: valueStyle.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        next(
          _CellText(
            text: row.pricePerSqFt > 0
                ? row.pricePerSqFt.toStringAsFixed(0)
                : '—',
            style: valueStyle.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        next(
          _CellText(
            text: row.output.amount > 0
                ? _StockTableFormat.amount(row.output.amount)
                : '—',
            style: valueStyle.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  InputDecoration _piecesDecoration(BuildContext context) {
    return const InputDecoration(
      isDense: true,
      isCollapsed: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 7),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      filled: false,
    );
  }
}

class _CompactCell extends StatelessWidget {
  const _CompactCell({
    required this.flex,
    required this.child,
  });

  final int flex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: SizedBox(
            height: 32,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CellText extends StatelessWidget {
  const _CellText({
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        style: style,
        textAlign: TextAlign.center,
        maxLines: 1,
      ),
    );
  }
}

abstract final class _StockTableFormat {
  static String amount(double value) {
    final rounded = value.round();
    if ((value - rounded).abs() < 0.01) {
      return rounded.toString();
    }
    return value.toStringAsFixed(2);
  }
}

class _SectionTotalsBar extends StatelessWidget {
  const _SectionTotalsBar({
    required this.sectionLabel,
    required this.totalPieces,
    required this.totalSquareFeet,
    required this.totalAmount,
    this.remainingPieces,
    this.remainingSquareFeet,
    this.collectedPieces,
    this.collectedSquareFeet,
  });

  final String sectionLabel;
  final int totalPieces;
  final double totalSquareFeet;
  final double totalAmount;
  final int? remainingPieces;
  final double? remainingSquareFeet;
  final int? collectedPieces;
  final double? collectedSquareFeet;

  bool get _showRemaining =>
      remainingPieces != null && remainingSquareFeet != null;

  bool get _showCollected =>
      collectedPieces != null && collectedSquareFeet != null;

  @override
  Widget build(BuildContext context) {
    final outline =
        Theme.of(context).colorScheme.outline.withValues(alpha: 0.2);

    final List<String> headerCells;
    final List<String> valueCells;
    if (_showCollected) {
      headerCells = [
        sectionLabel,
        AppStrings.totalPieces,
        AppStrings.collectedPiecesShort,
        AppStrings.remainingPiecesShort,
        AppStrings.totalSqFtLabel,
        AppStrings.collectedSquareFeetShort,
        AppStrings.remainingSquareFeetShort,
        AppStrings.totalAmountLabel,
      ];
      valueCells = [
        sectionLabel,
        totalPieces.toString(),
        collectedPieces!.toString(),
        remainingPieces!.toString(),
        totalSquareFeet.toStringAsFixed(2),
        collectedSquareFeet!.toStringAsFixed(2),
        remainingSquareFeet!.toStringAsFixed(2),
        _StockTableFormat.amount(totalAmount),
      ];
    } else if (_showRemaining) {
      headerCells = [
        sectionLabel,
        AppStrings.totalPieces,
        AppStrings.remainingPiecesShort,
        AppStrings.totalSqFtLabel,
        AppStrings.remainingSquareFeetShort,
        AppStrings.totalAmountLabel,
      ];
      valueCells = [
        sectionLabel,
        totalPieces.toString(),
        remainingPieces!.toString(),
        totalSquareFeet.toStringAsFixed(2),
        remainingSquareFeet!.toStringAsFixed(2),
        _StockTableFormat.amount(totalAmount),
      ];
    } else {
      headerCells = [
        sectionLabel,
        AppStrings.totalPieces,
        AppStrings.totalSqFtLabel,
        AppStrings.totalAmountLabel,
      ];
      valueCells = [
        sectionLabel,
        totalPieces.toString(),
        totalSquareFeet.toStringAsFixed(2),
        _StockTableFormat.amount(totalAmount),
      ];
    }

    final bar = DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .secondaryContainer
            .withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: outline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            _SectionTotalsRow(
              cells: headerCells,
              isHeader: true,
              showRemaining: _showRemaining,
              showCollected: _showCollected,
            ),
            Divider(height: 1, thickness: 1, color: outline),
            _SectionTotalsRow(
              cells: valueCells,
              isHeader: false,
              highlightLast: true,
              showRemaining: _showRemaining,
              showCollected: _showCollected,
            ),
          ],
        ),
      ),
    );

    if (!_showCollected) return bar;

    final minWidth = math.max(
      MediaQuery.sizeOf(context).width - 48,
      780.0,
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth),
        child: SizedBox(width: minWidth, child: bar),
      ),
    );
  }
}

class _SectionTotalsRow extends StatelessWidget {
  const _SectionTotalsRow({
    required this.cells,
    required this.isHeader,
    this.highlightLast = false,
    this.showRemaining = false,
    this.showCollected = false,
  });

  final List<String> cells;
  final bool isHeader;
  final bool highlightLast;
  final bool showRemaining;
  final bool showCollected;

  List<int> get _flex => showCollected
      ? const [12, 10, 11, 11, 11, 12, 12, 12]
      : showRemaining
          ? const [14, 12, 13, 13, 14, 14]
          : const [16, 14, 15, 15];

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          height: 1.15,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    final valueStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 1.15,
        );
    final flex = _flex;

    return Container(
      color: isHeader
          ? Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.5)
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: isHeader ? 22 : 20,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.22),
              ),
            Expanded(
              flex: flex[i],
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  cells[i],
                  style: isHeader
                      ? headerStyle
                      : valueStyle?.copyWith(
                          fontWeight:
                              i == 0 ? FontWeight.w700 : FontWeight.w600,
                          color: highlightLast && i == cells.length - 1
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GrandTotalsCard extends StatelessWidget {
  const _GrandTotalsCard({
    required this.totalPieces,
    required this.totalSquareFeet,
    required this.grandCuttingTotal,
    this.remainingPieces,
    this.remainingSquareFeet,
    this.collectedPieces,
    this.collectedSquareFeet,
  });

  final int totalPieces;
  final double totalSquareFeet;
  final double grandCuttingTotal;
  final int? remainingPieces;
  final double? remainingSquareFeet;
  final int? collectedPieces;
  final double? collectedSquareFeet;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          children: [
            AppFormSummaryRow(
              label: AppStrings.totalPieces,
              value: totalPieces.toString(),
            ),
            if (collectedPieces != null) ...[
              AppFormFields.gap,
              AppFormSummaryRow(
                label: AppStrings.piecesCollected,
                value: collectedPieces.toString(),
              ),
            ],
            if (remainingPieces != null) ...[
              AppFormFields.gap,
              AppFormSummaryRow(
                label: AppStrings.piecesRemaining,
                value: remainingPieces.toString(),
              ),
            ],
            AppFormFields.gap,
            AppFormSummaryRow(
              label: AppStrings.totalSquareFeet,
              value: '${totalSquareFeet.toStringAsFixed(2)} sq. ft',
            ),
            if (collectedSquareFeet != null) ...[
              AppFormFields.gap,
              AppFormSummaryRow(
                label: AppStrings.squareFeetCollected,
                value: '${collectedSquareFeet!.toStringAsFixed(2)} sq. ft',
              ),
            ],
            if (remainingSquareFeet != null) ...[
              AppFormFields.gap,
              AppFormSummaryRow(
                label: AppStrings.squareFeetRemaining,
                value: '${remainingSquareFeet!.toStringAsFixed(2)} sq. ft',
              ),
            ],
            AppFormFields.gap,
            AppFormSummaryRow(
              label: AppStrings.grandCuttingTotal,
              value: Formatters.currencyPkr(grandCuttingTotal),
              highlight: true,
            ),
          ],
        ),
      ),
    );
  }
}

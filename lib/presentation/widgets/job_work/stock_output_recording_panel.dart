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
    super.key,
  });

  final List<StockOutput> smallOutputs;
  final List<StockOutput> largeOutputs;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (activeSmall.isNotEmpty)
          _ReadOnlyStockSection(
            title: AppStrings.smallSizes,
            outputs: activeSmall,
            totalSquareFeet:
                StockOutputCalculator.totalSquareFeet(activeSmall),
            totalAmount: StockOutputCalculator.grandTotal(activeSmall),
            totalPieces: StockOutputCalculator.totalPieces(activeSmall),
          ),
        if (activeLarge.isNotEmpty) ...[
          if (activeSmall.isNotEmpty) const SizedBox(height: 14),
          _ReadOnlyStockSection(
            title: AppStrings.largeSizes,
            outputs: activeLarge,
            totalSquareFeet:
                StockOutputCalculator.totalSquareFeet(activeLarge),
            totalAmount: StockOutputCalculator.grandTotal(activeLarge),
            totalPieces: StockOutputCalculator.totalPieces(activeLarge),
          ),
        ],
        const SizedBox(height: 10),
        _GrandTotalsCard(
          totalPieces: StockOutputCalculator.totalPieces(allActive),
          totalSquareFeet: StockOutputCalculator.totalSquareFeet(allActive),
          grandCuttingTotal: StockOutputCalculator.grandTotal(allActive),
        ),
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
  });

  final String title;
  final List<StockOutput> outputs;
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
          rows: outputs
              .map(
                (output) => _StockRowData(
                  size: output.size,
                  output: output,
                  pricePerSqFt: output.pricePerSqFt,
                ),
              )
              .toList(),
          enabled: false,
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

class _StockRowData {
  const _StockRowData({
    required this.size,
    required this.output,
    required this.pricePerSqFt,
    this.piecesController,
  });

  final String size;
  final StockOutput output;
  final double pricePerSqFt;
  final TextEditingController? piecesController;
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
  });

  final List<_StockRowData> rows;
  final bool enabled;

  static const _outlineAlpha = 0.24;
  static const _rowGap = 4.0;

  @override
  Widget build(BuildContext context) {
    final outline =
        Theme.of(context).colorScheme.outline.withValues(alpha: _outlineAlpha);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            _TableHeaderRow(),
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
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 9,
          height: 1.1,
        );

    return Container(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.55),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      child: Row(
        children: [
          _HeaderCell(label: AppStrings.stockSize, flex: 14, style: style),
          _HeaderCell(label: AppStrings.pieces, flex: 13, style: style),
          _HeaderCell(label: AppStrings.sqFtShort, flex: 14, style: style),
          _HeaderCell(label: AppStrings.pricePerSqFt, flex: 14, style: style),
          _HeaderCell(label: AppStrings.amount, flex: 18, style: style),
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
  });

  final _StockRowData row;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final valueStyle = AppFormFields.valueStyle(context).copyWith(
      fontSize: 11,
      height: 1.1,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _CompactCell(
          flex: 14,
          child: Text(
            row.size,
            style: valueStyle.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ),
        _CompactCell(
          flex: 13,
          child: row.piecesController == null
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
        _CompactCell(
          flex: 14,
          child: _CellText(
            text: row.output.squareFeet > 0
                ? row.output.squareFeet.toStringAsFixed(2)
                : '—',
            style: valueStyle,
          ),
        ),
        _CompactCell(
          flex: 14,
          child: _CellText(
            text: row.pricePerSqFt > 0
                ? row.pricePerSqFt.toStringAsFixed(0)
                : '—',
            style: valueStyle.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        _CompactCell(
          flex: 18,
          child: _CellText(
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
    return InputDecoration(
      isDense: true,
      isCollapsed: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
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
  });

  final String sectionLabel;
  final int totalPieces;
  final double totalSquareFeet;
  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    final outline =
        Theme.of(context).colorScheme.outline.withValues(alpha: 0.2);

    return DecoratedBox(
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
              cells: [
                sectionLabel,
                AppStrings.totalPieces,
                AppStrings.totalSqFtLabel,
                AppStrings.totalAmountLabel,
              ],
              isHeader: true,
            ),
            Divider(height: 1, thickness: 1, color: outline),
            _SectionTotalsRow(
              cells: [
                sectionLabel,
                totalPieces.toString(),
                totalSquareFeet.toStringAsFixed(2),
                _StockTableFormat.amount(totalAmount),
              ],
              isHeader: false,
              highlightLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTotalsRow extends StatelessWidget {
  const _SectionTotalsRow({
    required this.cells,
    required this.isHeader,
    this.highlightLast = false,
  });

  final List<String> cells;
  final bool isHeader;
  final bool highlightLast;

  static const _flex = [16, 14, 15, 15];

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
                color:
                    Theme.of(context).colorScheme.outline.withValues(alpha: 0.22),
              ),
            Expanded(
              flex: _flex[i],
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  cells[i],
                  style: isHeader
                      ? headerStyle
                      : valueStyle?.copyWith(
                          fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w600,
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
  });

  final int totalPieces;
  final double totalSquareFeet;
  final double grandCuttingTotal;

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
            AppFormFields.gap,
            AppFormSummaryRow(
              label: AppStrings.totalSquareFeet,
              value: '${totalSquareFeet.toStringAsFixed(2)} sq. ft',
            ),
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

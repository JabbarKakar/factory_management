import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/stock_output.dart';
import '../forms/app_form_fields.dart';
import 'sales_stock_form_controller.dart';

class SalesStockRecordingPanel extends StatefulWidget {
  const SalesStockRecordingPanel({
    required this.controller,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final SalesStockFormController controller;
  final VoidCallback onChanged;
  final bool enabled;

  @override
  State<SalesStockRecordingPanel> createState() =>
      _SalesStockRecordingPanelState();
}

class _SalesStockRecordingPanelState extends State<SalesStockRecordingPanel> {
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
          _SalesStockSection(
            title: AppStrings.smallSizes,
            isSmall: true,
            sizes: controller.smallSizes,
            controller: controller,
            enabled: widget.enabled,
            onChanged: widget.onChanged,
            totalSquareFeet: controller.smallTotalSquareFeet,
            totalAmount: controller.smallTotalAmount,
            totalPieces: controller.smallTotalPieces,
          ),
        if (controller.largeSizes.isNotEmpty) ...[
          if (controller.smallSizes.isNotEmpty) const SizedBox(height: 14),
          _SalesStockSection(
            title: AppStrings.largeSizes,
            isSmall: false,
            sizes: controller.largeSizes,
            controller: controller,
            enabled: widget.enabled,
            onChanged: widget.onChanged,
            totalSquareFeet: controller.largeTotalSquareFeet,
            totalAmount: controller.largeTotalAmount,
            totalPieces: controller.largeTotalPieces,
          ),
        ],
      ],
    );
  }
}

class _SalesStockSection extends StatelessWidget {
  const _SalesStockSection({
    required this.title,
    required this.isSmall,
    required this.sizes,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.totalSquareFeet,
    required this.totalAmount,
    required this.totalPieces,
  });

  final String title;
  final bool isSmall;
  final List<String> sizes;
  final SalesStockFormController controller;
  final bool enabled;
  final VoidCallback onChanged;
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
        _SalesStockTable(
          rows: sizes
              .map(
                (size) => _SalesStockRowData(
                  size: size,
                  output: controller.outputForSize(size),
                  sqFtController: controller.sqFtControllerFor(size),
                ),
              )
              .toList(),
          enabled: enabled,
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        _SectionTotalsBar(
          sectionLabel: isSmall ? AppStrings.smallStock : AppStrings.largeStock,
          totalPieces: totalPieces,
          totalSquareFeet: totalSquareFeet,
          totalAmount: totalAmount,
        ),
      ],
    );
  }
}

class _SalesStockRowData {
  const _SalesStockRowData({
    required this.size,
    required this.output,
    required this.sqFtController,
  });

  final String size;
  final StockOutput output;
  final TextEditingController sqFtController;
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

class _SalesStockTable extends StatelessWidget {
  const _SalesStockTable({
    required this.rows,
    required this.enabled,
    required this.onChanged,
  });

  final List<_SalesStockRowData> rows;
  final bool enabled;
  final VoidCallback onChanged;

  static const _outlineAlpha = 0.24;

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
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                child: _SalesStockDataRow(
                  row: rows[i],
                  enabled: enabled,
                  onChanged: onChanged,
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
          _HeaderCell(label: AppStrings.sqFtShort, flex: 16, style: style),
          _HeaderCell(label: AppStrings.pieces, flex: 14, style: style),
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
        ),
      ),
    );
  }
}

class _SalesStockDataRow extends StatelessWidget {
  const _SalesStockDataRow({
    required this.row,
    required this.enabled,
    required this.onChanged,
  });

  final _SalesStockRowData row;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final valueStyle = AppFormFields.valueStyle(context).copyWith(
      fontSize: 11,
      height: 1.1,
    );
    final hasSqFt = row.output.squareFeet > 0;

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
          flex: 16,
          child: TextFormField(
            controller: row.sqFtController,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            style: valueStyle,
            textAlign: TextAlign.center,
            decoration: _cellDecoration(),
            onChanged: (_) => onChanged(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              final parsed = double.tryParse(value.trim());
              if (parsed == null || parsed < 0) {
                return AppStrings.sqFtCannotBeNegative;
              }
              return null;
            },
          ),
        ),
        _CompactCell(
          flex: 14,
          child: _CellText(
            text: hasSqFt ? '${row.output.pieces}' : '—',
            style: valueStyle,
          ),
        ),
        _CompactCell(
          flex: 18,
          child: _CellText(
            text: row.output.amount > 0
                ? _formatAmount(row.output.amount)
                : '—',
            style: valueStyle.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  InputDecoration _cellDecoration() {
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

  String _formatAmount(double value) {
    final rounded = value.round();
    if ((value - rounded).abs() < 0.01) return rounded.toString();
    return value.toStringAsFixed(2);
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
                _formatAmount(totalAmount),
              ],
              isHeader: false,
              highlightLast: true,
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double value) {
    final rounded = value.round();
    if ((value - rounded).abs() < 0.01) return rounded.toString();
    return value.toStringAsFixed(2);
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

class SalesOrderStockTotalsCard extends StatelessWidget {
  const SalesOrderStockTotalsCard({
    required this.totalPieces,
    required this.totalSquareFeet,
    required this.grandTotal,
    super.key,
  });

  final int totalPieces;
  final double totalSquareFeet;
  final double grandTotal;

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
              label: AppStrings.grandTotal,
              value: Formatters.currencyPkr(grandTotal),
              highlight: true,
            ),
          ],
        ),
      ),
    );
  }
}

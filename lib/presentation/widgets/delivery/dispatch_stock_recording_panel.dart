import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_strings.dart';
import '../forms/app_form_fields.dart';
import 'dispatch_stock_form_controller.dart';

enum DispatchStockPanelMode { schedule, confirm, readOnly }

class DispatchStockRecordingPanel extends StatefulWidget {
  const DispatchStockRecordingPanel({
    required this.controller,
    required this.onChanged,
    this.enabled = true,
    this.mode = DispatchStockPanelMode.schedule,
    super.key,
  });

  final DispatchStockFormController controller;
  final VoidCallback onChanged;
  final bool enabled;
  final DispatchStockPanelMode mode;

  @override
  State<DispatchStockRecordingPanel> createState() =>
      _DispatchStockRecordingPanelState();
}

class _DispatchStockRecordingPanelState
    extends State<DispatchStockRecordingPanel> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListenerSafe(_handleChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListenerSafe(_handleChanged);
    super.dispose();
  }

  void _handleChanged() {
    widget.onChanged();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    if (!controller.hasRows) {
      return Text(
        AppStrings.noRemainingStock,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.orderDispatchTotals != null &&
            widget.mode != DispatchStockPanelMode.readOnly) ...[
          _DispatchOrderSummaryCard(
            totalPieces: controller.orderDispatchTotals!.totalPieces,
            totalSquareFeet: controller.orderDispatchTotals!.totalSquareFeet,
            remainingPieces: widget.mode == DispatchStockPanelMode.confirm
                ? controller.remainingPiecesAfterDispatch(
                    controller.totalDeliveredPieces,
                  )
                : controller.remainingPiecesAfterDispatch(
                    controller.totalDispatchPieces,
                  ),
            remainingSquareFeet: widget.mode == DispatchStockPanelMode.confirm
                ? controller.remainingSquareFeetAfterDispatch(
                    controller.totalDeliveredSquareFeet,
                  )
                : controller.remainingSquareFeetAfterDispatch(
                    controller.totalDispatchSquareFeet,
                  ),
          ),
          const SizedBox(height: 12),
        ],
        for (var i = 0; i < controller.groups.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _LineItemGroupSection(
            group: controller.groups[i],
            enabled: widget.enabled,
            mode: widget.mode,
          ),
        ],
        if (widget.mode != DispatchStockPanelMode.readOnly) ...[
          const SizedBox(height: 10),
          _DispatchGrandTotalsCard(
            totalPieces: widget.mode == DispatchStockPanelMode.confirm
                ? controller.totalDeliveredPieces
                : controller.totalDispatchPieces,
            totalSquareFeet: widget.mode == DispatchStockPanelMode.confirm
                ? controller.totalDeliveredSquareFeet
                : controller.totalDispatchSquareFeet,
          ),
        ],
      ],
    );
  }
}

class _LineItemGroupSection extends StatelessWidget {
  const _LineItemGroupSection({
    required this.group,
    required this.enabled,
    required this.mode,
  });

  final DispatchLineItemGroup group;
  final bool enabled;
  final DispatchStockPanelMode mode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${group.productType.label} — ${group.marbleVariety}',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
        ),
        if (group.smallRows.isNotEmpty) ...[
          const SizedBox(height: 8),
          _DispatchStockSection(
            title: AppStrings.smallSizes,
            rows: group.smallRows,
            enabled: enabled,
            mode: mode,
            sectionLabel: AppStrings.smallStock,
          ),
        ],
        if (group.largeRows.isNotEmpty) ...[
          const SizedBox(height: 14),
          _DispatchStockSection(
            title: AppStrings.largeSizes,
            rows: group.largeRows,
            enabled: enabled,
            mode: mode,
            sectionLabel: AppStrings.largeStock,
          ),
        ],
      ],
    );
  }
}

class _DispatchStockSection extends StatelessWidget {
  const _DispatchStockSection({
    required this.title,
    required this.rows,
    required this.enabled,
    required this.mode,
    required this.sectionLabel,
  });

  final String title;
  final List<DispatchStockRow> rows;
  final bool enabled;
  final DispatchStockPanelMode mode;
  final String sectionLabel;

  @override
  Widget build(BuildContext context) {
    final sectionOrderedPieces =
        rows.fold<int>(0, (sum, row) => sum + row.orderedPieces);
    final sectionOrderedSquareFeet =
        rows.fold<double>(0, (sum, row) => sum + row.orderedSquareFeet);
    final sectionRemainingPieces = rows.fold<int>(
      0,
      (sum, row) => sum + _remainingPiecesForRow(row),
    );
    final sectionRemainingSquareFeet = rows.fold<double>(
      0,
      (sum, row) => sum + _remainingSquareFeetForRow(row),
    );
    final dispatchPieces = switch (mode) {
      DispatchStockPanelMode.confirm =>
        rows.fold<int>(0, (sum, row) => sum + row.deliveredPieces),
      _ => rows.fold<int>(0, (sum, row) => sum + row.scheduledPieces),
    };
    final dispatchSquareFeet = switch (mode) {
      DispatchStockPanelMode.confirm => rows.fold<double>(
          0,
          (sum, row) => sum + row.deliveredSquareFeet,
        ),
      _ => rows.fold<double>(0, (sum, row) => sum + row.scheduledSquareFeet),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: title),
        const SizedBox(height: 6),
        _DispatchStockTable(
          rows: rows,
          enabled: enabled,
          mode: mode,
        ),
        const SizedBox(height: 8),
        _SectionTotalsBar(
          sectionLabel: sectionLabel,
          orderedPieces: sectionOrderedPieces,
          remainingPieces: sectionRemainingPieces,
          orderedSquareFeet: sectionOrderedSquareFeet,
          remainingSquareFeet: sectionRemainingSquareFeet,
        ),
        if (mode != DispatchStockPanelMode.readOnly) ...[
          const SizedBox(height: 8),
          _SectionDispatchTotalsBar(
            sectionLabel: sectionLabel,
            dispatchPieces: dispatchPieces,
            dispatchSquareFeet: dispatchSquareFeet,
          ),
        ],
      ],
    );
  }

  int _remainingPiecesForRow(DispatchStockRow row) {
    return switch (mode) {
      DispatchStockPanelMode.confirm => row.remainingPiecesAfterDelivered,
      _ => row.remainingPiecesAfterSchedule,
    };
  }

  double _remainingSquareFeetForRow(DispatchStockRow row) {
    return switch (mode) {
      DispatchStockPanelMode.confirm => row.remainingSquareFeetAfterDelivered,
      _ => row.remainingSquareFeetAfterSchedule,
    };
  }
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

class _DispatchStockTable extends StatelessWidget {
  const _DispatchStockTable({
    required this.rows,
    required this.enabled,
    required this.mode,
  });

  final List<DispatchStockRow> rows;
  final bool enabled;
  final DispatchStockPanelMode mode;

  static const _outlineAlpha = 0.24;
  static const _minTableWidthSchedule = 520.0;
  static const _minTableWidthConfirm = 680.0;

  @override
  Widget build(BuildContext context) {
    final outline =
        Theme.of(context).colorScheme.outline.withValues(alpha: _outlineAlpha);

    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = mode == DispatchStockPanelMode.confirm
            ? _minTableWidthConfirm
            : _minTableWidthSchedule;
        final tableWidth =
            constraints.maxWidth < minWidth ? minWidth : constraints.maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  children: [
                    _TableHeaderRow(mode: mode),
                    for (var i = 0; i < rows.length; i++) ...[
                      Divider(height: 1, thickness: 1, color: outline),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 4,
                        ),
                        child: _DispatchStockDataRow(
                          row: rows[i],
                          enabled: enabled,
                          mode: mode,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow({required this.mode});

  final DispatchStockPanelMode mode;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 9,
          height: 1.1,
        );

    final labels = switch (mode) {
      DispatchStockPanelMode.confirm => const [
          AppStrings.stockSize,
          AppStrings.totalPiecesShort,
          AppStrings.remainingPiecesShort,
          AppStrings.totalSquareFeetShort,
          AppStrings.remainingSquareFeetShort,
          AppStrings.scheduledPiecesShort,
          AppStrings.scheduledSquareFeetShort,
          AppStrings.dispatchPiecesShort,
          AppStrings.dispatchSquareFeetShort,
        ],
      DispatchStockPanelMode.readOnly => const [
          AppStrings.stockSize,
          AppStrings.totalPiecesShort,
          AppStrings.remainingPiecesShort,
          AppStrings.totalSquareFeetShort,
          AppStrings.remainingSquareFeetShort,
          AppStrings.dispatchPiecesShort,
          AppStrings.dispatchSquareFeetShort,
        ],
      _ => const [
          AppStrings.stockSize,
          AppStrings.totalPiecesShort,
          AppStrings.remainingPiecesShort,
          AppStrings.totalSquareFeetShort,
          AppStrings.remainingSquareFeetShort,
          AppStrings.dispatchPiecesShort,
          AppStrings.dispatchSquareFeetShort,
        ],
    };

    final flex = switch (mode) {
      DispatchStockPanelMode.confirm =>
        const [10, 8, 8, 9, 9, 8, 9, 8, 9],
      _ => const [10, 8, 8, 9, 9, 8, 9],
    };

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
        ),
      ),
    );
  }
}

class _DispatchStockDataRow extends StatelessWidget {
  const _DispatchStockDataRow({
    required this.row,
    required this.enabled,
    required this.mode,
  });

  final DispatchStockRow row;
  final bool enabled;
  final DispatchStockPanelMode mode;

  @override
  Widget build(BuildContext context) {
    final valueStyle = AppFormFields.valueStyle(context).copyWith(
      fontSize: 11,
      height: 1.1,
    );
    final remainingPieces = switch (mode) {
      DispatchStockPanelMode.confirm => row.remainingPiecesAfterDelivered,
      _ => row.remainingPiecesAfterSchedule,
    };
    final remainingSquareFeet = switch (mode) {
      DispatchStockPanelMode.confirm => row.remainingSquareFeetAfterDelivered,
      _ => row.remainingSquareFeetAfterSchedule,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: switch (mode) {
        DispatchStockPanelMode.readOnly => [
            _sizeCell(row.size, valueStyle),
            _metricCell('${row.orderedPieces}', valueStyle, flex: 8),
            _metricCell('$remainingPieces', valueStyle, flex: 8),
            _metricCell(
              row.orderedSquareFeet.toStringAsFixed(2),
              valueStyle,
              flex: 9,
            ),
            _metricCell(
              remainingSquareFeet.toStringAsFixed(2),
              valueStyle,
              flex: 9,
            ),
            _metricCell('${row.scheduledPieces}', valueStyle, flex: 8),
            _metricCell(
              row.scheduledSquareFeet > 0
                  ? row.scheduledSquareFeet.toStringAsFixed(2)
                  : '—',
              valueStyle,
              flex: 9,
            ),
          ],
        DispatchStockPanelMode.confirm => [
            _sizeCell(row.size, valueStyle),
            _metricCell('${row.orderedPieces}', valueStyle, flex: 8),
            _metricCell('$remainingPieces', valueStyle, flex: 8),
            _metricCell(
              row.orderedSquareFeet.toStringAsFixed(2),
              valueStyle,
              flex: 9,
            ),
            _metricCell(
              remainingSquareFeet.toStringAsFixed(2),
              valueStyle,
              flex: 9,
            ),
            _metricCell('${row.scheduledPieces}', valueStyle, flex: 8),
            _metricCell(
              row.scheduledSquareFeet.toStringAsFixed(2),
              valueStyle,
              flex: 9,
            ),
            _CompactCell(
              flex: 8,
              child: _InputCell(
                controller: row.piecesDeliveredController,
                enabled: enabled,
                style: valueStyle,
                validator: (value) => _validateDeliveredPieces(value, row),
              ),
            ),
            _metricCell(
              row.deliveredSquareFeet > 0
                  ? row.deliveredSquareFeet.toStringAsFixed(2)
                  : '—',
              valueStyle,
              flex: 9,
            ),
          ],
        DispatchStockPanelMode.schedule => [
            _sizeCell(row.size, valueStyle),
            _metricCell('${row.orderedPieces}', valueStyle, flex: 8),
            _metricCell('$remainingPieces', valueStyle, flex: 8),
            _metricCell(
              row.orderedSquareFeet.toStringAsFixed(2),
              valueStyle,
              flex: 9,
            ),
            _metricCell(
              remainingSquareFeet.toStringAsFixed(2),
              valueStyle,
              flex: 9,
            ),
            _CompactCell(
              flex: 8,
              child: _InputCell(
                controller: row.piecesController,
                enabled: enabled,
                style: valueStyle,
                validator: (value) => _validatePieces(value, row),
              ),
            ),
            _metricCell(
              row.scheduledSquareFeet > 0
                  ? row.scheduledSquareFeet.toStringAsFixed(2)
                  : '—',
              valueStyle,
              flex: 9,
            ),
          ],
      },
    );
  }

  Widget _metricCell(String text, TextStyle valueStyle, {required int flex}) {
    return _CompactCell(
      flex: flex,
      child: _CellText(text: text, style: valueStyle),
    );
  }

  Widget _sizeCell(String size, TextStyle valueStyle) {
    return _CompactCell(
      flex: 10,
      child: Text(
        size,
        style: valueStyle.copyWith(fontWeight: FontWeight.w700),
        textAlign: TextAlign.center,
      ),
    );
  }

  String? _validatePieces(String? value, DispatchStockRow row) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return AppStrings.piecesCannotBeNegative;
    }
    if (parsed > row.maxRemainingPieces) {
      return 'Max ${row.maxRemainingPieces} pcs';
    }
    final computedSqFt = row.outputForPieces(parsed).squareFeet;
    if (computedSqFt > row.maxRemainingSquareFeet + 0.001) {
      return 'Max ${row.maxRemainingSquareFeet.toStringAsFixed(2)} sq. ft';
    }
    return null;
  }

  String? _validateDeliveredPieces(String? value, DispatchStockRow row) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter delivered pieces';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return AppStrings.piecesCannotBeNegative;
    }
    if (parsed > row.scheduledPieces) {
      return 'Max ${row.scheduledPieces} pcs';
    }
    return null;
  }
}

class _InputCell extends StatelessWidget {
  const _InputCell({
    required this.controller,
    required this.enabled,
    required this.style,
    this.validator,
  });

  final TextEditingController controller;
  final bool enabled;
  final TextStyle style;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: style,
      textAlign: TextAlign.center,
      decoration: const InputDecoration(
        isDense: true,
        isCollapsed: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 7),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
      ),
      validator: validator,
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

class _SectionTotalsBar extends StatelessWidget {
  const _SectionTotalsBar({
    required this.sectionLabel,
    required this.orderedPieces,
    required this.remainingPieces,
    required this.orderedSquareFeet,
    required this.remainingSquareFeet,
  });

  final String sectionLabel;
  final int orderedPieces;
  final int remainingPieces;
  final double orderedSquareFeet;
  final double remainingSquareFeet;

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
                AppStrings.totalPiecesShort,
                AppStrings.remainingPiecesShort,
                AppStrings.totalSquareFeetShort,
                AppStrings.remainingSquareFeetShort,
              ],
              isHeader: true,
            ),
            Divider(height: 1, thickness: 1, color: outline),
            _SectionTotalsRow(
              cells: [
                sectionLabel,
                orderedPieces.toString(),
                remainingPieces.toString(),
                orderedSquareFeet.toStringAsFixed(2),
                remainingSquareFeet.toStringAsFixed(2),
              ],
              isHeader: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionDispatchTotalsBar extends StatelessWidget {
  const _SectionDispatchTotalsBar({
    required this.sectionLabel,
    required this.dispatchPieces,
    required this.dispatchSquareFeet,
  });

  final String sectionLabel;
  final int dispatchPieces;
  final double dispatchSquareFeet;

  @override
  Widget build(BuildContext context) {
    final outline =
        Theme.of(context).colorScheme.outline.withValues(alpha: 0.2);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.18),
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
                AppStrings.dispatchPiecesShort,
                AppStrings.dispatchSquareFeetShort,
              ],
              isHeader: true,
              flex: const [18, 14, 16],
            ),
            Divider(height: 1, thickness: 1, color: outline),
            _SectionTotalsRow(
              cells: [
                sectionLabel,
                dispatchPieces.toString(),
                dispatchSquareFeet.toStringAsFixed(2),
              ],
              isHeader: false,
              flex: const [18, 14, 16],
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
    this.flex = const [14, 12, 12, 13, 13],
  });

  final List<String> cells;
  final bool isHeader;
  final List<int> flex;

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
              flex: flex[i],
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  cells[i],
                  style: isHeader
                      ? headerStyle
                      : valueStyle?.copyWith(
                          fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w600,
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

class _DispatchOrderSummaryCard extends StatelessWidget {
  const _DispatchOrderSummaryCard({
    required this.totalPieces,
    required this.totalSquareFeet,
    required this.remainingPieces,
    required this.remainingSquareFeet,
  });

  final int totalPieces;
  final double totalSquareFeet;
  final int remainingPieces;
  final double remainingSquareFeet;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35),
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
              label: AppStrings.piecesRemaining,
              value: remainingPieces.toString(),
              highlight: remainingPieces > 0,
            ),
            AppFormFields.gap,
            AppFormSummaryRow(
              label: AppStrings.totalSquareFeet,
              value: '${totalSquareFeet.toStringAsFixed(2)} sq. ft',
            ),
            AppFormFields.gap,
            AppFormSummaryRow(
              label: AppStrings.squareFeetRemaining,
              value: '${remainingSquareFeet.toStringAsFixed(2)} sq. ft',
              highlight: remainingSquareFeet > 0,
            ),
          ],
        ),
      ),
    );
  }
}

class _DispatchGrandTotalsCard extends StatelessWidget {
  const _DispatchGrandTotalsCard({
    required this.totalPieces,
    required this.totalSquareFeet,
  });

  final int totalPieces;
  final double totalSquareFeet;

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
            Text(
              AppStrings.dispatchTotals,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            AppFormSummaryRow(
              label: AppStrings.totalPieces,
              value: totalPieces.toString(),
            ),
            AppFormFields.gap,
            AppFormSummaryRow(
              label: AppStrings.totalSquareFeet,
              value: '${totalSquareFeet.toStringAsFixed(2)} sq. ft',
              highlight: true,
            ),
          ],
        ),
      ),
    );
  }
}

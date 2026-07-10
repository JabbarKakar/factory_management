import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_strings.dart';
import '../forms/app_form_fields.dart';
import 'collect_material_form_controller.dart';

class CollectMaterialRecordingPanel extends StatelessWidget {
  const CollectMaterialRecordingPanel({
    required this.controller,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final CollectMaterialFormController controller;
  final VoidCallback onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!controller.hasRows) {
      return Text(
        AppStrings.noRemainingStockToCollect,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    final smallRows = controller.smallRows;
    final largeRows = controller.largeRows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.orderTotals != null) ...[
          _CollectOrderSummaryCard(
            totalPieces: controller.orderTotals!.totalPieces,
            totalSquareFeet: controller.orderTotals!.totalSquareFeet,
            remainingPieces: controller.remainingPiecesAfterCollect(
              controller.totalCollectPieces,
            ),
            remainingSquareFeet: controller.remainingSquareFeetAfterCollect(
              controller.totalCollectSquareFeet,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (smallRows.isNotEmpty) ...[
          _SizeGroupSection(
            title: AppStrings.smallStock,
            rows: smallRows,
            enabled: enabled,
            onChanged: onChanged,
          ),
        ],
        if (largeRows.isNotEmpty) ...[
          if (smallRows.isNotEmpty) const SizedBox(height: 14),
          _SizeGroupSection(
            title: AppStrings.largeStock,
            rows: largeRows,
            enabled: enabled,
            onChanged: onChanged,
          ),
        ],
        const SizedBox(height: 10),
        _CollectTotalsCard(
          totalPieces: controller.totalCollectPieces,
          totalSquareFeet: controller.totalCollectSquareFeet,
        ),
      ],
    );
  }
}

class _CollectOrderSummaryCard extends StatelessWidget {
  const _CollectOrderSummaryCard({
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.materialCollectionSummary,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${AppStrings.totalPieces}: $totalPieces',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: Text(
                  '${AppStrings.piecesRemaining}: $remainingPieces',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${AppStrings.totalSquareFeet}: '
                  '${totalSquareFeet.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: Text(
                  '${AppStrings.squareFeetRemaining}: '
                  '${remainingSquareFeet.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectTotalsCard extends StatelessWidget {
  const _CollectTotalsCard({
    required this.totalPieces,
    required this.totalSquareFeet,
  });

  final int totalPieces;
  final double totalSquareFeet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${AppStrings.collectTotals}: $totalPieces pcs',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${totalSquareFeet.toStringAsFixed(2)} sq. ft',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SizeGroupSection extends StatelessWidget {
  const _SizeGroupSection({
    required this.title,
    required this.rows,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final List<CollectMaterialRow> rows;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outline = theme.colorScheme.outline.withValues(alpha: 0.3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: outline),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _TableHeaderRow(),
              for (var i = 0; i < rows.length; i++) ...[
                Divider(height: 1, thickness: 1, color: outline),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 4,
                  ),
                  child: _CollectStockDataRow(
                    row: rows[i],
                    enabled: enabled,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
    const labels = [
      AppStrings.stockSize,
      AppStrings.totalPiecesShort,
      AppStrings.remainingPiecesShort,
      AppStrings.totalSquareFeetShort,
      AppStrings.remainingSquareFeetShort,
      AppStrings.collectPiecesShort,
      AppStrings.collectSquareFeetShort,
    ];
    const flex = [10, 8, 8, 9, 9, 8, 9];

    return Container(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.55),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              flex: flex[i],
              child: Text(
                labels[i],
                textAlign: i == 0 ? TextAlign.left : TextAlign.center,
                style: style,
              ),
            ),
        ],
      ),
    );
  }
}

class _CollectStockDataRow extends StatelessWidget {
  const _CollectStockDataRow({
    required this.row,
    required this.enabled,
    required this.onChanged,
  });

  final CollectMaterialRow row;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.bodySmall?.copyWith(fontSize: 11);

    return Row(
      children: [
        Expanded(
          flex: 10,
          child: Text(row.size, style: valueStyle),
        ),
        Expanded(
          flex: 8,
          child: Text(
            '${row.producedPieces}',
            textAlign: TextAlign.center,
            style: valueStyle,
          ),
        ),
        Expanded(
          flex: 8,
          child: Text(
            '${row.remainingPiecesAfterCollect}',
            textAlign: TextAlign.center,
            style: valueStyle,
          ),
        ),
        Expanded(
          flex: 9,
          child: Text(
            row.producedSquareFeet.toStringAsFixed(2),
            textAlign: TextAlign.center,
            style: valueStyle,
          ),
        ),
        Expanded(
          flex: 9,
          child: Text(
            row.remainingSquareFeetAfterCollect.toStringAsFixed(2),
            textAlign: TextAlign.center,
            style: valueStyle,
          ),
        ),
        Expanded(
          flex: 8,
          child: TextFormField(
            controller: row.piecesController,
            enabled: enabled,
            textAlign: TextAlign.center,
            style: AppFormFields.valueStyle(context).copyWith(fontSize: 12),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => onChanged(),
          ),
        ),
        Expanded(
          flex: 9,
          child: Text(
            row.collectSquareFeet > 0
                ? row.collectSquareFeet.toStringAsFixed(2)
                : '—',
            textAlign: TextAlign.center,
            style: valueStyle,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
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
        if (controller.smallSizes.isNotEmpty) ...[
          _SectionHeader(title: AppStrings.smallSizes),
          const SizedBox(height: 8),
          _StockTable(
            sizes: controller.smallSizes,
            controller: controller,
            enabled: widget.enabled,
          ),
        ],
        if (controller.largeSizes.isNotEmpty) ...[
          if (controller.smallSizes.isNotEmpty) const SizedBox(height: 16),
          _SectionHeader(title: AppStrings.largeSizes),
          const SizedBox(height: 8),
          _StockTable(
            sizes: controller.largeSizes,
            controller: controller,
            enabled: widget.enabled,
          ),
        ],
        const SizedBox(height: 12),
        _TotalsCard(
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
    final allActive = [...activeSmall, ...activeLarge];

    if (allActive.isEmpty) {
      return Text(
        AppStrings.noStockProductionYet,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (activeSmall.isNotEmpty) ...[
          const _SectionHeader(title: AppStrings.smallSizes),
          const SizedBox(height: 8),
          _ReadOnlyStockTable(outputs: activeSmall),
        ],
        if (activeLarge.isNotEmpty) ...[
          if (activeSmall.isNotEmpty) const SizedBox(height: 16),
          const _SectionHeader(title: AppStrings.largeSizes),
          const SizedBox(height: 8),
          _ReadOnlyStockTable(outputs: activeLarge),
        ],
        const SizedBox(height: 12),
        _TotalsCard(
          totalPieces: allActive.fold<int>(0, (sum, o) => sum + o.pieces),
          totalSquareFeet: allActive.fold<double>(0, (sum, o) => sum + o.squareFeet),
          grandCuttingTotal: allActive.fold<double>(0, (sum, o) => sum + o.amount),
        ),
      ],
    );
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

class _StockTable extends StatelessWidget {
  const _StockTable({
    required this.sizes,
    required this.controller,
    required this.enabled,
  });

  final List<String> sizes;
  final StockOutputFormController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _TableHeaderRow(),
          for (var i = 0; i < sizes.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.18),
              ),
            _StockEntryRow(
              size: sizes[i],
              controller: controller,
              enabled: enabled,
            ),
          ],
        ],
      ),
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 10,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(AppStrings.stockSize, style: style)),
          Expanded(flex: 3, child: Text(AppStrings.pieces, style: style)),
          Expanded(flex: 3, child: Text(AppStrings.sqFtShort, style: style)),
          Expanded(
            flex: 3,
            child: Text(AppStrings.pricePerSqFt, style: style),
          ),
          Expanded(flex: 3, child: Text(AppStrings.amount, style: style)),
        ],
      ),
    );
  }
}

class _StockEntryRow extends StatelessWidget {
  const _StockEntryRow({
    required this.size,
    required this.controller,
    required this.enabled,
  });

  final String size;
  final StockOutputFormController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final output = controller.outputForSize(size);
    final valueStyle = AppFormFields.valueStyle(context).copyWith(fontSize: 12);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              size,
              style: valueStyle.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: controller.piecesControllerFor(size),
              enabled: enabled,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: valueStyle,
              decoration: _cellDecoration(context),
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
          Expanded(
            flex: 3,
            child: Text(
              output.squareFeet.toStringAsFixed(2),
              style: valueStyle,
            ),
          ),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: controller.priceControllerFor(size),
              enabled: enabled,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: valueStyle,
              decoration: _cellDecoration(context),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final parsed = double.tryParse(value.trim());
                if (parsed == null || parsed < 0) {
                  return AppStrings.priceCannotBeNegative;
                }
                return null;
              },
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              Formatters.currencyPkr(output.amount),
              style: valueStyle.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _cellDecoration(BuildContext context) {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _ReadOnlyStockTable extends StatelessWidget {
  const _ReadOnlyStockTable({required this.outputs});

  final List<StockOutput> outputs;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _TableHeaderRow(),
          for (var i = 0; i < outputs.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.18),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      outputs[i].size,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('${outputs[i].pieces}', style: const TextStyle(fontSize: 12)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      outputs[i].squareFeet.toStringAsFixed(2),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      outputs[i].pricePerSqFt.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      Formatters.currencyPkr(outputs[i].amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
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
        borderRadius: BorderRadius.circular(10),
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

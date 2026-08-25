import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/stock_reconciliation_service.dart';
import '../../utils/auth_context.dart';

/// Diagnostic view for S38: shows every stock position next to the level its own
/// movement history implies, so any drift is visible and attributable.
///
/// Each run reads the two stock collections and both movement collections in
/// full, which is why this is a manually triggered debug screen rather than
/// something on a dashboard.
class StockReconciliationScreen extends StatefulWidget {
  const StockReconciliationScreen({super.key});

  @override
  State<StockReconciliationScreen> createState() =>
      _StockReconciliationScreenState();
}

class _StockReconciliationScreenState extends State<StockReconciliationScreen> {
  final _service = StockReconciliationService();
  final _quantityFormat = NumberFormat('#,##0.##');
  final _currencyFormat = NumberFormat('#,##0.##');

  StockReconciliationReport? _report;
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final factoryId = readFactoryId(context);
    if (factoryId == null) {
      setState(() => _errorMessage = 'No factory in context.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final report = await _service.run(factoryId);
      if (!mounted) return;
      setState(() {
        _report = report;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock reconciliation'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _run,
            icon: const Icon(Icons.refresh),
            tooltip: 'Re-run',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                )
              : report == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _Summary(report: report),
                        const SizedBox(height: 16),
                        _Section(
                          title: 'Raw materials',
                          rows: report.rawMaterials,
                          quantityFormat: _quantityFormat,
                          currencyFormat: _currencyFormat,
                        ),
                        const SizedBox(height: 16),
                        _Section(
                          title: 'Finished goods',
                          rows: report.finishedGoods,
                          quantityFormat: _quantityFormat,
                          currencyFormat: _currencyFormat,
                        ),
                      ],
                    ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.report});

  final StockReconciliationReport report;

  @override
  Widget build(BuildContext context) {
    final drifting = report.drifting;
    final unmigrated = report.unmigrated;
    final balanced = drifting.isEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  balanced ? Icons.check_circle_outline : Icons.warning_amber,
                  color: balanced ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    balanced
                        ? 'Every position matches its movement history'
                        : '${drifting.length} position(s) drifted from their '
                            'movement history',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${report.all.length} positions checked · '
              '${report.openingBalanceCount} opening balance(s) with no '
              'movements · ${unmigrated.length} not yet carrying stored totals',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Generated ${DateFormat('d MMM y, HH:mm:ss').format(report.generatedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.rows,
    required this.quantityFormat,
    required this.currencyFormat,
  });

  final String title;
  final List<StockReconciliationRow> rows;
  final NumberFormat quantityFormat;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${rows.length})',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nothing recorded.'),
            ),
          )
        else
          ...rows.map(
            (row) => _Row(
              row: row,
              quantityFormat: quantityFormat,
              currencyFormat: currencyFormat,
            ),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.row,
    required this.quantityFormat,
    required this.currencyFormat,
  });

  final StockReconciliationRow row;
  final NumberFormat quantityFormat;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (statusColor, statusText) = switch (row) {
      _ when row.isUnattributable => (
          AppColors.dueSoon,
          'Opening balance — no movements to reconcile against',
        ),
      _ when row.isBalanced => (AppColors.success, 'Balanced'),
      _ => (
          AppColors.error,
          'Drift ${quantityFormat.format(row.drift)} ${row.unitLabel}',
        ),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(row.label, style: theme.textTheme.titleSmall),
                ),
                if (!row.hasStoredTotals)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      'pre-S38',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: AppColors.dueSoon),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Recorded ${quantityFormat.format(row.recordedQuantity)} '
              '${row.unitLabel} · ledger '
              '${quantityFormat.format(row.ledgerQuantity)} ${row.unitLabel} '
              'from ${row.movementCount} movement(s)',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'Value ${currencyFormat.format(row.recordedValue)} · unit cost '
              '${currencyFormat.format(row.unitCost)}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(
              statusText,
              style: theme.textTheme.labelMedium?.copyWith(color: statusColor),
            ),
          ],
        ),
      ),
    );
  }
}

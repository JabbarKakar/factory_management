import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../data/services/job_work_collection_quantity_helper.dart';

/// Read-only stock remaining table (Sales Dispatch Stock layout, Load-scoped).
class LoadStockRemainingPanel extends StatelessWidget {
  const LoadStockRemainingPanel({
    required this.lines,
    required this.totals,
    super.key,
  });

  final List<JobWorkCollectionRemainingLine> lines;
  final JobWorkCollectionTotals totals;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty && !totals.hasProducedStock) {
      return Text(
        AppStrings.noRemainingStockToCollect,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    final small = lines.where((line) => line.isSmall).toList();
    final large = lines.where((line) => !line.isSmall).toList();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryCard(totals: totals),
        if (small.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SizeTable(title: AppStrings.smallStock, lines: small),
        ],
        if (large.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SizeTable(title: AppStrings.largeStock, lines: large),
        ],
        if (lines.isEmpty && totals.hasProducedStock) ...[
          const SizedBox(height: 12),
          Text(
            AppStrings.fullyCollected,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totals});

  final JobWorkCollectionTotals totals;

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
                  '${AppStrings.totalPieces}: ${totals.totalPieces}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: Text(
                  '${AppStrings.piecesRemaining}: ${totals.remainingPieces}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: totals.remainingPieces > 0
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
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
                  '${totals.totalSquareFeet.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: Text(
                  '${AppStrings.squareFeetRemaining}: '
                  '${totals.remainingSquareFeet.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: totals.remainingSquareFeet > 0.001
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SizeTable extends StatelessWidget {
  const _SizeTable({required this.title, required this.lines});

  final String title;
  final List<JobWorkCollectionRemainingLine> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outline = theme.colorScheme.outline.withValues(alpha: 0.3);
    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurfaceVariant,
      fontSize: 10,
    );
    final cellStyle = theme.textTheme.bodySmall?.copyWith(fontSize: 11);

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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 520),
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 42,
                columnSpacing: 16,
                horizontalMargin: 12,
                columns: [
                  DataColumn(label: Text(AppStrings.stockSize, style: headerStyle)),
                  DataColumn(
                    label: Text(AppStrings.totalPiecesShort, style: headerStyle),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      AppStrings.remainingPiecesShort,
                      style: headerStyle,
                    ),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(AppStrings.totalSquareFeetShort, style: headerStyle),
                    numeric: true,
                  ),
                  DataColumn(
                    label: Text(
                      AppStrings.remainingSquareFeetShort,
                      style: headerStyle,
                    ),
                    numeric: true,
                  ),
                ],
                rows: [
                  for (final line in lines)
                    DataRow(
                      cells: [
                        DataCell(Text(line.size, style: cellStyle)),
                        DataCell(
                          Text('${line.producedPieces}', style: cellStyle),
                        ),
                        DataCell(
                          Text(
                            '${line.remainingPieces}',
                            style: cellStyle?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            line.producedSquareFeet.toStringAsFixed(2),
                            style: cellStyle,
                          ),
                        ),
                        DataCell(
                          Text(
                            line.remainingSquareFeet.toStringAsFixed(2),
                            style: cellStyle?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  DataRow(
                    cells: [
                      DataCell(
                        Text(
                          AppStrings.smallStock == title
                              ? AppStrings.smallStock
                              : AppStrings.largeStock,
                          style: cellStyle?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${lines.fold<int>(0, (s, l) => s + l.producedPieces)}',
                          style: cellStyle?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${lines.fold<int>(0, (s, l) => s + l.remainingPieces)}',
                          style: cellStyle?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          lines
                              .fold<double>(
                                0,
                                (s, l) => s + l.producedSquareFeet,
                              )
                              .toStringAsFixed(2),
                          style: cellStyle?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          lines
                              .fold<double>(
                                0,
                                (s, l) => s + l.remainingSquareFeet,
                              )
                              .toStringAsFixed(2),
                          style: cellStyle?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../blocs/pl/pl_report_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/monthly_pl_report.dart';
import '../../utils/auth_context.dart';
import '../../../core/di/injection.dart';
import '../../../data/services/export/pl_report_excel_exporter.dart';
import '../../../data/services/export/pl_report_pdf_exporter.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../utils/export_actions.dart';
import '../../utils/export_factory_name.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/export_menu_button.dart';
import '../../widgets/settings_section.dart';

class PlReportScreen extends StatelessWidget {
  const PlReportScreen({super.key});

  void _shiftMonth(BuildContext context, int delta) {
    final state = context.read<PlReportBloc>().state;
    if (delta > 0 && !state.canGoToNextMonth) return;

    final current = state.selectedMonth;
    final shifted = DateTime(current.year, current.month + delta);
    context.read<PlReportBloc>().add(PlReportMonthChanged(shifted));
  }

  @override
  Widget build(BuildContext context) {
    final canExport = context.userCanExport(AppModule.plReport);
    final pdfExporter = getIt<PlReportPdfExporter>();
    final excelExporter = getIt<PlReportExcelExporter>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.monthlyPlReport),
        actions: [
          if (canExport)
            BlocBuilder<PlReportBloc, PlReportState>(
              builder: (context, state) {
                if (state.status != PlReportStatus.loaded &&
                    !state.report.hasData) {
                  return const SizedBox.shrink();
                }
                final report = state.report;
                final monthKey =
                    '${report.year}_${report.month.toString().padLeft(2, '0')}';

                return ExportMenuButton(
                  onExportPdf: (origin) async {
                    final factoryName = await resolveExportFactoryName(context);
                    final doc = await pdfExporter.build(
                      report: report,
                      factoryName: factoryName,
                    );
                    await ExportActions.sharePdf(
                      document: doc,
                      filename: 'pl_report_$monthKey.pdf',
                      sharePositionOrigin: origin,
                    );
                  },
                  onExportExcel: (origin) async {
                    final bytes = excelExporter.build(report);
                    await ExportActions.shareExcel(
                      bytes: bytes,
                      filename: 'pl_report_$monthKey.xlsx',
                      sharePositionOrigin: origin,
                    );
                  },
                  onPrint: () async {
                    final factoryName = await resolveExportFactoryName(context);
                    final doc = await pdfExporter.build(
                      report: report,
                      factoryName: factoryName,
                    );
                    await ExportActions.printPdf(
                      document: doc,
                      filename: 'pl_report_$monthKey.pdf',
                    );
                  },
                );
              },
            ),
        ],
      ),
      body: BlocBuilder<PlReportBloc, PlReportState>(
        builder: (context, state) {
          if (state.status == PlReportStatus.loading &&
              !state.report.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == PlReportStatus.failure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.errorMessage ?? AppStrings.plReportLoadError,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final factoryId = readFactoryId(context);
                        if (factoryId != null) {
                          context.read<PlReportBloc>().add(
                                PlReportWatchStarted(factoryId),
                              );
                        }
                      },
                      child: const Text(AppStrings.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          final report = state.report;
          final monthLabel =
              DateFormat.yMMMM().format(state.selectedMonth);

          return RefreshIndicator(
            onRefresh: () async {
              final factoryId = readFactoryId(context);
              if (factoryId == null) return;
              context.read<PlReportBloc>().add(
                    PlReportWatchStarted(
                      factoryId,
                      initialMonth: state.selectedMonth,
                    ),
                  );
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _shiftMonth(context, -1),
                        icon: const Icon(Icons.chevron_left),
                        tooltip: AppStrings.previousMonth,
                      ),
                      Expanded(
                        child: Text(
                          monthLabel,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: state.canGoToNextMonth
                            ? () => _shiftMonth(context, 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                        tooltip: AppStrings.nextMonth,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _NetProfitCard(report: report),
                ),
                if (!report.hasData)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      AppStrings.plReportEmpty,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                SettingsSection(
                  title: AppStrings.revenue,
                  child: _LineGroup(
                    lines: [
                      _PlLine(
                        label: AppStrings.salesRevenue,
                        amount: report.salesRevenue,
                      ),
                      _PlLine(
                        label: AppStrings.jobWorkRevenue,
                        amount: report.jobWorkRevenue,
                      ),
                      _PlLine(
                        label: AppStrings.totalRevenue,
                        amount: report.totalRevenue,
                        bold: true,
                      ),
                    ],
                    footer: report.paymentCount > 0
                        ? '${report.paymentCount} ${AppStrings.paymentsRecorded}'
                        : null,
                  ),
                ),
                SettingsSection(
                  title: AppStrings.expenses,
                  child: report.expenseLines.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.noExpensesThisMonth,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              const Divider(height: 24),
                              _SummaryRow(
                                label: AppStrings.totalExpenses,
                                value: Formatters.currencyPkr(
                                  report.totalExpenses,
                                ),
                                bold: true,
                              ),
                            ],
                          ),
                        )
                      : _LineGroup(
                          lines: [
                            for (final line in report.expenseLines)
                              _PlLine(
                                label: line.category.label,
                                amount: line.amount,
                              ),
                            _PlLine(
                              label: AppStrings.totalExpenses,
                              amount: report.totalExpenses,
                              bold: true,
                            ),
                          ],
                          footer: report.expenseCount > 0
                              ? '${report.expenseCount} ${AppStrings.expenseEntriesThisMonth}'
                              : null,
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _SummaryRow(
                            label: report.netProfit >= 0
                                ? AppStrings.netProfit
                                : AppStrings.netLoss,
                            value: Formatters.currencyPkr(
                              report.netProfit.abs(),
                            ),
                            valueColor: report.netProfit >= 0
                                ? AppColors.success
                                : AppColors.error,
                            bold: true,
                          ),
                          if (report.totalRevenue > 0) ...[
                            const SizedBox(height: 8),
                            _SummaryRow(
                              label: AppStrings.netProfitMargin,
                              value:
                                  '${report.netProfitMargin.toStringAsFixed(1)}%',
                              bold: true,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppStrings.plReportFootnote,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NetProfitCard extends StatelessWidget {
  const _NetProfitCard({required this.report});

  final MonthlyPlReport report;

  @override
  Widget build(BuildContext context) {
    final isProfit = report.netProfit >= 0;
    final color = isProfit ? AppColors.success : AppColors.error;

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isProfit ? AppStrings.netProfit : AppStrings.netLoss,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              Formatters.currencyPkr(report.netProfit.abs()),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: AppStrings.revenue,
                    value: Formatters.currencyPkr(report.totalRevenue),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                    label: AppStrings.expenses,
                    value: Formatters.currencyPkr(report.totalExpenses),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _PlLine {
  const _PlLine({
    required this.label,
    required this.amount,
    this.bold = false,
  });

  final String label;
  final double amount;
  final bool bold;
}

class _LineGroup extends StatelessWidget {
  const _LineGroup({
    required this.lines,
    this.footer,
  });

  final List<_PlLine> lines;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (lines[i].bold && i > 0) const Divider(height: 24),
            _SummaryRow(
              label: lines[i].label,
              value: Formatters.currencyPkr(lines[i].amount),
              bold: lines[i].bold,
            ),
            if (i < lines.length - 1 && !lines[i + 1].bold)
              const SizedBox(height: 8),
          ],
          if (footer != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                footer!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: TextStyle(
              color: muted,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

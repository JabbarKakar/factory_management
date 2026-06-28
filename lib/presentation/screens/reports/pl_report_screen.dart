import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../blocs/pl/pl_report_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../data/services/export/pl_report_excel_exporter.dart';
import '../../../data/services/export/pl_report_pdf_exporter.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../utils/auth_context.dart';
import '../../utils/export_actions.dart';
import '../../utils/export_factory_name.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/export_menu_button.dart';
import '../../widgets/reports/pl_report_detail_hero.dart';
import '../../widgets/reports/pl_report_expenses_section.dart';
import '../../widgets/reports/pl_report_revenue_section.dart';
import '../../widgets/reports/report_month_navigator.dart';

class PlReportScreen extends StatelessWidget {
  const PlReportScreen({super.key});

  void _shiftMonth(BuildContext context, int delta) {
    final state = context.read<PlReportBloc>().state;
    if (delta > 0 && !state.canGoToNextMonth) return;

    final current = state.selectedMonth;
    final shifted = DateTime(current.year, current.month + delta);
    context.read<PlReportBloc>().add(PlReportMonthChanged(shifted));
  }

  void _retry(BuildContext context) {
    final factoryId = readFactoryId(context);
    if (factoryId != null) {
      context.read<PlReportBloc>().add(PlReportWatchStarted(factoryId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canExport = context.userCanExport(AppModule.plReport);
    final pdfExporter = getIt<PlReportPdfExporter>();
    final excelExporter = getIt<PlReportExcelExporter>();

    return BlocBuilder<PlReportBloc, PlReportState>(
      builder: (context, state) {
        final report = state.report;
        final monthLabel = DateFormat.yMMMM().format(state.selectedMonth);
        final isInitialLoad = (state.status == PlReportStatus.initial ||
                state.status == PlReportStatus.loading) &&
            !report.hasData;
        final isRefreshing =
            state.status == PlReportStatus.loading && report.hasData;
        final isLoaded = state.status == PlReportStatus.loaded ||
            (state.status == PlReportStatus.loading && report.hasData);
        final appBarForeground =
            Theme.of(context).appBarTheme.foregroundColor ??
                Theme.of(context).colorScheme.onSurface;
        final monthKey =
            '${report.year}_${report.month.toString().padLeft(2, '0')}';

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.monthlyPlReport),
                if (isLoaded)
                  Text(
                    monthLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: appBarForeground.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                  ),
              ],
            ),
            actions: [
              if (canExport && isLoaded)
                ExportMenuButton(
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
                ),
            ],
            bottom: isRefreshing
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(2),
                    child: LinearProgressIndicator(minHeight: 2),
                  )
                : null,
          ),
          body: isInitialLoad
              ? const Center(child: CircularProgressIndicator())
              : state.status == PlReportStatus.failure
                  ? EmptyStateView(
                      icon: Icons.error_outline,
                      title: state.errorMessage ?? AppStrings.plReportLoadError,
                      action: FilledButton.icon(
                        onPressed: () => _retry(context),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text(AppStrings.retry),
                      ),
                    )
                  : RefreshIndicator(
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
                          ReportMonthNavigator(
                            selectedMonth: state.selectedMonth,
                            onPrevious: () => _shiftMonth(context, -1),
                            onNext: state.canGoToNextMonth
                                ? () => _shiftMonth(context, 1)
                                : null,
                          ),
                          PlReportDetailHero(report: report),
                          if (!report.hasData)
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              child: Text(
                                AppStrings.plReportEmpty,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ),
                          PlReportRevenueSection(report: report),
                          PlReportExpensesSection(report: report),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: Text(
                              AppStrings.plReportFootnote,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 10,
                                    height: 1.35,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
        );
      },
    );
  }
}

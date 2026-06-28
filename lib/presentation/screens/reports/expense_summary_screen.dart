import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/services/expense_summary_service.dart';
import '../../../data/services/export/expense_summary_excel_exporter.dart';
import '../../../data/services/export/expense_summary_pdf_exporter.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/expense_summary_report.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../utils/auth_context.dart';
import '../../utils/export_actions.dart';
import '../../utils/export_factory_name.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/export_menu_button.dart';
import '../../widgets/reports/expense_summary_category_section.dart';
import '../../widgets/reports/expense_summary_detail_hero.dart';
import '../../widgets/reports/expense_summary_lines_section.dart';
import '../../widgets/reports/report_month_navigator.dart';

class ExpenseSummaryScreen extends StatefulWidget {
  const ExpenseSummaryScreen({super.key});

  @override
  State<ExpenseSummaryScreen> createState() => _ExpenseSummaryScreenState();
}

class _ExpenseSummaryScreenState extends State<ExpenseSummaryScreen> {
  final _repository = getIt<ExpenseRepository>();
  final _summaryService = ExpenseSummaryService();
  final _pdfExporter = ExpenseSummaryPdfExporter();
  final _excelExporter = ExpenseSummaryExcelExporter();

  StreamSubscription<List<Expense>>? _subscription;
  List<Expense> _expenses = const [];
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _loading = true;
  bool _initialized = false;
  String? _errorMessage;

  ExpenseSummaryReport get _report => _summaryService.build(
        year: _selectedMonth.year,
        month: _selectedMonth.month,
        expenses: _expenses,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startWatch());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _startWatch() {
    final factoryId = readFactoryId(context);
    if (factoryId == null) {
      setState(() {
        _loading = false;
        _errorMessage = AppStrings.expensesLoadError;
      });
      return;
    }

    _subscription?.cancel();
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    _subscription = _repository.watchExpenses(factoryId).listen(
      (expenses) {
        if (!mounted) return;
        setState(() {
          _expenses = expenses;
          _loading = false;
          _initialized = true;
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _errorMessage = AppStrings.expensesLoadError;
        });
      },
    );
  }

  void _shiftMonth(int delta) {
    final shifted = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    if (shifted.isAfter(currentMonth)) return;

    setState(() => _selectedMonth = shifted);
  }

  bool get _canGoToNextMonth {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    return !next.isAfter(currentMonth);
  }

  String _filenameMonthKey() {
    return '${_selectedMonth.year}_${_selectedMonth.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final canExport = context.userCanExport(AppModule.expenses);
    final monthLabel = DateFormat.yMMMM().format(_selectedMonth);
    final report = _report;
    final isInitialLoad = _loading && !_initialized;
    final isRefreshing = _loading && _initialized;
    final appBarForeground =
        Theme.of(context).appBarTheme.foregroundColor ??
            Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.expenseSummaryReport),
            if (_initialized)
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
          if (canExport && _initialized && _errorMessage == null)
            ExportMenuButton(
              onExportPdf: (origin) async {
                final factoryName = await resolveExportFactoryName(context);
                final doc = await _pdfExporter.build(
                  report: report,
                  factoryName: factoryName,
                );
                await ExportActions.sharePdf(
                  document: doc,
                  filename: 'expense_summary_${_filenameMonthKey()}.pdf',
                  sharePositionOrigin: origin,
                );
              },
              onExportExcel: (origin) async {
                final bytes = _excelExporter.build(report);
                await ExportActions.shareExcel(
                  bytes: bytes,
                  filename: 'expense_summary_${_filenameMonthKey()}.xlsx',
                  sharePositionOrigin: origin,
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
          : _errorMessage != null
              ? EmptyStateView(
                  icon: Icons.error_outline,
                  title: _errorMessage!,
                  action: FilledButton.icon(
                    onPressed: _startWatch,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text(AppStrings.retry),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _startWatch(),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      ReportMonthNavigator(
                        selectedMonth: _selectedMonth,
                        onPrevious: () => _shiftMonth(-1),
                        onNext:
                            _canGoToNextMonth ? () => _shiftMonth(1) : null,
                      ),
                      ExpenseSummaryDetailHero(report: report),
                      if (!report.hasData)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: Text(
                            AppStrings.noExpensesThisMonth,
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
                      if (report.categoryTotals.isNotEmpty)
                        ExpenseSummaryCategorySection(report: report),
                      if (report.lines.isNotEmpty)
                        ExpenseSummaryLinesSection(report: report),
                    ],
                  ),
                ),
    );
  }
}

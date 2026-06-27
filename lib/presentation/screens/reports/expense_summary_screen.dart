import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/services/expense_summary_service.dart';
import '../../../data/services/export/expense_summary_excel_exporter.dart';
import '../../../data/services/export/expense_summary_pdf_exporter.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/expense_summary_report.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../utils/export_actions.dart';
import '../../utils/export_factory_name.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/export_menu_button.dart';
import '../../widgets/settings_section.dart';
import '../../utils/auth_context.dart';

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

  @override
  Widget build(BuildContext context) {
    final canExport = context.userCanExport(AppModule.expenses);
    final monthLabel = DateFormat.yMMMM().format(_selectedMonth);
    final monthKey =
        '${_selectedMonth.year}_${_selectedMonth.month.toString().padLeft(2, '0')}';
    final report = _report;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.expenseSummaryReport),
        actions: [
          if (canExport && !_loading && _errorMessage == null)
            ExportMenuButton(
              onExportPdf: (origin) async {
                final factoryName = await resolveExportFactoryName(context);
                final doc = await _pdfExporter.build(
                  report: report,
                  factoryName: factoryName,
                );
                await ExportActions.sharePdf(
                  document: doc,
                  filename: 'expense_summary_$monthKey.pdf',
                  sharePositionOrigin: origin,
                );
              },
              onExportExcel: (origin) async {
                final bytes = _excelExporter.build(report);
                await ExportActions.shareExcel(
                  bytes: bytes,
                  filename: 'expense_summary_$monthKey.xlsx',
                  sharePositionOrigin: origin,
                );
              },
            ),
        ],
      ),
      body: _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _startWatch,
                      child: const Text(AppStrings.retry),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async => _startWatch(),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => _shiftMonth(-1),
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
                          onPressed:
                              _canGoToNextMonth ? () => _shiftMonth(1) : null,
                          icon: const Icon(Icons.chevron_right),
                          tooltip: AppStrings.nextMonth,
                        ),
                      ],
                    ),
                  ),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Card(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.35),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.totalExpenses,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                Formatters.currencyPkr(report.totalExpenses),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!report.hasData)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          AppStrings.noExpensesThisMonth,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ),
                    if (report.categoryTotals.isNotEmpty)
                      SettingsSection(
                        title: AppStrings.expensesByCategory,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              for (final entry in report.categoryTotals) ...[
                                _SummaryRow(
                                  label: entry.$1.label,
                                  value: Formatters.currencyPkr(entry.$2),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ],
                          ),
                        ),
                      ),
                    if (report.lines.isNotEmpty)
                      SettingsSection(
                        title: AppStrings.expenseDetails,
                        child: Column(
                          children: [
                            for (final line in report.lines)
                              ListTile(
                                title: Text(line.expense.description),
                                subtitle: Text(
                                  '${line.category.label} • ${DateFormat.yMMMd().format(line.expense.expenseDate)}',
                                ),
                                trailing: Text(
                                  Formatters.currencyPkr(line.amount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

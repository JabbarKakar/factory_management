import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/services/customer_statement_service.dart';
import '../../../data/services/export/customer_statement_excel_exporter.dart';
import '../../../data/services/export/customer_statement_pdf_exporter.dart';
import '../../../domain/entities/customer_statement.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../utils/export_actions.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/export_menu_button.dart';
import '../../widgets/settings_section.dart';

class CustomerStatementScreen extends StatefulWidget {
  const CustomerStatementScreen({required this.customerId, super.key});

  final String customerId;

  @override
  State<CustomerStatementScreen> createState() =>
      _CustomerStatementScreenState();
}

class _CustomerStatementScreenState extends State<CustomerStatementScreen> {
  final _statementService = getIt<CustomerStatementService>();
  final _pdfExporter = CustomerStatementPdfExporter();
  final _excelExporter = CustomerStatementExcelExporter();

  late DateTime _fromDate;
  late DateTime _toDate;

  CustomerStatement? _statement;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month);
    _toDate = now;
    _loadStatement();
  }

  Future<void> _loadStatement() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final statement = await _statementService.buildStatement(
        customerId: widget.customerId,
        fromDate: _fromDate,
        toDate: _toDate,
      );
      if (!mounted) return;
      setState(() {
        _statement = statement;
        _loading = false;
        if (statement == null) {
          _errorMessage = AppStrings.statementLoadError;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = AppStrings.statementLoadError;
      });
    }
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020),
      lastDate: _toDate,
    );
    if (picked != null) {
      setState(() => _fromDate = picked);
      await _loadStatement();
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: _fromDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _toDate = picked);
      await _loadStatement();
    }
  }

  String _filename(CustomerStatement statement) {
    final slug = statement.customer.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final from = DateFormat('yyyyMMdd').format(statement.fromDate);
    final to = DateFormat('yyyyMMdd').format(statement.toDate);
    return 'statement_${slug}_${from}_$to';
  }

  @override
  Widget build(BuildContext context) {
    final canExport = context.userCanExport(AppModule.customers);
    final statement = _statement;
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.customerStatement),
        actions: [
          if (canExport && statement != null)
            ExportMenuButton(
              onExportPdf: () async {
                final doc = await _pdfExporter.build(statement: statement);
                await ExportActions.sharePdf(
                  document: doc,
                  filename: '${_filename(statement)}.pdf',
                );
              },
              onExportExcel: () async {
                final bytes = _excelExporter.build(statement);
                await ExportActions.shareExcel(
                  bytes: bytes,
                  filename: '${_filename(statement)}.xlsx',
                );
              },
              onPrint: () async {
                final doc = await _pdfExporter.build(statement: statement);
                await ExportActions.printPdf(
                  document: doc,
                  filename: '${_filename(statement)}.pdf',
                );
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadStatement,
                          child: const Text(AppStrings.retry),
                        ),
                      ],
                    ),
                  ),
                )
              : statement == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: _loadStatement,
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          SettingsSection(
                            title: AppStrings.statementDateRange,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _DatePickerRow(
                                    label: AppStrings.fromDate,
                                    value: dateFormat.format(_fromDate),
                                    onTap: _pickFromDate,
                                  ),
                                  const SizedBox(height: 12),
                                  _DatePickerRow(
                                    label: AppStrings.toDate,
                                    value: dateFormat.format(_toDate),
                                    onTap: _pickToDate,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    statement.customer.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    statement.customer.phone,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SettingsSection(
                            title: AppStrings.accountLedger,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _SummaryRow(
                                    label: AppStrings.openingBalance,
                                    value: Formatters.currencyPkr(
                                      statement.openingBalance,
                                    ),
                                  ),
                                  const Divider(height: 24),
                                  if (statement.lines.isEmpty)
                                    Text(
                                      AppStrings.noStatementActivity,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    )
                                  else
                                    for (final line in statement.lines) ...[
                                      _StatementLineRow(
                                        line: line,
                                        dateFormat: dateFormat,
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  const Divider(height: 24),
                                  _SummaryRow(
                                    label: AppStrings.closingBalance,
                                    value: Formatters.currencyPkr(
                                      statement.closingBalance,
                                    ),
                                    bold: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.calendar_today_outlined, size: 18),
          ],
        ),
      ),
    );
  }
}

class _StatementLineRow extends StatelessWidget {
  const _StatementLineRow({
    required this.line,
    required this.dateFormat,
  });

  final CustomerStatementLine line;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final amountText = line.debit > 0
        ? '+${Formatters.currencyPkr(line.debit)}'
        : '-${Formatters.currencyPkr(line.credit)}';
    final amountColor = line.debit > 0
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.description,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${dateFormat.format(line.date)} · ${line.reference}',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          amountText,
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: muted,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600),
        ),
      ],
    );
  }
}

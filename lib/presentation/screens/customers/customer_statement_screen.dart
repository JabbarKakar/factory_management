import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../data/services/customer_statement_service.dart';
import '../../../data/services/export/customer_statement_excel_exporter.dart';
import '../../../data/services/export/customer_statement_pdf_exporter.dart';
import '../../../domain/entities/customer_statement.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../utils/export_actions.dart';
import '../../utils/export_factory_name.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/customers/customer_statement_date_range_section.dart';
import '../../widgets/customers/customer_statement_detail_hero.dart';
import '../../widgets/customers/customer_statement_ledger_section.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/export_menu_button.dart';

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
    final isInitialLoad = _loading && statement == null;
    final isRefreshing = _loading && statement != null;
    final appBarForeground =
        Theme.of(context).appBarTheme.foregroundColor ??
            Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.customerStatement),
            if (statement != null)
              Text(
                statement.customer.name,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: appBarForeground.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
              ),
          ],
        ),
        actions: [
          if (canExport && statement != null)
            ExportMenuButton(
              onExportPdf: (origin) async {
                final factoryName = await resolveExportFactoryName(context);
                final doc = await _pdfExporter.build(
                  statement: statement,
                  factoryName: factoryName,
                );
                await ExportActions.sharePdf(
                  document: doc,
                  filename: '${_filename(statement)}.pdf',
                  sharePositionOrigin: origin,
                );
              },
              onExportExcel: (origin) async {
                final bytes = _excelExporter.build(statement);
                await ExportActions.shareExcel(
                  bytes: bytes,
                  filename: '${_filename(statement)}.xlsx',
                  sharePositionOrigin: origin,
                );
              },
              onPrint: () async {
                final factoryName = await resolveExportFactoryName(context);
                final doc = await _pdfExporter.build(
                  statement: statement,
                  factoryName: factoryName,
                );
                await ExportActions.printPdf(
                  document: doc,
                  filename: '${_filename(statement)}.pdf',
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
                    onPressed: _loadStatement,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text(AppStrings.retry),
                  ),
                )
              : statement == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: _loadStatement,
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          CustomerStatementDetailHero(statement: statement),
                          CustomerStatementDateRangeSection(
                            fromDate: _fromDate,
                            toDate: _toDate,
                            onPickFrom: _pickFromDate,
                            onPickTo: _pickToDate,
                            enabled: !_loading,
                          ),
                          CustomerStatementLedgerSection(statement: statement),
                        ],
                      ),
                    ),
    );
  }
}

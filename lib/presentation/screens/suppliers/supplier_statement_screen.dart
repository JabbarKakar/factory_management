import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/repositories/raw_material_repository.dart';
import '../../../data/services/export/supplier_statement_excel_exporter.dart';
import '../../../data/services/export/supplier_statement_pdf_exporter.dart';
import '../../../data/services/supplier_statement_service.dart';
import '../../../domain/entities/supplier_statement.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../utils/auth_context.dart';
import '../../utils/export_actions.dart';
import '../../utils/export_factory_name.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/export_menu_button.dart';
import '../../widgets/suppliers/supplier_statement_date_range_section.dart';
import '../../widgets/suppliers/supplier_statement_detail_hero.dart';
import '../../widgets/suppliers/supplier_statement_ledger_section.dart';

class SupplierStatementScreen extends StatefulWidget {
  const SupplierStatementScreen({required this.supplierId, super.key});

  final String supplierId;

  @override
  State<SupplierStatementScreen> createState() =>
      _SupplierStatementScreenState();
}

class _SupplierStatementScreenState extends State<SupplierStatementScreen> {
  final _statementService = getIt<SupplierStatementService>();
  final _pdfExporter = getIt<SupplierStatementPdfExporter>();
  final _excelExporter = getIt<SupplierStatementExcelExporter>();

  late DateTime _fromDate;
  late DateTime _toDate;

  SupplierStatement? _statement;
  bool _loading = true;
  String? _errorMessage;

  StreamSubscription? _expensesSub;
  StreamSubscription? _paymentsSub;
  StreamSubscription? _transactionsSub;
  bool _subscribed = false;
  Timer? _reloadDebounce;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month);
    _toDate = now;
    _loadStatement();
  }

  void _debouncedReload() {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 600), () {
      if (mounted) _loadStatement(silent: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_subscribed) {
      _subscribed = true;
      final factoryId = readFactoryId(context);
      if (factoryId != null) {
        _expensesSub = getIt<ExpenseRepository>()
            .watchExpenses(factoryId)
            .listen((_) => _debouncedReload());
        _paymentsSub = getIt<ExpenseRepository>()
            .watchExpensePaymentsForFactory(factoryId)
            .listen((_) => _debouncedReload());
        _transactionsSub = getIt<RawMaterialRepository>()
            .watchTransactions(factoryId)
            .listen((_) => _debouncedReload());
      }
    }
  }

  @override
  void dispose() {
    _reloadDebounce?.cancel();
    _expensesSub?.cancel();
    _paymentsSub?.cancel();
    _transactionsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadStatement({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final statement = await _statementService.buildStatement(
        supplierId: widget.supplierId,
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (!silent) {
          _errorMessage = AppStrings.statementLoadError;
        }
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
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _toDate = picked);
      await _loadStatement();
    }
  }

  String _filename(SupplierStatement statement) {
    final slug = statement.supplier.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final from = DateFormat('yyyyMMdd').format(statement.fromDate);
    final to = DateFormat('yyyyMMdd').format(statement.toDate);
    return 'supplier_statement_${slug}_${from}_$to';
  }

  @override
  Widget build(BuildContext context) {
    final canExport = context.userCanExport(AppModule.suppliers);
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
            const Text(AppStrings.supplierStatement),
            if (statement != null)
              Text(
                statement.supplier.name,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: appBarForeground.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _loadStatement(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Statement',
          ),
          if (canExport && statement != null)
            ExportMenuButton(
              onExportPdf: (origin) async {
                try {
                  final factoryName = await resolveExportFactoryName(context);
                  if (!context.mounted) return;
                  final factoryProfile =
                      await resolveExportFactoryProfile(context, statement.supplier.factoryId);
                  final doc = await _pdfExporter.build(
                    statement: statement,
                    factoryName: factoryName,
                    factoryProfile: factoryProfile,
                  );
                  await ExportActions.sharePdf(
                    document: doc,
                    filename: '${_filename(statement)}.pdf',
                    sharePositionOrigin: origin,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ExportActions.showExportError(context, e);
                  }
                }
              },
              onExportExcel: (origin) async {
                try {
                  final bytes = _excelExporter.build(statement);
                  await ExportActions.shareExcel(
                    bytes: bytes,
                    filename: '${_filename(statement)}.xlsx',
                    sharePositionOrigin: origin,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ExportActions.showExportError(context, e);
                  }
                }
              },
              onPrint: () async {
                try {
                  final factoryName = await resolveExportFactoryName(context);
                  if (!context.mounted) return;
                  final factoryProfile =
                      await resolveExportFactoryProfile(context, statement.supplier.factoryId);
                  final doc = await _pdfExporter.build(
                    statement: statement,
                    factoryName: factoryName,
                    factoryProfile: factoryProfile,
                  );
                  await ExportActions.printPdf(
                    document: doc,
                    filename: '${_filename(statement)}.pdf',
                  );
                } catch (e) {
                  if (context.mounted) {
                    ExportActions.showExportError(context, e);
                  }
                }
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
                          SupplierStatementDetailHero(statement: statement),
                          SupplierStatementDateRangeSection(
                            fromDate: _fromDate,
                            toDate: _toDate,
                            onPickFrom: _pickFromDate,
                            onPickTo: _pickToDate,
                            enabled: !_loading,
                          ),
                          SupplierStatementLedgerSection(statement: statement),
                        ],
                      ),
                    ),
    );
  }
}

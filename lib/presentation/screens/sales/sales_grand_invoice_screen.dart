import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/sales_agreement_repository.dart';
import '../../../data/repositories/sales_invoice_repository.dart';
import '../../../data/repositories/sales_order_repository.dart';
import '../../../data/services/export/invoice_excel_exporter.dart';
import '../../../data/services/export/invoice_pdf_exporter.dart';
import '../../../data/services/sales_container_sync_helper.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/entities/sales_agreement.dart';
import '../../../domain/entities/sales_invoice.dart';
import '../../../domain/entities/sales_order.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/export_actions.dart';
import '../../utils/export_factory_name.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/export_menu_button.dart';
import '../../widgets/job_work/job_work_detail_row.dart';
import '../../widgets/job_work/job_work_detail_section.dart';
import '../../widgets/job_work/job_work_invoice_line_items_section.dart';
import '../../widgets/job_work/job_work_invoice_payment_action_bar.dart';
import '../../widgets/job_work/job_work_invoice_payment_history_section.dart';
import '../../widgets/sales/sales_invoice_pricing_section.dart';

/// Agreement-level rollup invoice (Job Work grand invoice parallel).
class SalesGrandInvoiceScreen extends StatefulWidget {
  const SalesGrandInvoiceScreen({
    required this.agreementId,
    this.generateMissing = false,
    super.key,
  });

  final String agreementId;
  final bool generateMissing;

  @override
  State<SalesGrandInvoiceScreen> createState() =>
      _SalesGrandInvoiceScreenState();
}

class _SalesGrandInvoiceScreenState extends State<SalesGrandInvoiceScreen> {
  var _loading = true;
  var _generating = false;
  var _savingPayment = false;
  String? _error;
  SalesAgreement? _agreement;
  SalesInvoice? _grandInvoice;
  List<SalesOrder> _orders = const [];
  List<SalesInvoice> _invoices = const [];
  List<Payment> _payments = const [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.generateMissing) {
        setState(() => _generating = true);
        await getIt<SalesInvoiceRepository>()
            .generateGrandFromAgreement(widget.agreementId);
      }
      await _reload();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _generating = false;
        _error = error is StateError
            ? error.message
            : AppStrings.salesGrandInvoiceIncomplete;
      });
    }
  }

  Future<void> _reload() async {
    final agreement = await getIt<SalesAgreementRepository>()
        .getAgreement(widget.agreementId);
    if (agreement == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _generating = false;
        _error = AppStrings.salesAgreementLoadError;
      });
      return;
    }

    final invoiceRepo = getIt<SalesInvoiceRepository>();
    await invoiceRepo.syncGrandInvoice(
      factoryId: agreement.factoryId,
      agreementId: agreement.id,
    );

    final orders = await getIt<SalesOrderRepository>().getOrdersForAgreement(
      factoryId: agreement.factoryId,
      agreementId: agreement.id,
    );
    final invoices = await invoiceRepo.getInvoicesForAgreement(
      factoryId: agreement.factoryId,
      agreementId: agreement.id,
    );
    final grand = SalesContainerSyncHelper.findGrandInvoice(invoices);
    final paymentRepo = getIt<PaymentRepository>();
    await paymentRepo.cleanupSalesGrandPhantomAdvances(
      factoryId: agreement.factoryId,
      agreementId: agreement.id,
    );
    final paymentLists = await Future.wait(
      invoices.map(
        (invoice) => paymentRepo.getPaymentsForInvoice(
          factoryId: agreement.factoryId,
          invoiceId: invoice.id,
        ),
      ),
    );
    final payments = paymentLists.expand((list) => list).toList()
      ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    final sortedOrders = List<SalesOrder>.from(orders)
      ..sort((a, b) {
        final aSeq = a.orderSequence ?? 0;
        final bSeq = b.orderSequence ?? 0;
        if (aSeq != bSeq) return aSeq.compareTo(bSeq);
        return a.createdAt.compareTo(b.createdAt);
      });

    if (!mounted) return;
    setState(() {
      _agreement = agreement;
      _orders = sortedOrders;
      _invoices = invoices;
      _grandInvoice = grand;
      _payments = payments;
      _loading = false;
      _generating = false;
      _error = grand == null && !widget.generateMissing
          ? AppStrings.salesGrandInvoiceIncomplete
          : null;
    });
  }

  String? _paymentBelongsLabel(Payment payment) {
    final invoice = _invoices
        .where((item) => item.id == payment.invoiceId)
        .firstOrNull;
    if (invoice == null) return null;
    if (invoice.isGrandInvoice) {
      return AppStrings.paymentBelongsToAgreement;
    }
    final orderId = invoice.salesOrderId.trim();
    final order = _orders.where((item) => item.id == orderId).firstOrNull;
    final orderNumber = (order?.orderNumber.trim().isNotEmpty == true)
        ? order!.orderNumber
        : (invoice.orderNumber.trim().isNotEmpty
            ? invoice.orderNumber
            : orderId);
    if (orderNumber.isEmpty) return null;
    return '${AppStrings.paymentBelongsToOrder} $orderNumber';
  }

  Future<void> _recordPayment() async {
    final invoice = _grandInvoice;
    if (invoice == null) return;
    final recorded = await context.push<bool>(
      RoutePaths.salesRecordPayment(invoice.id),
    );
    if (recorded == true && mounted) {
      await _reload();
    }
  }

  Future<void> _editPayment(Payment payment) async {
    final updated = await context.push<bool>(
      RoutePaths.salesRecordPaymentEdit(payment.invoiceId, payment.id),
    );
    if (updated == true && mounted) {
      await _reload();
    }
  }

  Future<void> _deletePayment(Payment payment) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deletePaymentTitle,
      message: AppStrings.deletePaymentMessage,
      confirmLabel: AppStrings.deletePayment,
      destructive: true,
      onConfirm: () async {
        setState(() => _savingPayment = true);
        try {
          await getIt<PaymentRepository>().deletePayment(payment.id);
        } finally {
          if (mounted) setState(() => _savingPayment = false);
        }
      },
    );
    if (!confirmed || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.paymentDeleted)),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final agreement = _agreement;
    final theme = Theme.of(context);
    final canMutate = context.userCanEdit(AppModule.sales);
    final canExport = context.userCanExport(AppModule.sales);
    final invoice = _grandInvoice;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.salesGrandInvoiceTitle),
            if (agreement != null)
              Text(
                agreement.agreementNumber,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: (theme.appBarTheme.foregroundColor ??
                          theme.colorScheme.onSurface)
                      .withValues(alpha: 0.78),
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        actions: [
          if (invoice != null && canExport)
            ExportMenuButton(
              onExportPdf: (origin) async {
                final factoryProfile = await resolveExportFactoryProfile(
                  context,
                  invoice.factoryId,
                );
                final doc = await getIt<InvoicePdfExporter>().buildSalesInvoicePdf(
                  invoice: invoice,
                  payments: _payments,
                  factoryProfile: factoryProfile,
                );
                await ExportActions.sharePdf(
                  document: doc,
                  filename: '${invoice.invoiceNumber}.pdf',
                  sharePositionOrigin: origin,
                );
              },
              onExportExcel: (origin) async {
                final factoryName = await resolveExportFactoryName(context);
                final bytes = getIt<InvoiceExcelExporter>().buildSalesInvoice(
                  invoice: invoice,
                  payments: _payments,
                  factoryName: factoryName,
                );
                await ExportActions.shareExcel(
                  bytes: bytes,
                  filename: '${invoice.invoiceNumber}.xlsx',
                  sharePositionOrigin: origin,
                );
              },
              onPrint: () async {
                final factoryProfile = await resolveExportFactoryProfile(
                  context,
                  invoice.factoryId,
                );
                final doc = await getIt<InvoicePdfExporter>().buildSalesInvoicePdf(
                  invoice: invoice,
                  payments: _payments,
                  factoryProfile: factoryProfile,
                );
                await ExportActions.printPdf(
                  document: doc,
                  filename: '${invoice.invoiceNumber}.pdf',
                );
              },
            ),
          if (invoice != null && canMutate && invoice.dueAmount > 0)
            IconButton(
              onPressed: _savingPayment ? null : _recordPayment,
              icon: const Icon(Icons.payments_outlined),
              tooltip: AppStrings.recordPayment,
            ),
        ],
      ),
      body: _loading || _generating
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (_generating) ...[
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.salesGrandInvoiceGenerating,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            )
          : _error != null && invoice == null
              ? EmptyStateView(
                  icon: Icons.receipt_long_outlined,
                  title: _error!,
                  action: FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text(AppStrings.close),
                  ),
                )
              : agreement == null
                  ? const EmptyStateView(
                      icon: Icons.error_outline,
                      title: AppStrings.salesAgreementLoadError,
                    )
                  : _buildBody(context, agreement),
    );
  }

  Widget _buildBody(BuildContext context, SalesAgreement agreement) {
    final finance = SalesContainerSyncHelper.rollupInvoiceFinance(
      agreement: agreement,
      orders: _orders,
      invoices: _invoices,
    );
    final invoice = _grandInvoice;
    final canMutate = context.userCanEdit(AppModule.sales);
    final canCorrectPayments = canMutate && _payments.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            AppStrings.salesGrandInvoiceSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            agreement.customerName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (invoice != null) ...[
            const SizedBox(height: 4),
            Text(
              invoice.invoiceNumber,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          JobWorkDetailSection(
            title: AppStrings.summary,
            icon: Icons.summarize_outlined,
            child: JobWorkDetailRows(
              rows: [
                JobWorkDetailRow(
                  label: AppStrings.charges,
                  value: Formatters.currencyPkr(
                    invoice?.totalAmount ?? finance.charges,
                  ),
                  bold: true,
                ),
                JobWorkDetailRow(
                  label: AppStrings.amountPaid,
                  value: Formatters.currencyPkr(
                    invoice?.paidAmount ?? finance.paid,
                  ),
                ),
                JobWorkDetailRow(
                  label: AppStrings.balanceDue,
                  value: Formatters.currencyPkr(
                    invoice?.dueAmount ?? finance.due,
                  ),
                  bold: (invoice?.dueAmount ?? finance.due) > 0,
                  highlight: (invoice?.dueAmount ?? finance.due) > 0,
                ),
              ],
            ),
          ),
          if (invoice != null && canMutate && invoice.dueAmount > 0) ...[
            const SizedBox(height: 12),
            JobWorkInvoicePaymentActionBar(
              enabled: !_savingPayment,
              onRecordPayment: _recordPayment,
            ),
          ],
          if (invoice != null) ...[
            const SizedBox(height: 12),
            JobWorkInvoiceLineItemsSection(lineItems: invoice.lineItems),
            SalesInvoicePricingSection(invoice: invoice),
          ],
          const SizedBox(height: 12),
          JobWorkInvoicePaymentHistorySection(
            payments: _payments,
            canCorrect: canCorrectPayments,
            onEdit: canCorrectPayments ? _editPayment : null,
            onDelete: canCorrectPayments ? _deletePayment : null,
            subtitleForPayment: _paymentBelongsLabel,
          ),
        ],
      ),
    );
  }
}

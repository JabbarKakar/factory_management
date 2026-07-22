import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/job_work/job_work_invoice_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/job_work_load.dart';
import '../../../domain/entities/payment.dart';
import '../../../data/repositories/job_work_load_repository.dart';
import '../../../data/services/export/invoice_excel_exporter.dart';
import '../../../data/services/export/invoice_pdf_exporter.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/invoice_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../utils/export_actions.dart';
import '../../utils/export_factory_name.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/export_menu_button.dart';
import '../../widgets/invoice_reminder_history_section.dart';
import '../../widgets/job_work/job_work_detail_row.dart';
import '../../widgets/job_work/job_work_detail_section.dart';
import '../../widgets/job_work/job_work_invoice_detail_hero.dart';
import '../../widgets/job_work/job_work_invoice_payment_action_bar.dart';
import '../../widgets/job_work/job_work_invoice_payment_history_section.dart';
import '../../widgets/job_work/job_work_invoice_pricing_section.dart';
import '../../widgets/send_payment_reminder_button.dart';

class JobWorkLoadInvoiceScreen extends StatefulWidget {
  const JobWorkLoadInvoiceScreen({
    required this.jobWorkId,
    required this.loadId,
    super.key,
  });

  final String jobWorkId;
  final String loadId;

  @override
  State<JobWorkLoadInvoiceScreen> createState() =>
      _JobWorkLoadInvoiceScreenState();
}

class _JobWorkLoadInvoiceScreenState extends State<JobWorkLoadInvoiceScreen> {
  JobWorkLoad? _load;
  bool _loadingLoad = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _fetchLoad();
  }

  Future<void> _fetchLoad() async {
    if (!mounted) return;
    setState(() {
      _loadingLoad = true;
      _loadError = null;
    });
    try {
      final load = await getIt<JobWorkLoadRepository>().getLoad(widget.loadId);
      if (mounted) {
        setState(() {
          _load = load;
          _loadingLoad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = 'Could not load load details.';
          _loadingLoad = false;
        });
      }
    }
  }

  Future<void> _reload(BuildContext context) async {
    final factoryId = readFactoryId(context);
    if (factoryId == null) return;
    context.read<JobWorkInvoiceBloc>().add(
          JobWorkInvoiceLoadByLoad(
            factoryId: factoryId,
            jobWorkId: widget.jobWorkId,
            loadId: widget.loadId,
          ),
        );
    await _fetchLoad();
  }

  Future<void> _recordPayment(BuildContext context) async {
    final state = context.read<JobWorkInvoiceBloc>().state;
    final invoice = state.invoice;
    if (invoice == null) return;

    final recorded = await context.push<bool>(
      RoutePaths.recordPayment(invoice.id),
    );
    if (recorded == true && context.mounted) {
      await _reload(context);
    }
  }

  Future<void> _editPayment(BuildContext context, Payment payment) async {
    final state = context.read<JobWorkInvoiceBloc>().state;
    final invoice = state.invoice;
    if (invoice == null) return;

    final updated = await context.push<bool>(
      RoutePaths.recordPaymentEdit(invoice.id, payment.id),
    );
    if (updated == true && context.mounted) {
      await _reload(context);
    }
  }

  Future<void> _deletePayment(BuildContext context, Payment payment) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deletePaymentTitle,
      message: AppStrings.deletePaymentMessage,
      confirmLabel: AppStrings.deletePayment,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final bloc = context.read<JobWorkInvoiceBloc>();
    bloc.add(JobWorkInvoicePaymentDeleteRequested(payment.id));
    final next = await bloc.stream.firstWhere(
      (state) =>
          state.status == JobWorkInvoiceStatus.paymentRecorded ||
          state.status == JobWorkInvoiceStatus.failure,
    );
    if (!context.mounted) return;
    if (next.status == JobWorkInvoiceStatus.paymentRecorded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.paymentDeleted)),
      );
      await _reload(context);
    } else if (next.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(next.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JobWorkInvoiceBloc, JobWorkInvoiceState>(
      listener: (context, state) {
        if (state.status == JobWorkInvoiceStatus.generated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.invoiceGenerated)),
          );
        }
        if (state.status == JobWorkInvoiceStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        final load = _load;
        final theme = Theme.of(context);

        if (state.status == JobWorkInvoiceStatus.loading ||
            state.status == JobWorkInvoiceStatus.initial ||
            _loadingLoad ||
            (state.status == JobWorkInvoiceStatus.saving &&
                state.invoice == null)) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.jobWorkInvoice)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (_loadError != null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.jobWorkInvoice)),
            body: EmptyStateView(
              icon: Icons.error_outline,
              title: _loadError!,
            ),
          );
        }

        if (load == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.jobWorkInvoice)),
            body: const EmptyStateView(
              icon: Icons.error_outline,
              title: 'Load not found.',
            ),
          );
        }

        if (state.status == JobWorkInvoiceStatus.notFound) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.jobWorkInvoice)),
            body: EmptyStateView(
              icon: Icons.receipt_long_outlined,
              title: AppStrings.invoiceNotReady,
              action: FilledButton.icon(
                onPressed: () {
                  context.read<JobWorkInvoiceBloc>().add(
                        JobWorkInvoiceGenerateFromLoadRequested(
                          jobWorkId: widget.jobWorkId,
                          loadId: widget.loadId,
                        ),
                      );
                },
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text(AppStrings.generateInvoice),
              ),
            ),
          );
        }

        final invoice = state.invoice;
        if (invoice == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.jobWorkInvoice)),
            body: EmptyStateView(
              icon: Icons.error_outline,
              title: state.errorMessage ?? 'Invoice not available',
            ),
          );
        }

        final isSaving = state.status == JobWorkInvoiceStatus.saving;
        final canCorrectPayments =
            context.userCanEdit(AppModule.jobWork) && state.payments.isNotEmpty;
        final canEditInvoice = context.userCanEdit(AppModule.jobWork) &&
            invoice.status != InvoiceStatus.cancelled;
        final appBarForeground =
            theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface;

        final loadLabel = load.loadNumber.isEmpty
            ? '${AppStrings.load} #${load.loadSequence}'
            : load.loadNumber;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.jobWorkInvoice),
                Text(
                  invoice.invoiceNumber,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: appBarForeground.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            actions: [
              if (canEditInvoice)
                IconButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final updated = await context.push<bool>(
                            RoutePaths.jobWorkInvoiceEdit(invoice.id),
                          );
                          if (updated == true && context.mounted) {
                            await _reload(context);
                          }
                        },
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: AppStrings.editInvoice,
                ),
              if (context.userCanExport(AppModule.jobWork))
                ExportMenuButton(
                  onExportPdf: (origin) async {
                    try {
                      final factoryName = await resolveExportFactoryName(context);
                      final exporter = getIt<InvoicePdfExporter>();
                      final doc = await exporter.buildJobWorkInvoicePdf(
                        invoice: invoice,
                        payments: state.payments,
                        factoryName: factoryName,
                      );
                      await ExportActions.sharePdf(
                        document: doc,
                        filename: '${invoice.invoiceNumber}.pdf',
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
                      final factoryName = await resolveExportFactoryName(context);
                      final bytes =
                          getIt<InvoiceExcelExporter>().buildJobWorkInvoice(
                        invoice: invoice,
                        payments: state.payments,
                        factoryName: factoryName,
                      );
                      await ExportActions.shareExcel(
                        bytes: bytes,
                        filename: '${invoice.invoiceNumber}.xlsx',
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
                      final exporter = getIt<InvoicePdfExporter>();
                      final doc = await exporter.buildJobWorkInvoicePdf(
                        invoice: invoice,
                        payments: state.payments,
                        factoryName: factoryName,
                      );
                      await ExportActions.printPdf(
                        document: doc,
                        filename: '${invoice.invoiceNumber}.pdf',
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ExportActions.showExportError(context, e);
                      }
                    }
                  },
                ),
              if (invoice.dueAmount > 0)
                SendPaymentReminderButton(
                  customerId: invoice.customerId,
                  customerName: invoice.customerName,
                  invoiceId: invoice.id,
                  invoiceNumber: invoice.invoiceNumber,
                  invoiceType: InvoiceType.jobWork,
                  amountDue: invoice.dueAmount,
                  dueDate: invoice.dueDate,
                  isOverdue: invoice.status == InvoiceStatus.overdue,
                ),
              if (invoice.dueAmount > 0)
                IconButton(
                  onPressed: isSaving ? null : () => _recordPayment(context),
                  icon: const Icon(Icons.payments_outlined),
                  tooltip: AppStrings.recordPayment,
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => _reload(context),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                JobWorkInvoiceDetailHero(invoice: invoice),
                if (invoice.dueAmount > 0)
                  JobWorkInvoicePaymentActionBar(
                    enabled: !isSaving,
                    onRecordPayment: () => _recordPayment(context),
                  ),
                JobWorkDetailSection(
                  title: 'Load Information',
                  icon: Icons.inventory_2_outlined,
                  child: JobWorkDetailRows(
                    rows: [
                      JobWorkDetailRow(
                        label: 'Load Number',
                        value: loadLabel,
                      ),
                      JobWorkDetailRow(
                        label: AppStrings.receivedDate,
                        value: DateFormat.yMMMd().format(load.receivedDate),
                      ),
                      if (load.mineLocation != null &&
                          load.mineLocation!.isNotEmpty)
                        JobWorkDetailRow(
                          label: AppStrings.mineLocation,
                          value: load.mineLocation!,
                        ),
                      if (load.mineOwner != null && load.mineOwner!.isNotEmpty)
                        JobWorkDetailRow(
                          label: AppStrings.mineOwner,
                          value: load.mineOwner!,
                        ),
                      JobWorkDetailRow(
                        label: AppStrings.marbleVariety,
                        value: load.marbleVariety,
                      ),
                      JobWorkDetailRow(
                        label: AppStrings.targetProduct,
                        value: load.targetProduct.label,
                      ),
                      JobWorkDetailRow(
                        label: 'Blocks Received',
                        value: '${load.blockCount}',
                      ),
                      if (load.smallSizes.isNotEmpty ||
                          load.largeSizes.isNotEmpty ||
                          load.legacySizes.isNotEmpty)
                        JobWorkDetailRow(
                          label: 'Sizes',
                          value: [
                            if (load.smallSizes.isNotEmpty)
                              'Small: ${load.smallSizes.join(", ")}',
                            if (load.largeSizes.isNotEmpty)
                              'Large: ${load.largeSizes.join(", ")}',
                            if (load.legacySizes.isNotEmpty)
                              'Legacy: ${load.legacySizes.join(", ")}',
                          ].join('\n'),
                        ),
                    ],
                  ),
                ),
                JobWorkDetailSection(
                  title: 'Production Summary',
                  icon: Icons.analytics_outlined,
                  child: JobWorkDetailRows(
                    rows: [
                      JobWorkDetailRow(
                        label: 'Pieces Produced',
                        value: '${load.output?.totalPieces ?? 0} pcs',
                      ),
                      JobWorkDetailRow(
                        label: 'Square Feet Produced',
                        value:
                            '${(load.output?.totalOutputSqFt ?? 0.0).toStringAsFixed(2)} sq. ft',
                      ),
                      JobWorkDetailRow(
                        label: 'Cutting Charges',
                        value: Formatters.currencyPkr(load.finalCuttingCharges),
                        bold: true,
                      ),
                    ],
                  ),
                ),
                JobWorkInvoicePricingSection(invoice: invoice),
                JobWorkInvoicePaymentHistorySection(
                  payments: state.payments,
                  canCorrect: canCorrectPayments,
                  onEdit: canCorrectPayments
                      ? (payment) => _editPayment(context, payment)
                      : null,
                  onDelete: canCorrectPayments
                      ? (payment) => _deletePayment(context, payment)
                      : null,
                ),
                InvoiceReminderHistorySection(invoiceId: invoice.id),
              ],
            ),
          ),
        );
      },
    );
  }
}

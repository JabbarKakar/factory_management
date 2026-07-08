import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/sales/sales_invoice_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/enums/invoice_enums.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

class RecordSalesPaymentScreen extends StatefulWidget {
  const RecordSalesPaymentScreen({
    required this.invoiceId,
    this.paymentId,
    super.key,
  });

  final String invoiceId;
  final String? paymentId;

  @override
  State<RecordSalesPaymentScreen> createState() =>
      _RecordSalesPaymentScreenState();
}

class _RecordSalesPaymentScreenState extends State<RecordSalesPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  PaymentMethod _method = PaymentMethod.cash;
  DateTime _paymentDate = DateTime.now();
  bool _populated = false;
  Payment? _editingPayment;
  bool _deletedPayment = false;

  bool get _isEditing => widget.paymentId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadPayment();
    }
  }

  Future<void> _loadPayment() async {
    final payment =
        await getIt<PaymentRepository>().getPayment(widget.paymentId!);
    if (!mounted || payment == null) return;
    setState(() {
      _editingPayment = payment;
      _amountController.text = payment.amount.toStringAsFixed(0);
      _method = payment.method;
      _paymentDate = payment.paymentDate;
      _referenceController.text = payment.reference ?? '';
      _notesController.text = payment.notes ?? '';
      _populated = true;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populate(double dueAmount) {
    if (_populated || _isEditing) return;
    _populated = true;
    _amountController.text = dueAmount.toStringAsFixed(0);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  Future<void> _deletePayment() async {
    final payment = _editingPayment;
    if (payment == null) return;
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deletePaymentTitle,
      message: AppStrings.deletePaymentMessage,
      confirmLabel: AppStrings.deletePayment,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _deletedPayment = true);
    context.read<SalesInvoiceBloc>().add(
          SalesInvoicePaymentDeleteRequested(payment.id),
        );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) return;

    final reference = _referenceController.text.trim().isEmpty
        ? null
        : _referenceController.text.trim();
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    final bloc = context.read<SalesInvoiceBloc>();
    if (_isEditing) {
      bloc.add(
        SalesInvoicePaymentUpdated(
          paymentId: widget.paymentId!,
          amount: amount,
          method: _method,
          paymentDate: _paymentDate,
          reference: reference,
          notes: notes,
        ),
      );
      return;
    }

    bloc.add(
      SalesInvoicePaymentSubmitted(
        invoiceId: widget.invoiceId,
        amount: amount,
        method: _method,
        paymentDate: _paymentDate,
        reference: reference,
        notes: notes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SalesInvoiceBloc, SalesInvoiceState>(
      listener: (context, state) {
        if (state.status == SalesInvoiceStatus.loaded &&
            state.invoice != null) {
          _populate(state.invoice!.dueAmount);
        }
        if (state.status == SalesInvoiceStatus.paymentRecorded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _deletedPayment
                    ? AppStrings.paymentDeleted
                    : _isEditing
                        ? AppStrings.paymentUpdated
                        : AppStrings.paymentRecorded,
              ),
            ),
          );
          context.pop(true);
        }
        if (state.status == SalesInvoiceStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        if (state.status == SalesInvoiceStatus.loading ||
            state.status == SalesInvoiceStatus.initial) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                _isEditing ? AppStrings.editPayment : AppStrings.recordPayment,
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final invoice = state.invoice;
        if (invoice == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                _isEditing ? AppStrings.editPayment : AppStrings.recordPayment,
              ),
            ),
            body: const Center(child: Text('Invoice not found')),
          );
        }

        _populate(invoice.dueAmount);
        final isSaving = state.status == SalesInvoiceStatus.saving;
        final maxAmount = _isEditing
            ? invoice.dueAmount + (_editingPayment?.amount ?? 0)
            : invoice.dueAmount;

        return Scaffold(
          appBar: AppBar(
            title: AppFormAppBarTitle(
              title: _isEditing
                  ? AppStrings.editPayment
                  : AppStrings.recordPayment,
              subtitle: '${invoice.invoiceNumber} · ${invoice.customerName}',
            ),
            actions: [
              if (_isEditing)
                IconButton(
                  onPressed: isSaving ? null : _deletePayment,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: AppStrings.deletePayment,
                ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              children: [
                AppFormContextHeader(
                  title: invoice.invoiceNumber,
                  subtitle:
                      '${AppStrings.amountDue}: ${Formatters.currencyPkr(invoice.dueAmount)}',
                ),
                JobWorkDetailSection(
                  title: AppStrings.paymentDetails,
                  icon: Icons.payments_outlined,
                  child: AppFormSectionBody(
                    children: [
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.paymentAmount,
                        ),
                        validator: (value) {
                          final amount =
                              double.tryParse(value?.trim() ?? '') ?? 0;
                          if (amount <= 0) return 'Enter a valid amount';
                          if (amount > maxAmount) {
                            return 'Cannot exceed ${Formatters.currencyPkr(maxAmount)}';
                          }
                          return null;
                        },
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      DropdownButtonFormField<PaymentMethod>(
                        key: ValueKey(_method),
                        initialValue: _method,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.paymentMethod,
                        ),
                        items: PaymentMethod.values
                            .map(
                              (method) => DropdownMenuItem(
                                value: method,
                                child: Text(
                                  method.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _method = value);
                                }
                              },
                      ),
                      AppFormFields.gap,
                      AppFormDateField(
                        label: AppStrings.paymentDate,
                        value: DateFormat.yMMMd().format(_paymentDate),
                        onTap: isSaving ? null : _pickDate,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _referenceController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.paymentReference,
                        ),
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _notesController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.paymentNotes,
                        ),
                        maxLines: 2,
                        enabled: !isSaving,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: AppFormBottomBar(
            label: _isEditing ? AppStrings.saveChanges : AppStrings.savePayment,
            isLoading: isSaving,
            onPressed: isSaving ? null : _submit,
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/sales/sales_invoice_bloc.dart';
import '../../../core/constants/app_colors.dart';
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
  double _customerCredit = 0;
  bool _applyCredit = true;
  String? _creditCustomerKey;
  bool _cashAdjustedForCredit = false;

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
      _amountController.text = ThousandsTextInputFormatter.format(payment.amount);
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
    _amountController.text = ThousandsTextInputFormatter.format(dueAmount);
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

  Future<void> _ensureCustomerCredit({
    required String factoryId,
    required String customerId,
    required double dueAmount,
  }) async {
    if (_isEditing) return;
    final key = '$factoryId|$customerId';
    if (_creditCustomerKey == key) return;
    _creditCustomerKey = key;
    final credit =
        await getIt<PaymentRepository>().getUnallocatedCreditForCustomer(
      factoryId: factoryId,
      customerId: customerId,
    );
    if (!mounted) return;
    setState(() {
      _customerCredit = credit;
      _applyCredit = credit > 0.005;
    });
    _adjustCashForCredit(dueAmount);
  }

  void _adjustCashForCredit(double dueAmount) {
    if (_isEditing || _cashAdjustedForCredit || !_applyCredit) return;
    if (_customerCredit <= 0.005) return;
    final creditSlice =
        _customerCredit < dueAmount ? _customerCredit : dueAmount;
    final cash = (dueAmount - creditSlice).clamp(0.0, dueAmount);
    _amountController.text = ThousandsTextInputFormatter.format(cash);
    _cashAdjustedForCredit = true;
  }

  double _creditToApply(double dueAmount) {
    if (_isEditing || !_applyCredit || _customerCredit <= 0.005) return 0;
    return _customerCredit < dueAmount ? _customerCredit : dueAmount;
  }

  Future<void> _deletePayment() async {
    final payment = _editingPayment;
    if (payment == null) return;
    final bloc = context.read<SalesInvoiceBloc>();
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deletePaymentTitle,
      message: AppStrings.deletePaymentMessage,
      confirmLabel: AppStrings.deletePayment,
      destructive: true,
      onConfirm: () async {
        bloc.add(SalesInvoicePaymentDeleteRequested(payment.id));
        final next = await bloc.stream.firstWhere(
          (state) =>
              state.status == SalesInvoiceStatus.paymentRecorded ||
              state.status == SalesInvoiceStatus.failure,
        );
        if (next.status == SalesInvoiceStatus.failure) {
          throw Exception(next.errorMessage ?? 'Could not delete payment.');
        }
      },
    );
    if (!confirmed || !mounted) return;
    setState(() => _deletedPayment = true);
  }

  Future<void> _submit({required double dueAmount}) async {
    if (!_formKey.currentState!.validate()) return;
    final amount =
        ThousandsTextInputFormatter.tryParseDouble(_amountController.text) ?? 0;
    final creditToApply = _creditToApply(dueAmount);
    if (amount <= 0 && creditToApply <= 0.005) return;

    final remainingAfterCredit =
        (dueAmount - creditToApply).clamp(0.0, dueAmount);
    final heldAsCredit = amount > remainingAfterCredit + 0.005
        ? amount - remainingAfterCredit
        : 0.0;
    if (heldAsCredit > 0.005) {
      final appliedCash = remainingAfterCredit;
      final confirmed = await AppConfirmDialog.show(
        context,
        title: AppStrings.overpayCreditTitle,
        message:
            '${Formatters.currencyPkr(appliedCash + creditToApply)} clears this due. '
            '${Formatters.currencyPkr(heldAsCredit)} will be held as credit for this customer.',
        confirmLabel: AppStrings.savePayment,
      );
      if (!confirmed || !mounted) return;
    }

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
        creditToApply: creditToApply,
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
          _ensureCustomerCredit(
            factoryId: state.invoice!.factoryId,
            customerId: state.invoice!.customerId,
            dueAmount: state.invoice!.dueAmount,
          );
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
        final dueForPayment = _isEditing
            ? invoice.dueAmount + (_editingPayment?.appliedAmount ?? 0)
            : invoice.dueAmount;
        final creditToApply = _creditToApply(dueForPayment);
        final typedCash =
            ThousandsTextInputFormatter.tryParseDouble(_amountController.text) ??
                0;
        final remainingAfterCredit =
            (dueForPayment - creditToApply).clamp(0.0, dueForPayment);
        final appliedCash = typedCash < remainingAfterCredit
            ? typedCash
            : remainingAfterCredit;
        final heldAsCredit =
            (typedCash - appliedCash).clamp(0.0, double.infinity);
        final appliedToDue = creditToApply + appliedCash;
        final canSubmit =
            !isSaving && (typedCash > 0.005 || creditToApply > 0.005);

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
                        inputFormatters: [
                          ThousandsTextInputFormatter(
                            allowDecimal: true,
                            decimalDigits: 2,
                          ),
                        ],
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.paymentAmount,
                        ),
                        validator: (value) {
                          final amount =
                              ThousandsTextInputFormatter.tryParseDouble(value) ??
                                  0;
                          if (amount < 0) return 'Enter a valid amount';
                          if (amount <= 0 && creditToApply <= 0.005) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                        enabled: !isSaving,
                        onChanged: (_) => setState(() {}),
                      ),
                      if (!_isEditing && _customerCredit > 0.005) ...[
                        AppFormFields.gap,
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          value: _applyCredit,
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  setState(() {
                                    _applyCredit = value ?? false;
                                  });
                                },
                          title: Text(
                            '${AppStrings.applyCustomerCredit} '
                            '(${Formatters.currencyPkr(_customerCredit)})',
                            style: AppFormFields.valueStyle(context),
                          ),
                        ),
                      ],
                      if (typedCash > 0.005 || creditToApply > 0.005) ...[
                        AppFormFields.gap,
                        Text(
                          '${AppStrings.appliedToThisDue}: '
                          '${Formatters.currencyPkr(appliedToDue)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (heldAsCredit > 0.005)
                          Text(
                            '${AppStrings.heldAsCustomerCredit}: '
                            '${Formatters.currencyPkr(heldAsCredit)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                      ],
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
            onPressed: canSubmit
                ? () => _submit(dueAmount: dueForPayment)
                : null,
          ),
        );
      },
    );
  }
}

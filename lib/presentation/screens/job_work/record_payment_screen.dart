import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/job_work/job_work_invoice_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../domain/entities/job_work_load.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/enums/invoice_enums.dart';
import '../../../domain/enums/job_work_enums.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

class RecordPaymentScreen extends StatefulWidget {
  const RecordPaymentScreen({
    required this.invoiceId,
    this.paymentId,
    super.key,
  });

  final String invoiceId;
  final String? paymentId;

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  PaymentMethod _method = PaymentMethod.cash;
  DateTime _paymentDate = DateTime.now();
  String? _selectedLoadId;
  bool _populated = false;
  Payment? _editingPayment;
  bool _deletedPayment = false;
  bool _submitting = false;
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
      _selectedLoadId = payment.loadId;
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

  void _populate(double dueAmount, JobWorkInvoiceState state) {
    if (_populated || _isEditing) return;
    final invoice = state.invoice;
    if (invoice == null) return;

    final isGrand = invoice.loadId == null || invoice.loadId!.trim().isEmpty;
    if (isGrand) {
      final billable = state.loads
          .where((l) => !l.isVirtual && l.status != JobWorkStatus.cancelled)
          .toList()
        ..sort((a, b) => a.loadSequence.compareTo(b.loadSequence));

      if (_selectedLoadId == null && billable.isNotEmpty) {
        final firstUnpaid = billable.where((l) {
          final fin = state.perLoadFinance[l.id];
          final due = fin?.due ?? l.balanceDue;
          return due > 0.005;
        }).firstOrNull;

        final target = firstUnpaid ?? billable.first;
        _selectedLoadId = target.id;
        final targetDue = state.perLoadFinance[target.id]?.due ?? target.balanceDue;
        _amountController.text = ThousandsTextInputFormatter.format(targetDue);
        _populated = true;
      }
    } else {
      _populated = true;
      _amountController.text = ThousandsTextInputFormatter.format(dueAmount);
    }
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
    if (payment == null || _submitting) return;
    final bloc = context.read<JobWorkInvoiceBloc>();
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deletePaymentTitle,
      message: AppStrings.deletePaymentMessage,
      confirmLabel: AppStrings.deletePayment,
      destructive: true,
      onConfirm: () async {
        bloc.add(JobWorkInvoicePaymentDeleteRequested(payment.id));
        final next = await bloc.stream.firstWhere(
          (state) =>
              state.status == JobWorkInvoiceStatus.paymentRecorded ||
              state.status == JobWorkInvoiceStatus.failure,
        );
        if (next.status == JobWorkInvoiceStatus.failure) {
          throw Exception(next.errorMessage ?? 'Could not delete payment.');
        }
      },
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _deletedPayment = true;
      _submitting = true;
    });
  }

  Future<void> _submit({required double dueAmount}) async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    final amount =
        ThousandsTextInputFormatter.tryParseDouble(_amountController.text) ?? 0;
    final creditToApply = _creditToApply(dueAmount);
    if (amount <= 0 && creditToApply <= 0.005) return;

    final invoice = context.read<JobWorkInvoiceBloc>().state.invoice;
    final isGrandInvoice =
        invoice?.loadId == null || invoice!.loadId!.trim().isEmpty;

    if (isGrandInvoice && (_selectedLoadId == null || _selectedLoadId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a target load first.')),
      );
      return;
    }

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

    setState(() => _submitting = true);

    final reference = _referenceController.text.trim().isEmpty
        ? null
        : _referenceController.text.trim();
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    final bloc = context.read<JobWorkInvoiceBloc>();
    if (_isEditing) {
      bloc.add(
        JobWorkInvoicePaymentUpdated(
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
      JobWorkInvoicePaymentSubmitted(
        invoiceId: widget.invoiceId,
        amount: amount,
        method: _method,
        paymentDate: _paymentDate,
        loadId: isGrandInvoice ? _selectedLoadId : invoice?.loadId,
        reference: reference,
        notes: notes,
        creditToApply: creditToApply,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JobWorkInvoiceBloc, JobWorkInvoiceState>(
      listener: (context, state) {
        if (state.status == JobWorkInvoiceStatus.loaded &&
            state.invoice != null) {
          _populate(state.invoice!.dueAmount, state);
          _ensureCustomerCredit(
            factoryId: state.invoice!.factoryId,
            customerId: state.invoice!.customerId,
            dueAmount: state.invoice!.dueAmount,
          );
        }
        if (state.status == JobWorkInvoiceStatus.paymentRecorded) {
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
        if (state.status == JobWorkInvoiceStatus.failure) {
          if (mounted) setState(() => _submitting = false);
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        }
      },
      builder: (context, state) {
        if (state.status == JobWorkInvoiceStatus.loading ||
            state.status == JobWorkInvoiceStatus.initial) {
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

        final isGrandInvoice =
            invoice.loadId == null || invoice.loadId!.trim().isEmpty;
        final billableLoads = state.loads
            .where((l) => !l.isVirtual && l.status != JobWorkStatus.cancelled)
            .toList()
          ..sort((a, b) => a.loadSequence.compareTo(b.loadSequence));

        _populate(invoice.dueAmount, state);
        final isSaving =
            state.status == JobWorkInvoiceStatus.saving || _submitting;

        final double dueForPayment;
        if (isGrandInvoice) {
          if (_selectedLoadId != null) {
            final selectedFin = state.perLoadFinance[_selectedLoadId];
            final targetLoad =
                billableLoads.where((l) => l.id == _selectedLoadId).firstOrNull;
            final loadDue = selectedFin?.due ?? targetLoad?.balanceDue ?? 0.0;
            dueForPayment = _isEditing
                ? loadDue + (_editingPayment?.appliedAmount ?? 0)
                : loadDue;
          } else {
            dueForPayment = invoice.dueAmount;
          }
        } else {
          dueForPayment = _isEditing
              ? invoice.dueAmount + (_editingPayment?.appliedAmount ?? 0)
              : invoice.dueAmount;
        }

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

        final canSubmit = !isSaving &&
            (!isGrandInvoice || _selectedLoadId != null) &&
            (typedCash > 0.005 || creditToApply > 0.005);

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
                  subtitle: _isEditing
                      ? '${AppStrings.amountDue}: ${Formatters.currencyPkr(invoice.dueAmount)}'
                      : '${AppStrings.amountDue}: ${Formatters.currencyPkr(invoice.dueAmount)}',
                ),
                JobWorkDetailSection(
                  title: AppStrings.paymentDetails,
                  icon: Icons.payments_outlined,
                  child: AppFormSectionBody(
                    children: [
                      if (isGrandInvoice) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedLoadId,
                          isExpanded: true,
                          itemHeight: null,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: 'Target Child Load',
                            hint: billableLoads.isEmpty
                                ? 'No loads found'
                                : 'Select load to allocate payment',
                          ),
                          selectedItemBuilder: (context) {
                            return billableLoads.map((load) {
                              final fin = state.perLoadFinance[load.id] ??
                                  (
                                    charges: load.finalCuttingCharges,
                                    paid: load.advanceReceived,
                                    due: load.balanceDue,
                                    credit: 0.0,
                                  );
                              final label = load.loadNumber.isNotEmpty
                                  ? load.loadNumber
                                  : 'Load #${load.loadSequence}';
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '$label · Due: ${Formatters.currencyPkrWhole(fin.due)}',
                                  style: AppFormFields.valueStyle(context),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList();
                          },
                          items: billableLoads.map((load) {
                            final fin = state.perLoadFinance[load.id] ??
                                (
                                  charges: load.finalCuttingCharges,
                                  paid: load.advanceReceived,
                                  due: load.balanceDue,
                                  credit: 0.0,
                                );
                            final isPaid = fin.due <= 0.005;
                            final label = load.loadNumber.isNotEmpty
                                ? load.loadNumber
                                : 'Load #${load.loadSequence}';
                            final details = isPaid
                                ? 'Paid Up (${Formatters.currencyPkrWhole(fin.charges)})'
                                : 'Total: ${Formatters.currencyPkrWhole(fin.charges)} · Paid: ${Formatters.currencyPkrWhole(fin.paid)} · Due: ${Formatters.currencyPkrWhole(fin.due)}';

                            return DropdownMenuItem<String>(
                              value: load.id,
                              enabled: !isPaid || _isEditing,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        label,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: isPaid && !_isEditing
                                              ? Theme.of(context).disabledColor
                                              : null,
                                        ),
                                      ),
                                      if (isPaid)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.success
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Paid Up',
                                            style: TextStyle(
                                              color: AppColors.success,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Text(
                                    details,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isPaid && !_isEditing
                                          ? Theme.of(context).disabledColor
                                          : (fin.due > 0
                                              ? AppColors.warning
                                              : AppColors.success),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: isSaving
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedLoadId = val;
                                      final fin = state.perLoadFinance[val];
                                      final target = billableLoads
                                          .where((l) => l.id == val)
                                          .firstOrNull;
                                      final due = fin?.due ??
                                          target?.balanceDue ??
                                          0.0;
                                      final credit = _creditToApply(due);
                                      _amountController.text =
                                          ThousandsTextInputFormatter.format(
                                        (due - credit).clamp(0.0, due),
                                      );
                                    });
                                  }
                                },
                          validator: (val) {
                            if (isGrandInvoice &&
                                (val == null || val.isEmpty)) {
                              return 'Please select a load to allocate payment';
                            }
                            return null;
                          },
                        ),
                        AppFormFields.gap,
                      ],
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
                              ThousandsTextInputFormatter.tryParseDouble(
                                      value) ??
                                  0;
                          if (isGrandInvoice && _selectedLoadId == null) {
                            return 'Please select a target load first';
                          }
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/job_work/job_work_invoice_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/enums/invoice_enums.dart';
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

class RecordPaymentScreen extends StatefulWidget {
  const RecordPaymentScreen({required this.invoiceId, super.key});

  final String invoiceId;

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
  bool _populated = false;

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populate(double dueAmount) {
    if (_populated) return;
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) return;

    context.read<JobWorkInvoiceBloc>().add(
          JobWorkInvoicePaymentSubmitted(
            invoiceId: widget.invoiceId,
            amount: amount,
            method: _method,
            paymentDate: _paymentDate,
            reference: _referenceController.text.trim().isEmpty
                ? null
                : _referenceController.text.trim(),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JobWorkInvoiceBloc, JobWorkInvoiceState>(
      listener: (context, state) {
        if (state.status == JobWorkInvoiceStatus.loaded &&
            state.invoice != null) {
          _populate(state.invoice!.dueAmount);
        }
        if (state.status == JobWorkInvoiceStatus.paymentRecorded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.paymentRecorded)),
          );
          context.pop(true);
        }
        if (state.status == JobWorkInvoiceStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        if (state.status == JobWorkInvoiceStatus.loading ||
            state.status == JobWorkInvoiceStatus.initial) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.recordPayment)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final invoice = state.invoice;
        if (invoice == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.recordPayment)),
            body: const Center(child: Text('Invoice not found')),
          );
        }

        _populate(invoice.dueAmount);
        final isSaving = state.status == JobWorkInvoiceStatus.saving;

        return Scaffold(
          appBar: AppBar(
            title: AppFormAppBarTitle(
              title: AppStrings.recordPayment,
              subtitle: '${invoice.invoiceNumber} · ${invoice.customerName}',
            ),
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
                          if (amount > invoice.dueAmount) {
                            return 'Cannot exceed amount due';
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
            label: AppStrings.savePayment,
            isLoading: isSaving,
            onPressed: _submit,
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/sales/sales_invoice_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/job_work_invoice.dart';
import '../../../domain/entities/sales_invoice.dart';
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

class EditSalesInvoiceScreen extends StatefulWidget {
  const EditSalesInvoiceScreen({required this.invoiceId, super.key});

  final String invoiceId;

  @override
  State<EditSalesInvoiceScreen> createState() => _EditSalesInvoiceScreenState();
}

class _EditSalesInvoiceScreenState extends State<EditSalesInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_LineItemFields> _lineItems = [];

  DateTime? _dueDate;
  bool _populated = false;

  @override
  void dispose() {
    for (final item in _lineItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _populate(SalesInvoice invoice) {
    if (_populated) return;
    _populated = true;
    _dueDate = invoice.dueDate ?? DateTime.now().add(const Duration(days: 7));
    for (final line in invoice.lineItems) {
      _lineItems.add(
        _LineItemFields(
          description: line.description,
          amount: line.amount,
        ),
      );
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  List<InvoiceLineItem> _buildLineItems() {
    return _lineItems
        .map(
          (fields) => InvoiceLineItem(
            description: fields.descriptionController.text.trim(),
            amount: double.tryParse(fields.amountController.text.trim()) ?? 0,
          ),
        )
        .where((item) => item.description.isNotEmpty)
        .toList();
  }

  double _computedTotal() {
    return _lineItems.fold<double>(0, (sum, fields) {
      final amount = double.tryParse(fields.amountController.text.trim()) ?? 0;
      return sum + amount;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final lineItems = _buildLineItems();
    if (lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one line item is required.')),
      );
      return;
    }

    context.read<SalesInvoiceBloc>().add(
          SalesInvoiceUpdateRequested(
            lineItems: lineItems,
            dueDate: _dueDate,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SalesInvoiceBloc, SalesInvoiceState>(
      listener: (context, state) {
        if (state.status == SalesInvoiceStatus.updated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.invoiceUpdated)),
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
            appBar: AppBar(title: const Text(AppStrings.editInvoice)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final invoice = state.invoice;
        if (invoice == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.editInvoice)),
            body: const Center(child: Text('Invoice not found')),
          );
        }

        _populate(invoice);
        final isSaving = state.status == SalesInvoiceStatus.saving;
        final minTotal = invoice.paidAmount;

        return Scaffold(
          appBar: AppBar(
            title: AppFormAppBarTitle(
              title: AppStrings.editInvoice,
              subtitle: invoice.invoiceNumber,
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              children: [
                AppFormContextHeader(
                  title: invoice.invoiceNumber,
                  subtitle:
                      '${invoice.customerName} · ${AppStrings.amountPaid}: '
                      '${Formatters.currencyPkr(invoice.paidAmount)}',
                ),
                JobWorkDetailSection(
                  title: AppStrings.pricingAgreement,
                  icon: Icons.payments_outlined,
                  child: AppFormSectionBody(
                    children: [
                      AppFormDateField(
                        label: AppStrings.paymentDueDate,
                        value: _dueDate == null
                            ? AppStrings.notSpecified
                            : DateFormat.yMMMd().format(_dueDate!),
                        onTap: isSaving ? null : _pickDueDate,
                      ),
                    ],
                  ),
                ),
                JobWorkDetailSection(
                  title: AppStrings.lineItems,
                  icon: Icons.receipt_long_outlined,
                  child: AppFormSectionBody(
                    children: [
                      for (final fields in _lineItems) ...[
                        TextFormField(
                          controller: fields.descriptionController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.description,
                          ),
                          enabled: !isSaving,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Description is required';
                            }
                            return null;
                          },
                        ),
                        AppFormFields.gap,
                        TextFormField(
                          controller: fields.amountController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.amount,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          enabled: !isSaving,
                          onChanged: (_) => setState(() {}),
                          validator: (value) {
                            final amount =
                                double.tryParse(value?.trim() ?? '') ?? 0;
                            if (amount < 0) {
                              return 'Enter a valid amount';
                            }
                            return null;
                          },
                        ),
                        AppFormFields.gap,
                      ],
                      AppFormSummaryRow(
                        label: AppStrings.invoiceTotal,
                        value: Formatters.currencyPkr(_computedTotal()),
                      ),
                      if (_computedTotal() + 0.01 < minTotal) ...[
                        AppFormFields.gap,
                        Text(
                          'Total must be at least '
                          '${Formatters.currencyPkr(minTotal)} (amount paid).',
                          style: AppFormFields.valueStyle(context).copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AppFormSubmitBar(
                  label: AppStrings.saveChanges,
                  isLoading: isSaving,
                  onPressed: isSaving || _computedTotal() + 0.01 < minTotal
                      ? null
                      : _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LineItemFields {
  _LineItemFields({
    required String description,
    required double amount,
  })  : descriptionController = TextEditingController(text: description),
        amountController = TextEditingController(
          text: amount.toStringAsFixed(0),
        );

  final TextEditingController descriptionController;
  final TextEditingController amountController;

  void dispose() {
    descriptionController.dispose();
    amountController.dispose();
  }
}

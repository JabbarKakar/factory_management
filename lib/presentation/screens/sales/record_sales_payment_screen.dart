import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/sales/sales_invoice_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/enums/invoice_enums.dart';

class RecordSalesPaymentScreen extends StatefulWidget {
  const RecordSalesPaymentScreen({required this.invoiceId, super.key});

  final String invoiceId;

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

    context.read<SalesInvoiceBloc>().add(
          SalesInvoicePaymentSubmitted(
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
    return BlocConsumer<SalesInvoiceBloc, SalesInvoiceState>(
      listener: (context, state) {
        if (state.status == SalesInvoiceStatus.loaded &&
            state.invoice != null) {
          _populate(state.invoice!.dueAmount);
        }
        if (state.status == SalesInvoiceStatus.paymentRecorded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.paymentRecorded)),
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
        final isSaving = state.status == SalesInvoiceStatus.saving;

        return Scaffold(
          appBar: AppBar(title: const Text(AppStrings.recordPayment)),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '${invoice.invoiceNumber} · ${invoice.customerName}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppStrings.amountDue}: ${Formatters.currencyPkr(invoice.dueAmount)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: AppStrings.paymentAmount,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '') ?? 0;
                    if (amount <= 0) return 'Enter a valid amount';
                    if (amount > invoice.dueAmount) {
                      return 'Cannot exceed amount due';
                    }
                    return null;
                  },
                  enabled: !isSaving,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PaymentMethod>(
                  initialValue: _method,
                  decoration: const InputDecoration(
                    labelText: AppStrings.paymentMethod,
                    border: OutlineInputBorder(),
                  ),
                  items: PaymentMethod.values
                      .map(
                        (method) => DropdownMenuItem(
                          value: method,
                          child: Text(method.label),
                        ),
                      )
                      .toList(),
                  onChanged: isSaving
                      ? null
                      : (value) {
                          if (value != null) setState(() => _method = value);
                        },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AppStrings.paymentDate),
                  subtitle: Text(DateFormat.yMMMd().format(_paymentDate)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: isSaving ? null : _pickDate,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _referenceController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.paymentReference,
                    border: OutlineInputBorder(),
                  ),
                  enabled: !isSaving,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: AppStrings.paymentNotes,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  enabled: !isSaving,
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: isSaving ? null : _submit,
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(AppStrings.savePayment),
              ),
            ),
          ),
        );
      },
    );
  }
}

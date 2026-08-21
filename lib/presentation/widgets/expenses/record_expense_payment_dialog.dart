import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/enums/invoice_enums.dart';
import '../dialogs/app_bottom_sheet.dart';
import '../forms/app_form_fields.dart';

class RecordExpensePaymentDialog extends StatefulWidget {
  const RecordExpensePaymentDialog({
    required this.expense,
    this.onPaymentRecorded,
    super.key,
  });

  final Expense expense;
  final VoidCallback? onPaymentRecorded;

  static Future<bool?> show(
    BuildContext context, {
    required Expense expense,
    VoidCallback? onPaymentRecorded,
  }) {
    return AppBottomSheet.show<bool>(
      context,
      child: RecordExpensePaymentDialog(
        expense: expense,
        onPaymentRecorded: onPaymentRecorded,
      ),
    );
  }

  @override
  State<RecordExpensePaymentDialog> createState() =>
      _RecordExpensePaymentDialogState();
}

class _RecordExpensePaymentDialogState
    extends State<RecordExpensePaymentDialog> {
  final _formKey = GlobalKey<FormState>();

  late double _maxPayable;
  late TextEditingController _amountController;
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _paymentDate = DateTime.now();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _maxPayable = widget.expense.effectiveDueAmount;
    _amountController = TextEditingController(
      text: ThousandsTextInputFormatter.format(_maxPayable),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount =
        ThousandsTextInputFormatter.tryParseDouble(_amountController.text) ?? 0;
    if (amount <= 0 || amount > _maxPayable + 0.005) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await getIt<ExpenseRepository>().recordExpensePayment(
        expenseId: widget.expense.id,
        amount: amount,
        method: _paymentMethod,
        paymentDate: _paymentDate,
        reference: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;
      widget.onPaymentRecorded?.call();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final errorMsg = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('Bad state: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);

    final title = widget.expense.payeeName != null &&
            widget.expense.payeeName!.isNotEmpty
        ? widget.expense.payeeName!
        : widget.expense.description;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: AppBottomSheet(
          title: 'Record Purchase Payment',
          icon: Icons.payments_outlined,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${widget.expense.expenseNumber} · $title',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Financial Overview Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: outline),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SummaryColumn(
                            label: 'Total Cost',
                            value: Formatters.currencyPkr(widget.expense.amount),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: outline.withValues(alpha: 0.5),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: _SummaryColumn(
                              label: 'Paid So Far',
                              value: Formatters.currencyPkr(
                                widget.expense.paidAmount,
                              ),
                              color: AppColors.success,
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: outline.withValues(alpha: 0.5),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: _SummaryColumn(
                              label: 'Remaining Due',
                              value: Formatters.currencyPkr(_maxPayable),
                              color: theme.colorScheme.error,
                              bold: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Payment Amount
                  TextFormField(
                    controller: _amountController,
                    style: AppFormFields.valueStyle(context),
                    decoration: AppFormFields.decoration(
                      context,
                      label: 'Payment Amount (PKR)',
                      hint: 'Up to ${Formatters.currencyPkr(_maxPayable)}',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      ThousandsTextInputFormatter(
                        allowDecimal: true,
                        decimalDigits: 2,
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter payment amount';
                      }
                      final val =
                          ThousandsTextInputFormatter.tryParseDouble(value);
                      if (val == null || val <= 0) {
                        return 'Amount must be greater than zero';
                      }
                      if (val > _maxPayable + 0.005) {
                        return 'Amount cannot exceed remaining due (${Formatters.currencyPkr(_maxPayable)})';
                      }
                      return null;
                    },
                    enabled: !_isSubmitting,
                  ),
                  AppFormFields.gap,
                  // Payment Date & Method Row
                  Row(
                    children: [
                      Expanded(
                        child: AppFormDateField(
                          label: 'Payment Date',
                          value: DateFormat.yMMMd().format(_paymentDate),
                          onTap: _isSubmitting ? null : _pickDate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<PaymentMethod>(
                          key: ValueKey(_paymentMethod),
                          initialValue: _paymentMethod,
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
                          onChanged: _isSubmitting
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setState(() => _paymentMethod = val);
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                  AppFormFields.gap,
                  // Reference & Notes
                  TextFormField(
                    controller: _referenceController,
                    style: AppFormFields.valueStyle(context),
                    decoration: AppFormFields.decoration(
                      context,
                      label: 'Cheque / Trx Reference (optional)',
                    ),
                    enabled: !_isSubmitting,
                  ),
                  AppFormFields.gap,
                  TextFormField(
                    controller: _notesController,
                    style: AppFormFields.valueStyle(context),
                    decoration: AppFormFields.decoration(
                      context,
                      label: 'Payment Notes (optional)',
                    ),
                    maxLines: 2,
                    enabled: !_isSubmitting,
                  ),
                  const SizedBox(height: 18),
                  // Submit Button
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      _isSubmitting
                          ? 'Recording Payment...'
                          : 'Confirm & Record Payment',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.label,
    required this.value,
    this.color,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            fontSize: 12,
            color: color ?? theme.colorScheme.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

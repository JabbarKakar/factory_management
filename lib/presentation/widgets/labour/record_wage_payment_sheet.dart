import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../blocs/labour/employee_salary_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/employee.dart';
import '../../../domain/entities/monthly_ledger.dart';
import '../../../domain/enums/invoice_enums.dart';
import '../../utils/user_permissions_context.dart';
import '../dialogs/app_bottom_sheet.dart';
import '../forms/app_form_fields.dart';

class RecordWagePaymentSheet extends StatefulWidget {
  const RecordWagePaymentSheet({
    required this.employee,
    this.ledger,
    super.key,
  });

  final Employee employee;
  final MonthlyLedger? ledger;

  static Future<void> show(
    BuildContext context, {
    required Employee employee,
    MonthlyLedger? ledger,
  }) {
    return AppBottomSheet.show<void>(
      context,
      isScrollControlled: true,
      child: BlocProvider.value(
        value: context.read<EmployeeSalaryBloc>(),
        child: RecordWagePaymentSheet(employee: employee, ledger: ledger),
      ),
    );
  }

  @override
  State<RecordWagePaymentSheet> createState() => _RecordWagePaymentSheetState();
}

class _RecordWagePaymentSheetState extends State<RecordWagePaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _notesController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  double get _remaining =>
      widget.ledger?.remainingBalance ?? widget.employee.rateAmount;

  @override
  void initState() {
    super.initState();
    final preset = _remaining > 0 ? _remaining : 0.0;
    _amountController = TextEditingController(
      text: preset > 0 ? ThousandsTextInputFormatter.format(preset) : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount =
        ThousandsTextInputFormatter.tryParseDouble(_amountController.text) ?? 0;
    final user = readCurrentUser(context);
    if (user == null) return;

    context.read<EmployeeSalaryBloc>().add(
          EmployeeSalaryPaymentRequested(
            amount: amount,
            paymentMethod: _paymentMethod,
            recordedBy: user.id,
            recordedByName: user.name,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            paymentDate: _paymentDate,
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);
    final remaining = _remaining;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: AppBottomSheet(
          title: AppStrings.recordWagePayment,
          icon: Icons.payments_outlined,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.employee.fullName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
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
                          child: _SheetMetric(
                            label: AppStrings.totalSalaryDue,
                            value: Formatters.currencyPkr(
                              widget.ledger?.totalPayable ??
                                  widget.employee.rateAmount,
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
                            child: _SheetMetric(
                              label: AppStrings.totalPaidToDate,
                              value: Formatters.currencyPkr(
                                widget.ledger?.totalPaid ?? 0,
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
                            child: _SheetMetric(
                              label: remaining < 0
                                  ? AppStrings.overpaidBalance
                                  : AppStrings.remainingBalance,
                              value: Formatters.currencyPkr(remaining.abs()),
                              color: remaining > 0.005
                                  ? AppColors.warning
                                  : remaining < -0.005
                                      ? AppColors.error
                                      : AppColors.success,
                              bold: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _amountController,
                    style: AppFormFields.valueStyle(context),
                    decoration: AppFormFields.decoration(
                      context,
                      label: AppStrings.wagePaymentAmount,
                      hint: remaining > 0
                          ? 'Remaining ${Formatters.currencyPkr(remaining)}'
                          : AppStrings.wageOverpaymentHint,
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
                        return AppStrings.enterPaymentAmount;
                      }
                      final parsed =
                          ThousandsTextInputFormatter.tryParseDouble(value);
                      if (parsed == null || parsed <= 0) {
                        return AppStrings.amountMustBePositive;
                      }
                      return null;
                    },
                  ),
                  AppFormFields.gap,
                  Row(
                    children: [
                      Expanded(
                        child: AppFormDateField(
                          label: AppStrings.wagePaymentDate,
                          value: DateFormat.yMMMd().format(_paymentDate),
                          onTap: _pickDate,
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
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _paymentMethod = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  AppFormFields.gap,
                  TextFormField(
                    controller: _notesController,
                    style: AppFormFields.valueStyle(context),
                    decoration: AppFormFields.decoration(
                      context,
                      label: AppStrings.wagePaymentNotes,
                      hint: AppStrings.wagePaymentNotesHint,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text(
                      AppStrings.confirmWagePayment,
                      style: TextStyle(
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

class _SheetMetric extends StatelessWidget {
  const _SheetMetric({
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

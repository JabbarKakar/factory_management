import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/expense/expense_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../utils/auth_context.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/enums/expense_enums.dart';
import '../../../domain/enums/invoice_enums.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/settings_section.dart';

class AddEditExpenseScreen extends StatefulWidget {
  const AddEditExpenseScreen({this.expenseId, super.key});

  final String? expenseId;

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _expenseDate = DateTime.now();
  ExpenseCategory _category = ExpenseCategory.miscellaneous;
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _payeeController = TextEditingController();
  final _billNumberController = TextEditingController();
  final _notesController = TextEditingController();

  bool _populated = false;

  bool get _isEditing => widget.expenseId != null;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _payeeController.dispose();
    _billNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateForm(Expense expense) {
    if (_populated) return;
    _populated = true;

    _expenseDate = expense.expenseDate;
    _category = expense.category;
    _paymentMethod = expense.paymentMethod;
    _descriptionController.text = expense.description;
    _amountController.text = expense.amount.toStringAsFixed(0);
    _payeeController.text = expense.payeeName ?? '';
    _billNumberController.text = expense.billNumber ?? '';
    _notesController.text = expense.notes ?? '';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _expenseDate = picked);
    }
  }

  void _submit(BuildContext context, Expense? existing) {
    if (!_formKey.currentState!.validate()) return;

    final factoryId = readFactoryId(context);
    if (factoryId == null) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final expense = Expense(
      id: existing?.id ?? '',
      expenseNumber: existing?.expenseNumber ?? '',
      factoryId: factoryId,
      expenseDate: _expenseDate,
      category: _category,
      description: _descriptionController.text.trim(),
      amount: amount,
      paymentMethod: _paymentMethod,
      payeeName: _payeeController.text.trim().isEmpty
          ? null
          : _payeeController.text.trim(),
      billNumber: _billNumberController.text.trim().isEmpty
          ? null
          : _billNumberController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: existing?.updatedAt,
    );

    context.read<ExpenseFormBloc>().add(ExpenseFormSubmitted(expense));
  }

  Future<void> _confirmDelete(BuildContext context, String expenseId) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deleteExpenseTitle,
      message: AppStrings.deleteExpenseMessage,
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (confirmed == true && context.mounted) {
      context.read<ExpenseFormBloc>().add(ExpenseFormDeleteRequested(expenseId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExpenseFormBloc, ExpenseFormState>(
      listener: (context, state) {
        if (state.status == ExpenseFormStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? AppStrings.expenseUpdated
                    : AppStrings.expenseCreated,
              ),
            ),
          );
          context.pop(true);
        }
        if (state.status == ExpenseFormStatus.deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.expenseDeleted)),
          );
          context.pop(true);
        }
        if (state.status == ExpenseFormStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        if (state.status == ExpenseFormStatus.loading ||
            state.status == ExpenseFormStatus.initial) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                _isEditing ? AppStrings.editExpense : AppStrings.addExpense,
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final expense = state.expense;
        if (expense != null && _isEditing) {
          _populateForm(expense);
        }

        final isSaving = state.status == ExpenseFormStatus.saving;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _isEditing ? AppStrings.editExpense : AppStrings.addExpense,
            ),
            actions: [
              if (_isEditing && widget.expenseId != null)
                IconButton(
                  onPressed: isSaving
                      ? null
                      : () => _confirmDelete(context, widget.expenseId!),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: AppStrings.delete,
                ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SettingsSection(
                  title: AppStrings.expenseDetails,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(AppStrings.expenseDate),
                          subtitle: Text(
                            DateFormat.yMMMd().format(_expenseDate),
                          ),
                          trailing: const Icon(Icons.calendar_today_outlined),
                          onTap: isSaving ? null : _pickDate,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ExpenseCategory>(
                          initialValue: _category,
                          decoration: const InputDecoration(
                            labelText: AppStrings.expenseCategory,
                          ),
                          items: ExpenseCategory.values
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category.label),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _category = value);
                                  }
                                },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.description,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          validator: (value) =>
                              Validators.requiredText(value, field: 'Description'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.amountPkr,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Amount is required';
                            }
                            final amount = double.tryParse(value.trim());
                            if (amount == null || amount <= 0) {
                              return 'Enter a valid amount';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<PaymentMethod>(
                          initialValue: _paymentMethod,
                          decoration: const InputDecoration(
                            labelText: AppStrings.paymentMethod,
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
                                  if (value != null) {
                                    setState(() => _paymentMethod = value);
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                SettingsSection(
                  title: AppStrings.optionalDetails,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _payeeController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.payeeName,
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _billNumberController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.billNumber,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.notes,
                          ),
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: isSaving
                        ? null
                        : () => _submit(context, expense),
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isEditing
                                ? AppStrings.saveExpense
                                : AppStrings.addExpense,
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

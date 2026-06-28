import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/expense/expense_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../utils/auth_context.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/supplier_repository.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/supplier.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/expense_enums.dart';
import '../../utils/user_permissions_context.dart';
import '../../../domain/enums/invoice_enums.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

class AddEditExpenseScreen extends StatefulWidget {
  const AddEditExpenseScreen({
    this.expenseId,
    this.initialSupplierId,
    this.initialPayeeName,
    super.key,
  });

  final String? expenseId;
  final String? initialSupplierId;
  final String? initialPayeeName;

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _expenseDate = DateTime.now();
  ExpenseCategory _category = ExpenseCategory.miscellaneous;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  String? _supplierId;

  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _payeeController = TextEditingController();
  final _billNumberController = TextEditingController();
  final _notesController = TextEditingController();

  bool _populated = false;

  bool get _isEditing => widget.expenseId != null;

  @override
  void initState() {
    super.initState();
    final supplierId = widget.initialSupplierId;
    if (!_isEditing && supplierId != null && supplierId.isNotEmpty) {
      _supplierId = supplierId;
      _category = ExpenseCategory.rawMaterialPurchase;
      final payee = widget.initialPayeeName;
      if (payee != null && payee.isNotEmpty) {
        _payeeController.text = payee;
      }
    }
  }

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
    _supplierId = expense.supplierId;
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
      supplierId: _supplierId,
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

  String _subtitle(Expense? expense) {
    if (!_isEditing) return AppStrings.addExpense;

    final description = _descriptionController.text.trim();
    if (description.isNotEmpty) return description;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount != null && amount > 0) {
      return '₨ ${amount.toStringAsFixed(0)}';
    }

    if (expense != null) {
      if (expense.description.isNotEmpty) return expense.description;
      return '₨ ${expense.amount.toStringAsFixed(0)}';
    }

    return AppStrings.editExpense;
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
        final factoryId = readFactoryId(context);

        return Scaffold(
          appBar: AppBar(
            title: AppFormAppBarTitle(
              title: _isEditing
                  ? AppStrings.editExpense
                  : AppStrings.addExpense,
              subtitle: _subtitle(expense),
            ),
            actions: [
              if (_isEditing &&
                  widget.expenseId != null &&
                  context.userCanDelete(AppModule.expenses))
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
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              children: [
                JobWorkDetailSection(
                  title: AppStrings.expenseDetails,
                  icon: Icons.receipt_outlined,
                  child: AppFormSectionBody(
                    children: [
                      AppFormDateField(
                        label: AppStrings.expenseDate,
                        value: DateFormat.yMMMd().format(_expenseDate),
                        onTap: isSaving ? null : _pickDate,
                      ),
                      AppFormFields.gap,
                      DropdownButtonFormField<ExpenseCategory>(
                        key: ValueKey(_category),
                        initialValue: _category,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.expenseCategory,
                        ),
                        items: ExpenseCategory.values
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(
                                  category.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
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
                      AppFormFields.gap,
                      TextFormField(
                        controller: _descriptionController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.description,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) =>
                            Validators.requiredText(value, field: 'Description'),
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _amountController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.amountPkr,
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
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      DropdownButtonFormField<PaymentMethod>(
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
                JobWorkDetailSection(
                  title: AppStrings.optionalDetails,
                  icon: Icons.notes_outlined,
                  child: AppFormSectionBody(
                    children: [
                      if (factoryId != null)
                        StreamBuilder<List<Supplier>>(
                          stream: getIt<SupplierRepository>()
                              .watchSuppliers(factoryId),
                          builder: (context, snapshot) {
                            final suppliers = snapshot.data ?? const [];
                            final supplierValue = _supplierId != null &&
                                    suppliers.any(
                                      (supplier) => supplier.id == _supplierId,
                                    )
                                ? _supplierId
                                : null;
                            return DropdownButtonFormField<String?>(
                              key: ValueKey(supplierValue),
                              initialValue: supplierValue,
                              style: AppFormFields.valueStyle(context),
                              decoration: AppFormFields.decoration(
                                context,
                                label: AppStrings.linkSupplier,
                              ),
                              items: [
                                DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text(
                                    AppStrings.noSupplierLinked,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                ...suppliers.map(
                                  (supplier) => DropdownMenuItem<String?>(
                                    value: supplier.id,
                                    child: Text(
                                      supplier.name,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: isSaving
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _supplierId = value;
                                        if (value != null) {
                                          final supplier = suppliers
                                              .firstWhere(
                                                (item) => item.id == value,
                                              );
                                          _payeeController.text = supplier.name;
                                        } else {
                                          _payeeController.clear();
                                        }
                                      });
                                    },
                            );
                          },
                        ),
                      if (factoryId != null) AppFormFields.gap,
                      TextFormField(
                        controller: _payeeController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.payeeName,
                        ),
                        textCapitalization: TextCapitalization.words,
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _billNumberController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.billNumber,
                        ),
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _notesController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.notes,
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        enabled: !isSaving,
                      ),
                    ],
                  ),
                ),
                AppFormSubmitBar(
                  label: _isEditing
                      ? AppStrings.saveExpense
                      : AppStrings.addExpense,
                  isLoading: isSaving,
                  onPressed: () => _submit(context, expense),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

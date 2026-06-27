import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/labour/employee_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/employee.dart';
import '../../../domain/enums/labour_enums.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/settings_section.dart';

class AddEditEmployeeScreen extends StatefulWidget {
  const AddEditEmployeeScreen({this.employeeId, super.key});

  final String? employeeId;

  @override
  State<AddEditEmployeeScreen> createState() => _AddEditEmployeeScreenState();
}

class _AddEditEmployeeScreenState extends State<AddEditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  WorkerCategory _workerCategory = WorkerCategory.helper;
  EmploymentType _employmentType = EmploymentType.dailyWage;
  SalaryType _salaryType = SalaryType.dailyRate;
  EmployeeStatus _status = EmployeeStatus.active;
  DateTime _joinDate = DateTime.now();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cnicController = TextEditingController();
  final _rateController = TextEditingController();
  final _notesController = TextEditingController();

  bool _populated = false;

  bool get _isEditing => widget.employeeId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateForm(Employee employee) {
    if (_populated) return;
    _populated = true;

    _workerCategory = employee.workerCategory;
    _employmentType = employee.employmentType;
    _salaryType = employee.salaryType;
    _status = employee.status;
    _joinDate = employee.joinDate;
    _nameController.text = employee.fullName;
    _phoneController.text = employee.phone;
    _cnicController.text = employee.cnic ?? '';
    _rateController.text =
        employee.rateAmount > 0 ? employee.rateAmount.toStringAsFixed(0) : '';
    _notesController.text = employee.notes ?? '';
  }

  Employee? _buildEmployee(Employee? existing) {
    if (existing == null) return null;

    final rate = double.tryParse(_rateController.text.trim()) ?? 0;

    return existing.copyWith(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      cnic: _cnicController.text.trim().isEmpty
          ? null
          : _cnicController.text.trim(),
      workerCategory: _workerCategory,
      employmentType: _employmentType,
      salaryType: _salaryType,
      rateAmount: rate,
      joinDate: _joinDate,
      status: _status,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
  }

  void _submit(BuildContext context, Employee? existing) {
    if (!_formKey.currentState!.validate()) return;
    final employee = _buildEmployee(existing);
    if (employee == null) return;
    context.read<EmployeeFormBloc>().add(EmployeeFormSubmitted(employee));
  }

  Future<void> _pickJoinDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joinDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _joinDate = picked);
    }
  }

  Future<void> _confirmDelete(BuildContext context, String employeeId) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deleteEmployeeTitle,
      message: AppStrings.deleteEmployeeMessage,
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (confirmed == true && context.mounted) {
      context
          .read<EmployeeFormBloc>()
          .add(EmployeeFormDeleteRequested(employeeId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EmployeeFormBloc, EmployeeFormState>(
      listener: (context, state) {
        if (state.status == EmployeeFormStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.employeeSaved)),
          );
          context.pop(true);
        }
        if (state.status == EmployeeFormStatus.deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.employeeDeleted)),
          );
          context.pop(true);
        }
        if (state.status == EmployeeFormStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        if (state.status == EmployeeFormStatus.loading ||
            state.status == EmployeeFormStatus.initial) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                _isEditing ? AppStrings.editEmployee : AppStrings.addEmployee,
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final employee = state.employee;
        if (employee != null && _isEditing) {
          _populateForm(employee);
        }

        final isSaving = state.status == EmployeeFormStatus.saving;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _isEditing ? AppStrings.editEmployee : AppStrings.addEmployee,
            ),
            actions: [
              if (_isEditing && widget.employeeId != null)
                IconButton(
                  onPressed: isSaving
                      ? null
                      : () => _confirmDelete(context, widget.employeeId!),
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
                  title: AppStrings.basicInformation,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.fullName,
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) => Validators.requiredText(
                            value,
                            field: 'Name',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.phone,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: Validators.phone,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cnicController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.cnicNumber,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<WorkerCategory>(
                          initialValue: _workerCategory,
                          decoration: const InputDecoration(
                            labelText: AppStrings.workerCategory,
                          ),
                          items: WorkerCategory.values
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
                                    setState(() => _workerCategory = value);
                                  }
                                },
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(AppStrings.employeeJoinDate),
                          subtitle: Text(
                            DateFormat.yMMMd().format(_joinDate),
                          ),
                          trailing: const Icon(Icons.calendar_today_outlined),
                          onTap: isSaving ? null : _pickJoinDate,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<EmployeeStatus>(
                          initialValue: _status,
                          decoration: const InputDecoration(
                            labelText: AppStrings.employeeStatus,
                          ),
                          items: EmployeeStatus.values
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status.label),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _status = value);
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                SettingsSection(
                  title: AppStrings.salaryType,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        DropdownButtonFormField<EmploymentType>(
                          initialValue: _employmentType,
                          decoration: const InputDecoration(
                            labelText: AppStrings.employmentType,
                          ),
                          items: EmploymentType.values
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type.label),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _employmentType = value);
                                  }
                                },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<SalaryType>(
                          initialValue: _salaryType,
                          decoration: const InputDecoration(
                            labelText: AppStrings.salaryType,
                          ),
                          items: SalaryType.values
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type.label),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _salaryType = value);
                                  }
                                },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _rateController,
                          decoration: InputDecoration(
                            labelText: AppStrings.rateAmount,
                            helperText: switch (_salaryType) {
                              SalaryType.monthlyFixed => 'Monthly salary in PKR',
                              SalaryType.dailyRate => 'Daily wage in PKR',
                              SalaryType.perPieceRate =>
                                'Rate per piece / sq. ft in PKR',
                            },
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Rate is required';
                            }
                            final rate = double.tryParse(value.trim());
                            if (rate == null || rate < 0) {
                              return 'Enter a valid rate';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SettingsSection(
                  title: AppStrings.notes,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.notes,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: isSaving
                        ? null
                        : () => _submit(context, employee),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isEditing
                                ? AppStrings.saveChanges
                                : AppStrings.saveEmployee,
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

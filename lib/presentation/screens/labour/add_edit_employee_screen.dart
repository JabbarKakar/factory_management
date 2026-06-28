import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/labour/employee_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/employee.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/labour_enums.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

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

  String _subtitle(Employee? employee) {
    if (_isEditing) {
      final name = _nameController.text.trim();
      if (name.isNotEmpty) return name;
      return employee?.fullName ?? '';
    }
    return AppStrings.addEmployee;
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
            title: AppFormAppBarTitle(
              title: _isEditing
                  ? AppStrings.editEmployee
                  : AppStrings.addEmployee,
              subtitle: _subtitle(employee),
            ),
            actions: [
              if (_isEditing &&
                  widget.employeeId != null &&
                  context.userCanDelete(AppModule.labour))
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
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              children: [
                JobWorkDetailSection(
                  title: AppStrings.basicInformation,
                  icon: Icons.person_outline,
                  child: AppFormSectionBody(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.fullName,
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) => Validators.requiredText(
                          value,
                          field: 'Name',
                        ),
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _phoneController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.phone,
                        ),
                        keyboardType: TextInputType.phone,
                        validator: Validators.phone,
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _cnicController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.cnicNumber,
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      DropdownButtonFormField<WorkerCategory>(
                        key: ValueKey(_workerCategory),
                        initialValue: _workerCategory,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.workerCategory,
                        ),
                        items: WorkerCategory.values
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
                                  setState(() => _workerCategory = value);
                                }
                              },
                      ),
                      AppFormFields.gap,
                      AppFormDateField(
                        label: AppStrings.employeeJoinDate,
                        value: DateFormat.yMMMd().format(_joinDate),
                        onTap: isSaving ? null : _pickJoinDate,
                      ),
                      AppFormFields.gap,
                      DropdownButtonFormField<EmployeeStatus>(
                        key: ValueKey(_status),
                        initialValue: _status,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.employeeStatus,
                        ),
                        items: EmployeeStatus.values
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(
                                  status.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
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
                JobWorkDetailSection(
                  title: AppStrings.salaryType,
                  icon: Icons.payments_outlined,
                  child: AppFormSectionBody(
                    children: [
                      DropdownButtonFormField<EmploymentType>(
                        key: ValueKey(_employmentType),
                        initialValue: _employmentType,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.employmentType,
                        ),
                        items: EmploymentType.values
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
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
                      AppFormFields.gap,
                      DropdownButtonFormField<SalaryType>(
                        key: ValueKey(_salaryType),
                        initialValue: _salaryType,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.salaryType,
                        ),
                        items: SalaryType.values
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
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
                      AppFormFields.gap,
                      TextFormField(
                        controller: _rateController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.rateAmount,
                        ).copyWith(
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
                        enabled: !isSaving,
                      ),
                    ],
                  ),
                ),
                JobWorkDetailSection(
                  title: AppStrings.notes,
                  icon: Icons.notes_outlined,
                  child: AppFormSectionBody(
                    children: [
                      TextFormField(
                        controller: _notesController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.notes,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3,
                        enabled: !isSaving,
                      ),
                    ],
                  ),
                ),
                AppFormSubmitBar(
                  label: _isEditing
                      ? AppStrings.saveChanges
                      : AppStrings.saveEmployee,
                  isLoading: isSaving,
                  onPressed: () => _submit(context, employee),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

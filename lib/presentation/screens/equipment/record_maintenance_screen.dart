import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/equipment/maintenance_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/maintenance_log.dart';
import '../../../domain/enums/equipment_enums.dart';
import '../../utils/auth_context.dart';
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

class RecordMaintenanceScreen extends StatefulWidget {
  const RecordMaintenanceScreen({required this.equipmentId, super.key});

  final String equipmentId;

  @override
  State<RecordMaintenanceScreen> createState() =>
      _RecordMaintenanceScreenState();
}

class _RecordMaintenanceScreenState extends State<RecordMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();

  MaintenanceType _maintenanceType = MaintenanceType.preventive;
  MaintenancePerformedBy _performedBy = MaintenancePerformedBy.inHouse;
  EquipmentStatus? _statusAfter;
  DateTime _maintenanceDate = DateTime.now();
  DateTime? _nextDueDate;

  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _performedByNameController = TextEditingController();
  final _downtimeController = TextEditingController();

  bool _defaultNextDueSet = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _costController.dispose();
    _performedByNameController.dispose();
    _downtimeController.dispose();
    super.dispose();
  }

  Future<void> _pickMaintenanceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _maintenanceDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _maintenanceDate = picked);
  }

  Future<void> _pickNextDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _nextDueDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _nextDueDate = picked);
  }

  void _submit(BuildContext context, String factoryId) {
    if (!_formKey.currentState!.validate()) return;

    final cost = double.tryParse(_costController.text.trim()) ?? 0;
    final downtime = double.tryParse(_downtimeController.text.trim());

    final log = MaintenanceLog(
      id: '',
      equipmentId: widget.equipmentId,
      factoryId: factoryId,
      maintenanceDate: _maintenanceDate,
      maintenanceType: _maintenanceType,
      description: _descriptionController.text.trim(),
      cost: cost,
      performedBy: _performedBy,
      performedByName: _performedByNameController.text.trim().isEmpty
          ? null
          : _performedByNameController.text.trim(),
      downtimeHours: downtime,
      nextDueDate: _nextDueDate,
      equipmentStatusAfter: _statusAfter,
      createdAt: DateTime.now(),
    );

    context.read<MaintenanceFormBloc>().add(MaintenanceFormSubmitted(log));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MaintenanceFormBloc, MaintenanceFormState>(
      listener: (context, state) {
        if (state.status == MaintenanceFormStatus.ready &&
            !_defaultNextDueSet &&
            state.equipment?.maintenanceIntervalDays != null) {
          _defaultNextDueSet = true;
          setState(() {
            _nextDueDate = _maintenanceDate.add(
              Duration(days: state.equipment!.maintenanceIntervalDays!),
            );
          });
        }
        if (state.status == MaintenanceFormStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.maintenanceSaved)),
          );
          context.pop(true);
        }
        if (state.status == MaintenanceFormStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        if (state.status == MaintenanceFormStatus.loading ||
            state.status == MaintenanceFormStatus.initial) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.recordMaintenance)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state.equipment == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.recordMaintenance)),
            body: Center(
              child: Text(state.errorMessage ?? AppStrings.equipmentNotFound),
            ),
          );
        }

        final equipment = state.equipment!;
        final isSaving = state.status == MaintenanceFormStatus.saving;

        return Scaffold(
          appBar: AppBar(
            title: AppFormAppBarTitle(
              title: AppStrings.recordMaintenance,
              subtitle:
                  '${equipment.name} · ${equipment.equipmentNumber}',
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              children: [
                JobWorkDetailSection(
                  title: AppStrings.equipmentDetails,
                  icon: Icons.precision_manufacturing_outlined,
                  child: AppFormSectionBody(
                    children: [
                      Text(
                        equipment.name,
                        style: AppFormFields.valueStyle(context),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        equipment.equipmentNumber,
                        style: AppFormFields.labelStyle(context),
                      ),
                    ],
                  ),
                ),
                JobWorkDetailSection(
                  title: AppStrings.maintenanceDetails,
                  icon: Icons.build_circle_outlined,
                  child: AppFormSectionBody(
                    children: [
                      AppFormDateField(
                        label: AppStrings.maintenanceDate,
                        value: DateFormat.yMMMd().format(_maintenanceDate),
                        onTap: isSaving ? null : _pickMaintenanceDate,
                      ),
                      AppFormFields.gap,
                      DropdownButtonFormField<MaintenanceType>(
                        key: ValueKey(_maintenanceType),
                        initialValue: _maintenanceType,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.maintenanceType,
                        ),
                        items: MaintenanceType.values
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
                                  setState(() => _maintenanceType = value);
                                }
                              },
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _descriptionController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.maintenanceDescription,
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Description is required';
                          }
                          return null;
                        },
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _costController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.maintenanceCost,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      DropdownButtonFormField<MaintenancePerformedBy>(
                        key: ValueKey(_performedBy),
                        initialValue: _performedBy,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.performedBy,
                        ),
                        items: MaintenancePerformedBy.values
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _performedBy = value);
                                }
                              },
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _performedByNameController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.performedByName,
                        ),
                        textCapitalization: TextCapitalization.words,
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _downtimeController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.downtimeHours,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      AppFormDateField(
                        label: AppStrings.nextMaintenanceDue,
                        value: _nextDueDate == null
                            ? AppStrings.notSpecified
                            : DateFormat.yMMMd().format(_nextDueDate!),
                        onTap: isSaving ? null : _pickNextDueDate,
                        onClear: isSaving || _nextDueDate == null
                            ? null
                            : () => setState(() => _nextDueDate = null),
                      ),
                      AppFormFields.gap,
                      DropdownButtonFormField<EquipmentStatus?>(
                        key: ValueKey(_statusAfter),
                        initialValue: _statusAfter,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.statusAfterMaintenance,
                        ),
                        items: [
                          const DropdownMenuItem<EquipmentStatus?>(
                            value: null,
                            child: Text(
                              AppStrings.keepCurrentStatus,
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          ...EquipmentStatus.values.map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(
                                status.label,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                        onChanged: isSaving
                            ? null
                            : (value) => setState(() => _statusAfter = value),
                      ),
                    ],
                  ),
                ),
                AppFormSubmitBar(
                  label: AppStrings.saveMaintenance,
                  isLoading: isSaving,
                  onPressed: isSaving
                      ? null
                      : () {
                          final factoryId = readFactoryId(context);
                          if (factoryId == null) return;
                          _submit(context, factoryId);
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

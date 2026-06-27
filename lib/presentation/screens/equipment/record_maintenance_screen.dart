import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/equipment/maintenance_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/maintenance_log.dart';
import '../../../domain/enums/equipment_enums.dart';
import '../../utils/auth_context.dart';
import '../../widgets/settings_section.dart';

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
      initialDate: _nextDueDate ?? DateTime.now().add(const Duration(days: 90)),
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
          appBar: AppBar(title: const Text(AppStrings.recordMaintenance)),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SettingsSection(
                  title: AppStrings.equipmentDetails,
                  child: ListTile(
                    title: Text(equipment.name),
                    subtitle: Text(equipment.equipmentNumber),
                  ),
                ),
                SettingsSection(
                  title: AppStrings.maintenanceDetails,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(AppStrings.maintenanceDate),
                          subtitle:
                              Text(DateFormat.yMMMd().format(_maintenanceDate)),
                          trailing: const Icon(Icons.calendar_today_outlined),
                          onTap: isSaving ? null : _pickMaintenanceDate,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<MaintenanceType>(
                          initialValue: _maintenanceType,
                          decoration: const InputDecoration(
                            labelText: AppStrings.maintenanceType,
                          ),
                          items: MaintenanceType.values
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
                                    setState(() => _maintenanceType = value);
                                  }
                                },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.maintenanceDescription,
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Description is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _costController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.maintenanceCost,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<MaintenancePerformedBy>(
                          initialValue: _performedBy,
                          decoration: const InputDecoration(
                            labelText: AppStrings.performedBy,
                          ),
                          items: MaintenancePerformedBy.values
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value.label),
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
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _performedByNameController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.performedByName,
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _downtimeController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.downtimeHours,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(AppStrings.nextMaintenanceDue),
                          subtitle: Text(
                            _nextDueDate == null
                                ? AppStrings.notSpecified
                                : DateFormat.yMMMd().format(_nextDueDate!),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_nextDueDate != null)
                                IconButton(
                                  onPressed: isSaving
                                      ? null
                                      : () => setState(() => _nextDueDate = null),
                                  icon: const Icon(Icons.clear),
                                ),
                              const Icon(Icons.calendar_today_outlined),
                            ],
                          ),
                          onTap: isSaving ? null : _pickNextDueDate,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<EquipmentStatus?>(
                          initialValue: _statusAfter,
                          decoration: const InputDecoration(
                            labelText: AppStrings.statusAfterMaintenance,
                          ),
                          items: [
                            const DropdownMenuItem<EquipmentStatus?>(
                              value: null,
                              child: Text(AppStrings.keepCurrentStatus),
                            ),
                            ...EquipmentStatus.values.map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.label),
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
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            final factoryId = readFactoryId(context);
                            if (factoryId == null) return;
                            _submit(context, factoryId);
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(AppStrings.saveMaintenance),
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

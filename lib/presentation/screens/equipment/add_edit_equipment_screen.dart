import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/equipment/equipment_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/equipment.dart';
import '../../../domain/enums/equipment_enums.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/settings_section.dart';

class AddEditEquipmentScreen extends StatefulWidget {
  const AddEditEquipmentScreen({this.equipmentId, super.key});

  final String? equipmentId;

  @override
  State<AddEditEquipmentScreen> createState() => _AddEditEquipmentScreenState();
}

class _AddEditEquipmentScreenState extends State<AddEditEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();

  EquipmentCategory _category = EquipmentCategory.cutting;
  EquipmentStatus _status = EquipmentStatus.running;
  DateTime? _purchaseDate;
  DateTime? _nextMaintenanceDueDate;

  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialController = TextEditingController();
  final _purchaseCostController = TextEditingController();
  final _supplierController = TextEditingController();
  final _locationController = TextEditingController();
  final _depreciationController = TextEditingController();
  final _intervalController = TextEditingController();
  final _notesController = TextEditingController();

  bool _populated = false;

  bool get _isEditing => widget.equipmentId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _purchaseCostController.dispose();
    _supplierController.dispose();
    _locationController.dispose();
    _depreciationController.dispose();
    _intervalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateForm(Equipment equipment) {
    if (_populated) return;
    _populated = true;

    _category = equipment.category;
    _status = equipment.status;
    _purchaseDate = equipment.purchaseDate;
    _nextMaintenanceDueDate = equipment.nextMaintenanceDueDate;
    _nameController.text = equipment.name;
    _brandController.text = equipment.brand ?? '';
    _modelController.text = equipment.model ?? '';
    _serialController.text = equipment.serialNumber ?? '';
    _purchaseCostController.text = equipment.purchaseCost != null
        ? equipment.purchaseCost!.toStringAsFixed(0)
        : '';
    _supplierController.text = equipment.supplierName ?? '';
    _locationController.text = equipment.location ?? '';
    _depreciationController.text = equipment.depreciationRatePercent != null
        ? equipment.depreciationRatePercent!.toStringAsFixed(1)
        : '';
    _intervalController.text = equipment.maintenanceIntervalDays != null
        ? equipment.maintenanceIntervalDays.toString()
        : '';
    _notesController.text = equipment.notes ?? '';
  }

  Equipment? _buildEquipment(Equipment? existing) {
    if (existing == null) return null;

    final purchaseCost = double.tryParse(_purchaseCostController.text.trim());
    final depreciation = double.tryParse(_depreciationController.text.trim());
    final interval = int.tryParse(_intervalController.text.trim());

    return existing.copyWith(
      name: _nameController.text.trim(),
      category: _category,
      status: _status,
      brand: _brandController.text.trim().isEmpty
          ? null
          : _brandController.text.trim(),
      model: _modelController.text.trim().isEmpty
          ? null
          : _modelController.text.trim(),
      serialNumber: _serialController.text.trim().isEmpty
          ? null
          : _serialController.text.trim(),
      purchaseDate: _purchaseDate,
      clearPurchaseDate: _purchaseDate == null,
      purchaseCost: purchaseCost,
      clearPurchaseCost: purchaseCost == null,
      supplierName: _supplierController.text.trim().isEmpty
          ? null
          : _supplierController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      depreciationRatePercent: depreciation,
      clearDepreciationRatePercent: depreciation == null,
      nextMaintenanceDueDate: _nextMaintenanceDueDate,
      clearNextMaintenanceDueDate: _nextMaintenanceDueDate == null,
      maintenanceIntervalDays: interval,
      clearMaintenanceIntervalDays: interval == null,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
  }

  void _submit(BuildContext context, Equipment? existing) {
    if (!_formKey.currentState!.validate()) return;
    final equipment = _buildEquipment(existing);
    if (equipment == null) return;
    context.read<EquipmentFormBloc>().add(EquipmentFormSubmitted(equipment));
  }

  Future<void> _pickPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  Future<void> _pickNextDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextMaintenanceDueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _nextMaintenanceDueDate = picked);
  }

  Future<void> _confirmDelete(BuildContext context, String equipmentId) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deleteEquipmentTitle,
      message: AppStrings.deleteEquipmentMessage,
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (confirmed == true && context.mounted) {
      context
          .read<EquipmentFormBloc>()
          .add(EquipmentFormDeleteRequested(equipmentId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EquipmentFormBloc, EquipmentFormState>(
      listener: (context, state) {
        if (state.status == EquipmentFormStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? AppStrings.equipmentUpdated
                    : AppStrings.equipmentSaved,
              ),
            ),
          );
          context.pop(true);
        }
        if (state.status == EquipmentFormStatus.deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.equipmentDeleted)),
          );
          context.pop(true);
        }
        if (state.status == EquipmentFormStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
        if (state.status == EquipmentFormStatus.ready && state.equipment != null) {
          _populateForm(state.equipment!);
        }
      },
      builder: (context, state) {
        if (state.status == EquipmentFormStatus.loading ||
            (state.status == EquipmentFormStatus.initial && _isEditing)) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                _isEditing ? AppStrings.editEquipment : AppStrings.addEquipment,
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final existing = state.equipment;
        final isSaving = state.status == EquipmentFormStatus.saving;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _isEditing ? AppStrings.editEquipment : AppStrings.addEquipment,
            ),
            actions: [
              if (_isEditing && widget.equipmentId != null)
                IconButton(
                  onPressed: isSaving
                      ? null
                      : () => _confirmDelete(context, widget.equipmentId!),
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
                  title: AppStrings.equipmentDetails,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.equipmentName,
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Equipment name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<EquipmentCategory>(
                          initialValue: _category,
                          decoration: const InputDecoration(
                            labelText: AppStrings.equipmentCategory,
                          ),
                          items: EquipmentCategory.values
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
                        DropdownButtonFormField<EquipmentStatus>(
                          initialValue: _status,
                          decoration: const InputDecoration(
                            labelText: AppStrings.equipmentStatus,
                          ),
                          items: EquipmentStatus.values
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
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.equipmentLocation,
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ],
                    ),
                  ),
                ),
                SettingsSection(
                  title: AppStrings.equipmentSpecs,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _brandController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.brand,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _modelController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.model,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _serialController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.serialNumber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SettingsSection(
                  title: AppStrings.purchaseInfo,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(AppStrings.purchaseDate),
                          subtitle: Text(
                            _purchaseDate == null
                                ? AppStrings.notSpecified
                                : DateFormat.yMMMd().format(_purchaseDate!),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_purchaseDate != null)
                                IconButton(
                                  onPressed: isSaving
                                      ? null
                                      : () => setState(() => _purchaseDate = null),
                                  icon: const Icon(Icons.clear),
                                ),
                              const Icon(Icons.calendar_today_outlined),
                            ],
                          ),
                          onTap: isSaving ? null : _pickPurchaseDate,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _purchaseCostController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.purchaseCost,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _supplierController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.supplierVendor,
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _depreciationController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.depreciationRate,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SettingsSection(
                  title: AppStrings.maintenanceSchedule,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(AppStrings.nextMaintenanceDue),
                          subtitle: Text(
                            _nextMaintenanceDueDate == null
                                ? AppStrings.notSpecified
                                : DateFormat.yMMMd()
                                    .format(_nextMaintenanceDueDate!),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_nextMaintenanceDueDate != null)
                                IconButton(
                                  onPressed: isSaving
                                      ? null
                                      : () => setState(
                                            () => _nextMaintenanceDueDate = null,
                                          ),
                                  icon: const Icon(Icons.clear),
                                ),
                              const Icon(Icons.calendar_today_outlined),
                            ],
                          ),
                          onTap: isSaving ? null : _pickNextDueDate,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _intervalController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.maintenanceIntervalDays,
                          ),
                          keyboardType: TextInputType.number,
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
                      maxLines: 3,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: isSaving
                        ? null
                        : () => _submit(context, existing),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isEditing
                                ? AppStrings.saveChanges
                                : AppStrings.saveEquipment,
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

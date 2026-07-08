import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/production/production_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/marble_data.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/raw_material_repository.dart';
import '../../../domain/entities/production_batch.dart';
import '../../../domain/entities/raw_material.dart';
import '../../../domain/enums/production_enums.dart';
import '../../../domain/enums/raw_material_enums.dart';
import '../../utils/auth_context.dart';
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

class AddProductionBatchScreen extends StatefulWidget {
  const AddProductionBatchScreen({this.batchId, super.key});

  final String? batchId;

  @override
  State<AddProductionBatchScreen> createState() =>
      _AddProductionBatchScreenState();
}

class _AddProductionBatchScreenState extends State<AddProductionBatchScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _productionDate = DateTime.now();
  ProductionShift _shift = ProductionShift.morning;
  RawMaterialType? _rawMaterialType;
  ProductionProductType _productType = ProductionProductType.marbleTiles;
  String _marbleVariety = MarbleData.varieties.first;

  final _customVarietyController = TextEditingController();
  final _materialConsumedController = TextEditingController();
  final _gradeAController = TextEditingController();
  final _gradeBController = TextEditingController();
  final _gradeCController = TextEditingController();
  final _rejectController = TextEditingController();
  final _wasteController = TextEditingController();
  final _supervisorController = TextEditingController();
  final _notesController = TextEditingController();

  String? _thickness;
  String? _size;
  double? _availableStock;
  bool _populatedFromEdit = false;

  bool get _isEditing => widget.batchId != null;

  bool get _isCustomVariety => _marbleVariety == 'Custom';

  String get _resolvedMarbleVariety {
    if (!_isCustomVariety) return _marbleVariety;
    return _customVarietyController.text.trim();
  }

  double get _totalOutput =>
      _parse(_gradeAController.text) +
      _parse(_gradeBController.text) +
      _parse(_gradeCController.text) +
      _parse(_rejectController.text);

  RawMaterial? _materialForType(List<RawMaterial> materials) {
    final type = _rawMaterialType;
    if (type == null) return null;
    for (final material in materials) {
      if (material.materialType == type) return material;
    }
    return null;
  }

  String _formatQuantity(double quantity) {
    return quantity.toStringAsFixed(
      quantity == quantity.roundToDouble() ? 0 : 2,
    );
  }

  @override
  void dispose() {
    _customVarietyController.dispose();
    _materialConsumedController.dispose();
    _gradeAController.dispose();
    _gradeBController.dispose();
    _gradeCController.dispose();
    _rejectController.dispose();
    _wasteController.dispose();
    _supervisorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _parse(String value) => double.tryParse(value.trim()) ?? 0;

  String _formatNum(double value) {
    if (value == 0) return '';
    return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
  }

  void _populateFromBatch(ProductionBatch batch) {
    if (_populatedFromEdit) return;
    _populatedFromEdit = true;

    _productionDate = batch.productionDate;
    _shift = batch.shift;
    _rawMaterialType = batch.rawMaterialType;
    _productType = batch.productType;
    if (MarbleData.varieties.contains(batch.marbleVariety)) {
      _marbleVariety = batch.marbleVariety;
    } else {
      _marbleVariety = 'Custom';
      _customVarietyController.text = batch.marbleVariety;
    }
    _thickness = batch.thickness;
    _size = batch.size;
    _materialConsumedController.text = _formatNum(batch.materialConsumed);
    _gradeAController.text = _formatNum(batch.gradeASqFt);
    _gradeBController.text = _formatNum(batch.gradeBSqFt);
    _gradeCController.text = _formatNum(batch.gradeCSqFt);
    _rejectController.text = _formatNum(batch.rejectSqFt);
    if (batch.wasteTons != null && batch.wasteTons! > 0) {
      _wasteController.text = _formatNum(batch.wasteTons!);
    }
    _supervisorController.text = batch.supervisorName ?? '';
    _notesController.text = batch.notes ?? '';
  }

  double get _totalUsable =>
      _parse(_gradeAController.text) +
      _parse(_gradeBController.text) +
      _parse(_gradeCController.text);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _productionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _productionDate = picked);
    }
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final materialType = _rawMaterialType;
    if (materialType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.selectRawMaterialRequired)),
      );
      return;
    }

    if (_isCustomVariety && _resolvedMarbleVariety.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.customVarietyRequired)),
      );
      return;
    }

    if (_totalOutput <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.productionOutputRequired)),
      );
      return;
    }

    context.read<ProductionFormBloc>().add(
          ProductionFormSubmitted(
            productionDate: _productionDate,
            shift: _shift,
            rawMaterialType: materialType,
            materialConsumed: _parse(_materialConsumedController.text),
            productType: _productType,
            marbleVariety: _resolvedMarbleVariety,
            thickness: _thickness,
            size: _size,
            gradeASqFt: _parse(_gradeAController.text),
            gradeBSqFt: _parse(_gradeBController.text),
            gradeCSqFt: _parse(_gradeCController.text),
            rejectSqFt: _parse(_rejectController.text),
            wasteTons: _wasteController.text.trim().isEmpty
                ? null
                : _parse(_wasteController.text),
            supervisorName: _supervisorController.text.trim(),
            notes: _notesController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final factoryId = readFactoryId(context);

    return BlocConsumer<ProductionFormBloc, ProductionFormState>(
      listener: (context, state) {
        if (state.status == ProductionFormStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.isEditing
                    ? AppStrings.productionBatchUpdated
                    : AppStrings.productionBatchSaved,
              ),
            ),
          );
          context.pop(true);
        }
        if (state.status == ProductionFormStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
        if (state.status == ProductionFormStatus.ready &&
            state.isEditing &&
            state.batch != null) {
          _populateFromBatch(state.batch!);
          setState(() {});
        }
      },
      builder: (context, state) {
        if (state.status == ProductionFormStatus.loading ||
            (state.status == ProductionFormStatus.initial && _isEditing)) {
          return Scaffold(
            appBar: AppBar(
              title: AppFormAppBarTitle(
                title: _isEditing
                    ? AppStrings.editProductionBatch
                    : AppStrings.recordProduction,
                subtitle: AppStrings.recordProduction,
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == ProductionFormStatus.failure && state.batch == null) {
          return Scaffold(
            appBar: AppBar(
              title: AppFormAppBarTitle(
                title: AppStrings.editProductionBatch,
                subtitle: AppStrings.recordProduction,
              ),
            ),
            body: Center(
              child: Text(state.errorMessage ?? 'Could not load production batch.'),
            ),
          );
        }

        final isSaving = state.status == ProductionFormStatus.saving;
        final inventoryLocked = state.inventoryFieldsLocked;
        final editingBatch = state.batch;

        return Scaffold(
          appBar: AppBar(
            title: AppFormAppBarTitle(
              title: state.isEditing
                  ? AppStrings.editProductionBatch
                  : AppStrings.recordProduction,
              subtitle:
                  '${DateFormat.yMMMd().format(_productionDate)} · ${_shift.label}',
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              children: [
                if (inventoryLocked) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      AppStrings.productionBatchLockedByQc,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 11,
                            height: 1.35,
                          ),
                    ),
                  ),
                ],
                JobWorkDetailSection(
                  title: AppStrings.batchInformation,
                  icon: Icons.info_outline,
                  child: AppFormSectionBody(
                    children: [
                      AppFormDateField(
                        label: AppStrings.productionDate,
                        value: DateFormat.yMMMd().format(_productionDate),
                        onTap: isSaving ? null : _pickDate,
                      ),
                      AppFormFields.gap,
                      DropdownButtonFormField<ProductionShift>(
                        initialValue: _shift,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.shift,
                        ),
                        items: ProductionShift.values
                            .map(
                              (shift) => DropdownMenuItem(
                                value: shift,
                                child: Text(
                                  shift.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: isSaving || inventoryLocked
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _shift = value);
                                }
                              },
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _supervisorController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.supervisorName,
                        ),
                        textCapitalization: TextCapitalization.words,
                        enabled: !isSaving && !inventoryLocked,
                      ),
                    ],
                  ),
                ),
                JobWorkDetailSection(
                  title: AppStrings.rawMaterialConsumed,
                  icon: Icons.inventory_2_outlined,
                  child: AppFormSectionBody(
                    children: [
                      if (factoryId == null)
                        Text(
                          AppStrings.factoryNotLoaded,
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      else
                        StreamBuilder<List<RawMaterial>>(
                          stream: getIt<RawMaterialRepository>()
                              .watchMaterials(factoryId),
                          builder: (context, snapshot) {
                            final allMaterials = snapshot.data ?? const [];
                            final materials = state.isEditing
                                ? allMaterials
                                    .where(
                                      (material) =>
                                          material.currentStock > 0 ||
                                          material.materialType ==
                                              _rawMaterialType,
                                    )
                                    .toList()
                                : allMaterials
                                    .where((material) => material.currentStock > 0)
                                    .toList();
                            final selectedMaterial =
                                _materialForType(allMaterials);
                            final availableStock =
                                selectedMaterial?.currentStock ??
                                    _availableStock;
                            final stockUnit = selectedMaterial?.unit ??
                                _rawMaterialType?.unit;

                            final returnedStock = editingBatch?.materialConsumed ?? 0;
                            final effectiveAvailable = availableStock == null
                                ? null
                                : availableStock + returnedStock;

                            return Column(
                              children: [
                                DropdownButtonFormField<RawMaterialType?>(
                                  initialValue: _rawMaterialType,
                                  style: AppFormFields.valueStyle(context),
                                  decoration: AppFormFields.decoration(
                                    context,
                                    label: AppStrings.selectRawMaterial,
                                  ),
                                  items: [
                                    const DropdownMenuItem<RawMaterialType?>(
                                      value: null,
                                      child: Text(
                                        AppStrings.selectMaterial,
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    ...materials.map(
                                      (material) =>
                                          DropdownMenuItem<RawMaterialType?>(
                                        value: material.materialType,
                                        child: Text(
                                          '${material.materialType.label} '
                                          '(${_formatQuantity(material.currentStock)} '
                                          '${material.unit.label})',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: isSaving || state.isEditing
                                      ? null
                                      : (value) {
                                          RawMaterial? material;
                                          if (value != null) {
                                            for (final item in materials) {
                                              if (item.materialType == value) {
                                                material = item;
                                                break;
                                              }
                                            }
                                          }
                                          setState(() {
                                            _rawMaterialType = value;
                                            _availableStock =
                                                material?.currentStock;
                                          });
                                        },
                                  validator: (_) {
                                    if (_rawMaterialType == null) {
                                      return AppStrings
                                          .selectRawMaterialRequired;
                                    }
                                    return null;
                                  },
                                ),
                                if (materials.isEmpty) ...[
                                  AppFormFields.gap,
                                  Text(
                                    AppStrings.noRawMaterialInStock,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                                AppFormFields.gap,
                                TextFormField(
                                  controller: _materialConsumedController,
                                  style: AppFormFields.valueStyle(context),
                                  decoration: AppFormFields.decoration(
                                    context,
                                    label: _rawMaterialType == null
                                        ? AppStrings.quantityConsumed
                                        : '${AppStrings.quantityConsumed} '
                                            '(${_rawMaterialType!.unit.label})',
                                  ).copyWith(
                                    helperText: effectiveAvailable != null &&
                                            stockUnit != null
                                        ? '${AppStrings.availableInStock}: '
                                            '${_formatQuantity(effectiveAvailable)} '
                                            '${stockUnit.label}'
                                        : null,
                                    helperStyle: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  enabled: !isSaving && !inventoryLocked,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Quantity is required';
                                    }
                                    final quantity =
                                        double.tryParse(value.trim());
                                    if (quantity == null || quantity <= 0) {
                                      return 'Enter a valid quantity';
                                    }
                                    if (effectiveAvailable != null &&
                                        quantity > effectiveAvailable) {
                                      return AppStrings.quantityExceedsStock;
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
                JobWorkDetailSection(
                  title: AppStrings.productionOutput,
                  icon: Icons.factory_outlined,
                  child: AppFormSectionBody(
                    children: [
                      DropdownButtonFormField<ProductionProductType>(
                        initialValue: _productType,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.productType,
                        ),
                        items: ProductionProductType.values
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
                        onChanged: isSaving || inventoryLocked
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _productType = value);
                                }
                              },
                      ),
                      AppFormFields.gap,
                      DropdownButtonFormField<String>(
                        initialValue: _marbleVariety,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.marbleVariety,
                        ),
                        items: MarbleData.varieties
                            .map(
                              (variety) => DropdownMenuItem(
                                value: variety,
                                child: Text(
                                  variety,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: isSaving || inventoryLocked
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() {
                                    _marbleVariety = value;
                                    if (!_isCustomVariety) {
                                      _customVarietyController.clear();
                                    }
                                  });
                                }
                              },
                      ),
                      if (_isCustomVariety) ...[
                        AppFormFields.gap,
                        TextFormField(
                          controller: _customVarietyController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.customMarbleVarietyName,
                          ),
                          textCapitalization: TextCapitalization.words,
                          enabled: !isSaving && !inventoryLocked,
                          validator: (value) {
                            if (!_isCustomVariety) return null;
                            if (value == null || value.trim().isEmpty) {
                              return AppStrings.customVarietyRequired;
                            }
                            return null;
                          },
                        ),
                      ],
                      AppFormFields.gap,
                      DropdownButtonFormField<String?>(
                        initialValue: _size,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.size,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              AppStrings.notSpecified,
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          ...MarbleData.commonSizes.map(
                            (size) => DropdownMenuItem(
                              value: size,
                              child: Text(
                                size,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                        onChanged: isSaving
                            ? null
                            : (value) => setState(() => _size = value),
                      ),
                      AppFormFields.gap,
                      DropdownButtonFormField<String?>(
                        initialValue: _thickness,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.thickness,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              AppStrings.notSpecified,
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          ...MarbleData.thicknesses.map(
                            (thickness) => DropdownMenuItem(
                              value: thickness,
                              child: Text(
                                thickness,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                        onChanged: isSaving
                            ? null
                            : (value) => setState(() => _thickness = value),
                      ),
                      AppFormFields.gap,
                      Text(
                        AppStrings.outputByGrade,
                        style: AppFormFields.labelStyle(context),
                      ),
                      const SizedBox(height: 8),
                      _GradeField(
                        controller: _gradeAController,
                        label: AppStrings.productionGradeA,
                        enabled: !isSaving && !inventoryLocked,
                        onChanged: (_) => setState(() {}),
                      ),
                      AppFormFields.gap,
                      _GradeField(
                        controller: _gradeBController,
                        label: AppStrings.productionGradeB,
                        enabled: !isSaving && !inventoryLocked,
                        onChanged: (_) => setState(() {}),
                      ),
                      AppFormFields.gap,
                      _GradeField(
                        controller: _gradeCController,
                        label: AppStrings.productionGradeC,
                        enabled: !isSaving && !inventoryLocked,
                        onChanged: (_) => setState(() {}),
                      ),
                      AppFormFields.gap,
                      _GradeField(
                        controller: _rejectController,
                        label: AppStrings.productionReject,
                        enabled: !isSaving && !inventoryLocked,
                        onChanged: (_) => setState(() {}),
                      ),
                      if (_totalOutput <= 0) ...[
                        AppFormFields.gap,
                        Text(
                          AppStrings.productionOutputRequired,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ],
                      if (_totalUsable > 0) ...[
                        AppFormFields.gap,
                        AppFormSummaryRow(
                          label: AppStrings.totalUsableOutput,
                          value:
                              '${_totalUsable.toStringAsFixed(_totalUsable == _totalUsable.roundToDouble() ? 0 : 2)} sq. ft',
                          highlight: true,
                        ),
                      ],
                      AppFormFields.gap,
                      TextFormField(
                        controller: _wasteController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.wasteGeneratedTons,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        enabled: !isSaving && !inventoryLocked,
                      ),
                    ],
                  ),
                ),
                JobWorkDetailSection(
                  title: AppStrings.optionalDetails,
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
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        enabled: !isSaving && !inventoryLocked,
                      ),
                    ],
                  ),
                ),
                AppFormSubmitBar(
                  label: state.isEditing
                      ? AppStrings.saveChanges
                      : AppStrings.saveProductionBatch,
                  isLoading: isSaving,
                  onPressed: isSaving ? null : () => _submit(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GradeField extends StatelessWidget {
  const _GradeField({
    required this.controller,
    required this.label,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: AppFormFields.valueStyle(context),
      decoration: AppFormFields.decoration(
        context,
        label: '$label (sq. ft)',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return null;
        final parsed = double.tryParse(value.trim());
        if (parsed == null || parsed < 0) {
          return 'Enter a valid amount';
        }
        return null;
      },
    );
  }
}

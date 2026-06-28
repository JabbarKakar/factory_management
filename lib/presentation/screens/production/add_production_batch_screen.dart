import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/production/production_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/marble_data.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/raw_material_repository.dart';
import '../../../domain/entities/raw_material.dart';
import '../../../domain/enums/production_enums.dart';
import '../../../domain/enums/raw_material_enums.dart';
import '../../utils/auth_context.dart';
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

class AddProductionBatchScreen extends StatefulWidget {
  const AddProductionBatchScreen({super.key});

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
            const SnackBar(content: Text(AppStrings.productionBatchSaved)),
          );
          context.pop(true);
        }
        if (state.status == ProductionFormStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        final isSaving = state.status == ProductionFormStatus.saving;

        return Scaffold(
          appBar: AppBar(
            title: AppFormAppBarTitle(
              title: AppStrings.recordProduction,
              subtitle:
                  '${DateFormat.yMMMd().format(_productionDate)} · ${_shift.label}',
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              children: [
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
                        onChanged: isSaving
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
                        enabled: !isSaving,
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
                            final materials = (snapshot.data ?? const [])
                                .where((material) => material.currentStock > 0)
                                .toList();
                            final selectedMaterial =
                                _materialForType(materials);
                            final availableStock =
                                selectedMaterial?.currentStock ??
                                    _availableStock;
                            final stockUnit = selectedMaterial?.unit ??
                                _rawMaterialType?.unit;

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
                                  onChanged: isSaving
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
                                    helperText: availableStock != null &&
                                            stockUnit != null
                                        ? '${AppStrings.availableInStock}: '
                                            '${_formatQuantity(availableStock)} '
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
                                  enabled: !isSaving,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Quantity is required';
                                    }
                                    final quantity =
                                        double.tryParse(value.trim());
                                    if (quantity == null || quantity <= 0) {
                                      return 'Enter a valid quantity';
                                    }
                                    if (availableStock != null &&
                                        quantity > availableStock) {
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
                        onChanged: isSaving
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
                        onChanged: isSaving
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
                          enabled: !isSaving,
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
                        enabled: !isSaving,
                        onChanged: (_) => setState(() {}),
                      ),
                      AppFormFields.gap,
                      _GradeField(
                        controller: _gradeBController,
                        label: AppStrings.productionGradeB,
                        enabled: !isSaving,
                        onChanged: (_) => setState(() {}),
                      ),
                      AppFormFields.gap,
                      _GradeField(
                        controller: _gradeCController,
                        label: AppStrings.productionGradeC,
                        enabled: !isSaving,
                        onChanged: (_) => setState(() {}),
                      ),
                      AppFormFields.gap,
                      _GradeField(
                        controller: _rejectController,
                        label: AppStrings.productionReject,
                        enabled: !isSaving,
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
                        enabled: !isSaving,
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
                        enabled: !isSaving,
                      ),
                    ],
                  ),
                ),
                AppFormSubmitBar(
                  label: AppStrings.saveProductionBatch,
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

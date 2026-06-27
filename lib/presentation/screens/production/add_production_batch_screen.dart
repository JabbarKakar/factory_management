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
import '../../widgets/settings_section.dart';

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

  @override
  void dispose() {
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

    context.read<ProductionFormBloc>().add(
          ProductionFormSubmitted(
            productionDate: _productionDate,
            shift: _shift,
            rawMaterialType: materialType,
            materialConsumed: _parse(_materialConsumedController.text),
            productType: _productType,
            marbleVariety: _marbleVariety,
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
            title: const Text(AppStrings.recordProduction),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SettingsSection(
                  title: AppStrings.batchInformation,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(AppStrings.productionDate),
                          subtitle:
                              Text(DateFormat.yMMMd().format(_productionDate)),
                          trailing:
                              const Icon(Icons.calendar_today_outlined),
                          onTap: isSaving ? null : _pickDate,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ProductionShift>(
                          initialValue: _shift,
                          decoration: const InputDecoration(
                            labelText: AppStrings.shift,
                          ),
                          items: ProductionShift.values
                              .map(
                                (shift) => DropdownMenuItem(
                                  value: shift,
                                  child: Text(shift.label),
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
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _supervisorController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.supervisorName,
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ],
                    ),
                  ),
                ),
                SettingsSection(
                  title: AppStrings.rawMaterialConsumed,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: factoryId == null
                        ? const Text(AppStrings.factoryNotLoaded)
                        : StreamBuilder<List<RawMaterial>>(
                            stream: getIt<RawMaterialRepository>()
                                .watchMaterials(factoryId),
                            builder: (context, snapshot) {
                              final materials = (snapshot.data ?? const [])
                                  .where((material) => material.currentStock > 0)
                                  .toList();

                              return Column(
                                children: [
                                  DropdownButtonFormField<RawMaterialType?>(
                                    initialValue: _rawMaterialType,
                                    decoration: const InputDecoration(
                                      labelText: AppStrings.selectRawMaterial,
                                    ),
                                    items: [
                                      const DropdownMenuItem<RawMaterialType?>(
                                        value: null,
                                        child: Text(AppStrings.selectMaterial),
                                      ),
                                      ...materials.map(
                                        (material) =>
                                            DropdownMenuItem<RawMaterialType?>(
                                          value: material.materialType,
                                          child: Text(
                                            '${material.materialType.label} '
                                            '(${material.currentStock.toStringAsFixed(material.currentStock == material.currentStock.roundToDouble() ? 0 : 2)} '
                                            '${material.unit.label})',
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: isSaving
                                        ? null
                                        : (value) => setState(
                                              () => _rawMaterialType = value,
                                            ),
                                    validator: (_) {
                                      if (_rawMaterialType == null) {
                                        return AppStrings.selectRawMaterialRequired;
                                      }
                                      return null;
                                    },
                                  ),
                                  if (materials.isEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      AppStrings.noRawMaterialInStock,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _materialConsumedController,
                                    decoration: InputDecoration(
                                      labelText: _rawMaterialType == null
                                          ? AppStrings.quantityConsumed
                                          : '${AppStrings.quantityConsumed} '
                                              '(${_rawMaterialType!.unit.label})',
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Quantity is required';
                                      }
                                      final quantity =
                                          double.tryParse(value.trim());
                                      if (quantity == null || quantity <= 0) {
                                        return 'Enter a valid quantity';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ),
                SettingsSection(
                  title: AppStrings.productionOutput,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        DropdownButtonFormField<ProductionProductType>(
                          initialValue: _productType,
                          decoration: const InputDecoration(
                            labelText: AppStrings.productType,
                          ),
                          items: ProductionProductType.values
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
                                    setState(() => _productType = value);
                                  }
                                },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _marbleVariety,
                          decoration: const InputDecoration(
                            labelText: AppStrings.marbleVariety,
                          ),
                          items: MarbleData.varieties
                              .map(
                                (variety) => DropdownMenuItem(
                                  value: variety,
                                  child: Text(variety),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _marbleVariety = value);
                                  }
                                },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          initialValue: _size,
                          decoration: const InputDecoration(
                            labelText: AppStrings.size,
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text(AppStrings.notSpecified),
                            ),
                            ...MarbleData.commonSizes.map(
                              (size) => DropdownMenuItem(
                                value: size,
                                child: Text(size),
                              ),
                            ),
                          ],
                          onChanged: isSaving
                              ? null
                              : (value) => setState(() => _size = value),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          initialValue: _thickness,
                          decoration: const InputDecoration(
                            labelText: AppStrings.thickness,
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text(AppStrings.notSpecified),
                            ),
                            ...MarbleData.thicknesses.map(
                              (thickness) => DropdownMenuItem(
                                value: thickness,
                                child: Text(thickness),
                              ),
                            ),
                          ],
                          onChanged: isSaving
                              ? null
                              : (value) => setState(() => _thickness = value),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.outputByGrade,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        _GradeField(
                          controller: _gradeAController,
                          label: AppStrings.productionGradeA,
                          enabled: !isSaving,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        _GradeField(
                          controller: _gradeBController,
                          label: AppStrings.productionGradeB,
                          enabled: !isSaving,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        _GradeField(
                          controller: _gradeCController,
                          label: AppStrings.productionGradeC,
                          enabled: !isSaving,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        _GradeField(
                          controller: _rejectController,
                          label: AppStrings.productionReject,
                          enabled: !isSaving,
                          onChanged: (_) => setState(() {}),
                        ),
                        if (_totalUsable > 0) ...[
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(AppStrings.totalUsableOutput),
                            trailing: Text(
                              '${_totalUsable.toStringAsFixed(_totalUsable == _totalUsable.roundToDouble() ? 0 : 2)} sq. ft',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _wasteController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.wasteGeneratedTons,
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
                  title: AppStrings.optionalDetails,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.notes,
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: isSaving ? null : () => _submit(context),
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(AppStrings.saveProductionBatch),
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
      decoration: InputDecoration(
        labelText: '$label (sq. ft)',
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

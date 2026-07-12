import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/quality/qc_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/quality_check.dart';
import '../../../domain/enums/quality_enums.dart';
import '../../utils/auth_context.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

class RecordQcScreen extends StatefulWidget {
  const RecordQcScreen({
    this.qcId,
    this.referenceType,
    this.referenceId,
    super.key,
  });

  final String? qcId;
  final QcReferenceType? referenceType;
  final String? referenceId;

  @override
  State<RecordQcScreen> createState() => _RecordQcScreenState();
}

class _RecordQcScreenState extends State<RecordQcScreen> {
  final _formKey = GlobalKey<FormState>();

  QcReferenceType _referenceType = QcReferenceType.production;
  String? _selectedReferenceId;
  QcDisposition _disposition = QcDisposition.pass;
  final Set<QcDefectType> _defects = {};
  DateTime _inspectionDate = DateTime.now();
  String? _syncSignature;

  final _inspectorController = TextEditingController();
  final _productController = TextEditingController();
  final _varietyController = TextEditingController();
  final _sizeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _gradeAController = TextEditingController();
  final _gradeBController = TextEditingController();
  final _gradeCController = TextEditingController();
  final _rejectController = TextEditingController();
  final _notesController = TextEditingController();

  bool _populatedFromEdit = false;

  bool get _isEditing => widget.qcId != null;

  @override
  void dispose() {
    _inspectorController.dispose();
    _productController.dispose();
    _varietyController.dispose();
    _sizeController.dispose();
    _quantityController.dispose();
    _gradeAController.dispose();
    _gradeBController.dispose();
    _gradeCController.dispose();
    _rejectController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateFromEditingCheck(QualityCheck check) {
    if (_populatedFromEdit) return;
    _populatedFromEdit = true;

    _referenceType = check.referenceType;
    _selectedReferenceId = check.referenceId;
    _inspectionDate = check.inspectionDate;
    _disposition = check.disposition;
    _defects
      ..clear()
      ..addAll(check.defects);
    _inspectorController.text = check.inspectorName;
    _productController.text = check.productLabel;
    _varietyController.text = check.marbleVariety;
    _sizeController.text = check.sizeThickness ?? '';
    _quantityController.text = check.quantityInspected.toString();
    _gradeAController.text = check.gradeASqFt.toString();
    _gradeBController.text = check.gradeBSqFt.toString();
    _gradeCController.text = check.gradeCSqFt.toString();
    _rejectController.text = check.rejectSqFt.toString();
    _notesController.text = check.notes ?? '';
    _syncSignature =
        '${check.referenceType.name}:${check.referenceId}:${check.quantityInspected}';
  }

  void _syncFromState(QcFormState state) {
    final signature =
        '${state.referenceType.name}:${state.selectedLoad?.id ?? state.selectedBatch?.id ?? state.selectedOrder?.id ?? ''}:${state.prefill.quantityInspected}';
    if (_syncSignature == signature) return;
    _syncSignature = signature;

    _referenceType = state.referenceType;
    _selectedReferenceId = state.selectedLoad?.id ??
        state.selectedBatch?.id ??
        state.selectedOrder?.id;

    final prefill = state.prefill;
    if (prefill.productLabel != null) {
      _productController.text = prefill.productLabel!;
    }
    if (prefill.marbleVariety != null) {
      _varietyController.text = prefill.marbleVariety!;
    }
    if (prefill.sizeThickness != null) {
      _sizeController.text = prefill.sizeThickness!;
    }
    if (prefill.quantityInspected != null && prefill.quantityInspected! > 0) {
      _quantityController.text = prefill.quantityInspected!.toString();
    }
    if (prefill.gradeASqFt != null) {
      _gradeAController.text = prefill.gradeASqFt!.toString();
    }
    if (prefill.gradeBSqFt != null) {
      _gradeBController.text = prefill.gradeBSqFt!.toString();
    }
    if (prefill.gradeCSqFt != null) {
      _gradeCController.text = prefill.gradeCSqFt!.toString();
    }
    if (prefill.rejectSqFt != null) {
      _rejectController.text = prefill.rejectSqFt!.toString();
    }
  }

  QualityCheck? _buildCheck(String factoryId, QcFormState state) {
    if (_selectedReferenceId == null) return null;

    final quantity = double.tryParse(_quantityController.text.trim());
    final gradeA = double.tryParse(_gradeAController.text.trim()) ?? 0;
    final gradeB = double.tryParse(_gradeBController.text.trim()) ?? 0;
    final gradeC = double.tryParse(_gradeCController.text.trim()) ?? 0;
    final reject = double.tryParse(_rejectController.text.trim()) ?? 0;

    if (quantity == null || quantity <= 0) return null;

    final batch = state.selectedBatch;
    final order = state.selectedOrder;
    final load = state.selectedLoad;
    final existing = state.editingCheck;

    if (state.isEditing && existing != null) {
      return QualityCheck(
        id: existing.id,
        qcNumber: existing.qcNumber,
        factoryId: factoryId,
        referenceType: existing.referenceType,
        referenceId: existing.referenceId,
        referenceNumber: existing.referenceNumber,
        referenceLabel: existing.referenceLabel,
        productLabel: _productController.text.trim(),
        marbleVariety: _varietyController.text.trim(),
        sizeThickness: _sizeController.text.trim().isEmpty
            ? null
            : _sizeController.text.trim(),
        inspectionDate: _inspectionDate,
        inspectorName: _inspectorController.text.trim(),
        quantityInspected: quantity,
        gradeASqFt: gradeA,
        gradeBSqFt: gradeB,
        gradeCSqFt: gradeC,
        rejectSqFt: reject,
        defects: _defects.toList(),
        disposition: _disposition,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: existing.createdAt,
      );
    }

    return QualityCheck(
      id: '',
      qcNumber: '',
      factoryId: factoryId,
      referenceType: _referenceType,
      referenceId: _selectedReferenceId!,
      referenceNumber: batch?.batchNumber ??
          load?.loadNumber ??
          order?.jobWorkNumber ??
          '',
      referenceLabel: batch != null
          ? batch.batchNumber
          : load?.customerName ?? order?.customerName ?? '',
      productLabel: _productController.text.trim(),
      marbleVariety: _varietyController.text.trim(),
      sizeThickness: _sizeController.text.trim().isEmpty
          ? null
          : _sizeController.text.trim(),
      inspectionDate: _inspectionDate,
      inspectorName: _inspectorController.text.trim(),
      quantityInspected: quantity,
      gradeASqFt: gradeA,
      gradeBSqFt: gradeB,
      gradeCSqFt: gradeC,
      rejectSqFt: reject,
      defects: _defects.toList(),
      disposition: _disposition,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: DateTime.now(),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _inspectionDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _inspectionDate = picked);
  }

  void _submit(BuildContext context, QcFormState state) {
    if (!_formKey.currentState!.validate()) return;
    final factoryId = readFactoryId(context);
    if (factoryId == null) return;
    final check = _buildCheck(factoryId, state);
    if (check == null) return;
    context.read<QcFormBloc>().add(QcFormSubmitted(check));
  }

  String _appBarSubtitle(QcFormState state) {
    final batch = state.selectedBatch;
    final load = state.selectedLoad;
    final order = state.selectedOrder;
    if (batch != null) {
      return '${batch.batchNumber} · ${batch.marbleVariety}';
    }
    if (load != null) {
      return '${load.loadNumber} · ${load.customerName}';
    }
    if (order != null) {
      return '${order.jobWorkNumber} · ${order.customerName}';
    }
    return _referenceType.label;
  }

  Widget _dropdownLabel(String text) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Widget _buildReferenceDropdown(QcFormState state, bool isSaving) {
    final referenceLocked = state.isEditing;
    if (_referenceType == QcReferenceType.production) {
      return DropdownButtonFormField<String>(
        initialValue: _selectedReferenceId,
        isExpanded: true,
        style: AppFormFields.valueStyle(context),
        decoration: AppFormFields.decoration(
          context,
          label: AppStrings.productionBatchLabel,
        ),
        items: state.productionBatches
            .map(
              (batch) => DropdownMenuItem(
                value: batch.id,
                child: _dropdownLabel(
                  '${batch.batchNumber} · ${batch.marbleVariety}',
                ),
              ),
            )
            .toList(),
        selectedItemBuilder: (context) => state.productionBatches
            .map(
              (batch) => _dropdownLabel(
                '${batch.batchNumber} · ${batch.marbleVariety}',
              ),
            )
            .toList(),
        onChanged: isSaving || referenceLocked
            ? null
            : (value) {
                if (value == null) return;
                context.read<QcFormBloc>().add(QcFormReferenceSelected(value));
              },
        validator: (value) => value == null ? 'Select a batch' : null,
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedReferenceId,
      isExpanded: true,
      style: AppFormFields.valueStyle(context),
      decoration: AppFormFields.decoration(
        context,
        label: AppStrings.jobWorkOrderLabel,
      ),
      items: state.jobWorkOrders
          .map(
            (order) => DropdownMenuItem(
              value: order.id,
              child: _dropdownLabel(
                '${order.jobWorkNumber} · ${order.customerName}',
              ),
            ),
          )
          .toList(),
      selectedItemBuilder: (context) => state.jobWorkOrders
          .map(
            (order) => _dropdownLabel(
              '${order.jobWorkNumber} · ${order.customerName}',
            ),
          )
          .toList(),
      onChanged: isSaving || referenceLocked
          ? null
          : (value) {
              if (value == null) return;
              context.read<QcFormBloc>().add(QcFormReferenceSelected(value));
            },
      validator: (value) => value == null ? 'Select a job work order' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QcFormBloc, QcFormState>(
      listener: (context, state) async {
        if (state.status == QcFormStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.isEditing ? AppStrings.qcUpdated : AppStrings.qcSaved,
              ),
            ),
          );
          if (!state.isEditing && state.advancedToQc) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.jobWorkAdvancedToQc)),
            );
          }
          if (!state.isEditing &&
              (state.pendingMarkReadyJobWorkId != null ||
                  state.pendingMarkReadyLoadId != null)) {
            final confirmed = await AppConfirmDialog.show(
              context,
              title: AppStrings.markReadyAfterQcTitle,
              message: AppStrings.markReadyAfterQcMessage,
              confirmLabel: AppStrings.markReady,
            );
            if (confirmed && context.mounted) {
              final bloc = context.read<QcFormBloc>();
              bloc.add(const QcFormMarkReadyConfirmed());
              final latest = await bloc.stream.firstWhere(
                (s) =>
                    s.markedReady ||
                    (s.status == QcFormStatus.failure &&
                        s.errorMessage != null),
              );
              if (!context.mounted) return;
              if (latest.markedReady) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.jobWorkMarkedReady)),
                );
              } else if (latest.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(latest.errorMessage!)),
                );
              }
            }
          }
          if (context.mounted) {
            context.pop(true);
          }
          return;
        }
        if (state.status == QcFormStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
        if (state.status == QcFormStatus.ready) {
          if (state.isEditing && state.editingCheck != null) {
            _populateFromEditingCheck(state.editingCheck!);
          } else {
            _syncFromState(state);
          }
          setState(() {});
        }
      },
      builder: (context, state) {
        if (state.status == QcFormStatus.loading ||
            state.status == QcFormStatus.initial) {
          return Scaffold(
            appBar: AppBar(
              title: AppFormAppBarTitle(
                title: _isEditing
                    ? AppStrings.editQcInspection
                    : AppStrings.recordQcInspection,
                subtitle: AppStrings.recordQcInspection,
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == QcFormStatus.failure && state.editingCheck == null) {
          return Scaffold(
            appBar: AppBar(
              title: AppFormAppBarTitle(
                title: _isEditing
                    ? AppStrings.editQcInspection
                    : AppStrings.recordQcInspection,
                subtitle: AppStrings.recordQcInspection,
              ),
            ),
            body: Center(
              child: Text(state.errorMessage ?? 'Could not load inspection.'),
            ),
          );
        }

        final isSaving = state.status == QcFormStatus.saving;
        final loadLocked = state.selectedLoad != null;
        final isLoadReference =
            loadLocked || _referenceType == QcReferenceType.jobWorkLoad;
        final referencesEmpty = isLoadReference
            ? false
            : _referenceType == QcReferenceType.production
                ? state.productionBatches.isEmpty
                : state.jobWorkOrders.isEmpty;
        // Hide jobWorkLoad from the manual QC picker; keep it when already
        // scoped to a load (deep-link create or edit).
        final referenceTypeItems = QcReferenceType.values.where(
          (type) =>
              type != QcReferenceType.jobWorkLoad || isLoadReference,
        );

        return Scaffold(
          appBar: AppBar(
            title: AppFormAppBarTitle(
              title: state.isEditing
                  ? AppStrings.editQcInspection
                  : AppStrings.recordQcInspection,
              subtitle: _appBarSubtitle(state),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              children: [
                JobWorkDetailSection(
                  title: AppStrings.qcReference,
                  icon: Icons.link_outlined,
                  child: AppFormSectionBody(
                    children: [
                      DropdownButtonFormField<QcReferenceType>(
                        initialValue: _referenceType,
                        isExpanded: true,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.qcReferenceType,
                        ),
                        items: referenceTypeItems
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: _dropdownLabel(type.label),
                              ),
                            )
                            .toList(),
                        onChanged: isSaving ||
                                state.isEditing ||
                                loadLocked
                            ? null
                            : (value) {
                                if (value == null) return;
                                context.read<QcFormBloc>().add(
                                      QcFormReferenceTypeChanged(value),
                                    );
                              },
                      ),
                      if (isLoadReference) ...[
                        AppFormFields.gap,
                        TextFormField(
                          initialValue: state.selectedLoad != null
                              ? '${state.selectedLoad!.loadNumber} · ${state.selectedLoad!.customerName}'
                              : '${state.editingCheck?.referenceNumber ?? ''} · ${state.editingCheck?.referenceLabel ?? ''}',
                          enabled: false,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.load,
                          ),
                        ),
                      ] else if (referencesEmpty) ...[
                        AppFormFields.gap,
                        Text(
                          _referenceType == QcReferenceType.production
                              ? AppStrings.noQcEligibleProduction
                              : AppStrings.noQcEligibleJobWork,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ] else ...[
                        AppFormFields.gap,
                        _buildReferenceDropdown(state, isSaving),
                      ],
                    ],
                  ),
                ),
                if (_selectedReferenceId != null) ...[
                  JobWorkDetailSection(
                    title: AppStrings.qcInspectionDetails,
                    icon: Icons.fact_check_outlined,
                    child: AppFormSectionBody(
                      children: [
                        AppFormDateField(
                          label: AppStrings.inspectionDate,
                          value: DateFormat.yMMMd().format(_inspectionDate),
                          onTap: isSaving ? null : _pickDate,
                        ),
                        AppFormFields.gap,
                        TextFormField(
                          controller: _inspectorController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.inspectorName,
                          ),
                          textCapitalization: TextCapitalization.words,
                          enabled: !isSaving,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Inspector name is required';
                            }
                            return null;
                          },
                        ),
                        AppFormFields.gap,
                        TextFormField(
                          controller: _productController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.productType,
                          ),
                          enabled: !isSaving,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Product is required';
                            }
                            return null;
                          },
                        ),
                        AppFormFields.gap,
                        TextFormField(
                          controller: _varietyController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.marbleVariety,
                          ),
                          enabled: !isSaving,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Variety is required';
                            }
                            return null;
                          },
                        ),
                        AppFormFields.gap,
                        TextFormField(
                          controller: _sizeController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.sizeThickness,
                          ),
                          enabled: !isSaving,
                        ),
                        AppFormFields.gap,
                        TextFormField(
                          controller: _quantityController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.quantityInspected,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          enabled: !isSaving,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Quantity is required';
                            }
                            final qty = double.tryParse(value.trim());
                            if (qty == null || qty <= 0) {
                              return 'Enter a valid quantity';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  JobWorkDetailSection(
                    title: AppStrings.outputByGrade,
                    icon: Icons.grid_view_outlined,
                    child: AppFormSectionBody(
                      children: [
                        TextFormField(
                          controller: _gradeAController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.gradeA,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          enabled: !isSaving,
                        ),
                        AppFormFields.gap,
                        TextFormField(
                          controller: _gradeBController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.gradeB,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          enabled: !isSaving,
                        ),
                        AppFormFields.gap,
                        TextFormField(
                          controller: _gradeCController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.gradeC,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          enabled: !isSaving,
                        ),
                        AppFormFields.gap,
                        TextFormField(
                          controller: _rejectController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.reject,
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
                    title: AppStrings.defectsFound,
                    icon: Icons.warning_amber_outlined,
                    child: AppFormSectionBody(
                      children: [
                        AppFormChipGroup(
                          label: AppStrings.defectsFound,
                          options: QcDefectType.values
                              .map((defect) => defect.label)
                              .toList(),
                          selected: _defects.map((defect) => defect.label).toSet(),
                          enabled: !isSaving,
                          onToggle: (option, value) {
                            final defect = QcDefectType.values.firstWhere(
                              (type) => type.label == option,
                            );
                            setState(() {
                              if (value) {
                                _defects.add(defect);
                              } else {
                                _defects.remove(defect);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  JobWorkDetailSection(
                    title: AppStrings.qcDisposition,
                    icon: Icons.rule_outlined,
                    child: AppFormSectionBody(
                      children: [
                        DropdownButtonFormField<QcDisposition>(
                          initialValue: _disposition,
                          isExpanded: true,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.qcDisposition,
                          ),
                          items: QcDisposition.values
                              .map(
                                (disposition) => DropdownMenuItem(
                                  value: disposition,
                                  child: _dropdownLabel(disposition.label),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _disposition = value);
                                  }
                                },
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
                          maxLines: 3,
                          enabled: !isSaving,
                        ),
                      ],
                    ),
                  ),
                  AppFormSubmitBar(
                    label: state.isEditing
                        ? AppStrings.saveChanges
                        : AppStrings.saveQcInspection,
                    isLoading: isSaving,
                    onPressed: isSaving ? null : () => _submit(context, state),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

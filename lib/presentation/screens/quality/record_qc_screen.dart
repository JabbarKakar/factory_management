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
import '../../widgets/settings_section.dart';

class RecordQcScreen extends StatefulWidget {
  const RecordQcScreen({
    this.referenceType,
    this.referenceId,
    super.key,
  });

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

  void _syncFromState(QcFormState state) {
    final signature =
        '${state.referenceType.name}:${state.selectedBatch?.id ?? state.selectedOrder?.id ?? ''}:${state.prefill.quantityInspected}';
    if (_syncSignature == signature) return;
    _syncSignature = signature;

    _referenceType = state.referenceType;
    _selectedReferenceId =
        state.selectedBatch?.id ?? state.selectedOrder?.id;

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

    return QualityCheck(
      id: '',
      qcNumber: '',
      factoryId: factoryId,
      referenceType: _referenceType,
      referenceId: _selectedReferenceId!,
      referenceNumber: batch?.batchNumber ?? order?.jobWorkNumber ?? '',
      referenceLabel: batch != null
          ? batch.batchNumber
          : order?.customerName ?? '',
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

  Widget _dropdownLabel(String text) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Widget _buildReferenceDropdown(QcFormState state, bool isSaving) {
    if (_referenceType == QcReferenceType.production) {
      return DropdownButtonFormField<String>(
        initialValue: _selectedReferenceId,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: AppStrings.productionBatchLabel,
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
        onChanged: isSaving
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
      decoration: const InputDecoration(
        labelText: AppStrings.jobWorkOrderLabel,
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
      onChanged: isSaving
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
            const SnackBar(content: Text(AppStrings.qcSaved)),
          );
          if (state.advancedToQc) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.jobWorkAdvancedToQc)),
            );
          }
          if (state.pendingMarkReadyJobWorkId != null) {
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
          _syncFromState(state);
          setState(() {});
        }
      },
      builder: (context, state) {
        if (state.status == QcFormStatus.loading ||
            state.status == QcFormStatus.initial) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.recordQcInspection)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final isSaving = state.status == QcFormStatus.saving;
        final referencesEmpty = _referenceType == QcReferenceType.production
            ? state.productionBatches.isEmpty
            : state.jobWorkOrders.isEmpty;

        return Scaffold(
          appBar: AppBar(title: const Text(AppStrings.recordQcInspection)),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SettingsSection(
                  title: AppStrings.qcReference,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        DropdownButtonFormField<QcReferenceType>(
                          initialValue: _referenceType,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: AppStrings.qcReferenceType,
                          ),
                          items: QcReferenceType.values
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: _dropdownLabel(type.label),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  context.read<QcFormBloc>().add(
                                        QcFormReferenceTypeChanged(value),
                                      );
                                },
                        ),
                        const SizedBox(height: 12),
                        if (referencesEmpty)
                          Text(
                            _referenceType == QcReferenceType.production
                                ? AppStrings.noQcEligibleProduction
                                : AppStrings.noQcEligibleJobWork,
                          )
                        else
                          _buildReferenceDropdown(state, isSaving),
                      ],
                    ),
                  ),
                ),
                if (_selectedReferenceId != null) ...[
                  SettingsSection(
                    title: AppStrings.qcInspectionDetails,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(AppStrings.inspectionDate),
                            subtitle:
                                Text(DateFormat.yMMMd().format(_inspectionDate)),
                            trailing:
                                const Icon(Icons.calendar_today_outlined),
                            onTap: isSaving ? null : _pickDate,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _inspectorController,
                            decoration: const InputDecoration(
                              labelText: AppStrings.inspectorName,
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Inspector name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _productController,
                            decoration: const InputDecoration(
                              labelText: AppStrings.productType,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Product is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _varietyController,
                            decoration: const InputDecoration(
                              labelText: AppStrings.marbleVariety,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Variety is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _sizeController,
                            decoration: const InputDecoration(
                              labelText: AppStrings.sizeThickness,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _quantityController,
                            decoration: const InputDecoration(
                              labelText: AppStrings.quantityInspected,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
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
                  ),
                  SettingsSection(
                    title: AppStrings.outputByGrade,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _gradeAController,
                            decoration: const InputDecoration(
                              labelText: AppStrings.gradeA,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _gradeBController,
                            decoration: const InputDecoration(
                              labelText: AppStrings.gradeB,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _gradeCController,
                            decoration: const InputDecoration(
                              labelText: AppStrings.gradeC,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _rejectController,
                            decoration: const InputDecoration(
                              labelText: AppStrings.reject,
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
                    title: AppStrings.defectsFound,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: QcDefectType.values.map((defect) {
                          final selected = _defects.contains(defect);
                          return FilterChip(
                            label: Text(defect.label),
                            selected: selected,
                            onSelected: isSaving
                                ? null
                                : (value) {
                                    setState(() {
                                      if (value) {
                                        _defects.add(defect);
                                      } else {
                                        _defects.remove(defect);
                                      }
                                    });
                                  },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  SettingsSection(
                    title: AppStrings.qcDisposition,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DropdownButtonFormField<QcDisposition>(
                        initialValue: _disposition,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: AppStrings.qcDisposition,
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
                      onPressed:
                          isSaving ? null : () => _submit(context, state),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(AppStrings.saveQcInspection),
                    ),
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/job_work/job_work_collection_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/services/job_work_collection_quantity_helper.dart';
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/collect_material_form_controller.dart';
import '../../widgets/job_work/collect_material_recording_panel.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

class CollectMaterialScreen extends StatefulWidget {
  const CollectMaterialScreen({required this.jobWorkId, super.key});

  final String jobWorkId;

  @override
  State<CollectMaterialScreen> createState() => _CollectMaterialScreenState();
}

class _CollectMaterialScreenState extends State<CollectMaterialScreen> {
  final _notesController = TextEditingController();
  final _receiverNameController = TextEditingController();
  CollectMaterialFormController? _stockController;
  DateTime _collectedAt = DateTime.now();

  @override
  void dispose() {
    _notesController.dispose();
    _receiverNameController.dispose();
    _stockController?.dispose();
    super.dispose();
  }

  void _ensureController(JobWorkCollectionFormState state) {
    if (_stockController != null || state.order == null) return;
    final remaining = JobWorkCollectionQuantityHelper.remainingLines(
      state.order!,
      state.collections,
    );
    final totals = JobWorkCollectionQuantityHelper.orderTotals(
      state.order!,
      state.collections,
    );
    _stockController = CollectMaterialFormController.fromRemainingLines(
      remainingLines: remaining,
      orderTotals: totals,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _collectedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _collectedAt = picked);
  }

  void _submit(BuildContext context) {
    final controller = _stockController;
    if (controller == null || !controller.hasCollectQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.enterCollectPieces)),
      );
      return;
    }

    context.read<JobWorkCollectionFormBloc>().add(
          JobWorkCollectionFormSubmitted(
            collectedAt: _collectedAt,
            lineItems: controller.buildLineItems(),
            receiverName: _receiverNameController.text.trim(),
            notes: _notesController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JobWorkCollectionFormBloc, JobWorkCollectionFormState>(
      listener: (context, state) {
        if (state.status == JobWorkCollectionFormStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.materialCollected)),
          );
          context.pop(true);
        }
        if (state.errorMessage != null &&
            state.status == JobWorkCollectionFormStatus.ready &&
            _stockController != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        if (state.status == JobWorkCollectionFormStatus.loading ||
            state.status == JobWorkCollectionFormStatus.initial) {
          return Scaffold(
            appBar: AppBar(
              title: const AppFormAppBarTitle(
                title: AppStrings.collectMaterial,
                subtitle: AppStrings.collectMaterial,
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final order = state.order;
        if (order == null) {
          return Scaffold(
            appBar: AppBar(
              title: const AppFormAppBarTitle(
                title: AppStrings.collectMaterial,
                subtitle: AppStrings.collectMaterial,
              ),
            ),
            body: Center(
              child: Text(
                state.errorMessage ?? AppStrings.jobWorkOrderNotFound,
              ),
            ),
          );
        }

        if (state.status == JobWorkCollectionFormStatus.failure &&
            _stockController == null) {
          return Scaffold(
            appBar: AppBar(
              title: AppFormAppBarTitle(
                title: AppStrings.collectMaterial,
                subtitle: order.jobWorkNumber,
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.errorMessage ?? AppStrings.noRemainingStockToCollect,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        _ensureController(state);
        final isSaving = state.status == JobWorkCollectionFormStatus.saving;

        return Scaffold(
          appBar: AppBar(
            title: AppFormAppBarTitle(
              title: AppStrings.collectMaterial,
              subtitle: '${order.jobWorkNumber} · ${order.customerName}',
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            children: [
              JobWorkDetailSection(
                title: AppStrings.collectionDetails,
                icon: Icons.event_outlined,
                child: AppFormSectionBody(
                  children: [
                    AppFormDateField(
                      label: AppStrings.collectionDate,
                      value: DateFormat.yMMMd().format(_collectedAt),
                      onTap: isSaving ? null : _pickDate,
                    ),
                    AppFormFields.gap,
                    TextFormField(
                      controller: _receiverNameController,
                      enabled: !isSaving,
                      style: AppFormFields.valueStyle(context),
                      decoration: AppFormFields.decoration(
                        context,
                        label: AppStrings.receiverName,
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ],
                ),
              ),
              JobWorkDetailSection(
                title: AppStrings.itemsToCollect,
                icon: Icons.inventory_2_outlined,
                child: AppFormSectionBody(
                  children: [
                    CollectMaterialRecordingPanel(
                      controller: _stockController!,
                      enabled: !isSaving,
                      onChanged: () => setState(() {}),
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
                      enabled: !isSaving,
                      style: AppFormFields.valueStyle(context),
                      decoration: AppFormFields.decoration(
                        context,
                        label: AppStrings.notes,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: FilledButton(
                  onPressed: isSaving ? null : () => _submit(context),
                  child: Text(
                    isSaving ? 'Saving…' : AppStrings.confirmCollectMaterial,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

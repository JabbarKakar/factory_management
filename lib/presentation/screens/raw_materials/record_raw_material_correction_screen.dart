import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/raw_material_repository.dart';
import '../../../data/services/raw_material_stock_service.dart';
import '../../../data/services/stock_correction_helper.dart';
import '../../../domain/entities/stock_transaction.dart';
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

class RecordRawMaterialCorrectionScreen extends StatefulWidget {
  const RecordRawMaterialCorrectionScreen({
    required this.materialTypeName,
    required this.transactionId,
    super.key,
  });

  final String materialTypeName;
  final String transactionId;

  @override
  State<RecordRawMaterialCorrectionScreen> createState() =>
      _RecordRawMaterialCorrectionScreenState();
}

class _RecordRawMaterialCorrectionScreenState
    extends State<RecordRawMaterialCorrectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  StockTransaction? _original;
  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;
  DateTime _transactionDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final transaction =
        await getIt<RawMaterialRepository>().getTransaction(widget.transactionId);
    if (!mounted) return;
    if (transaction == null ||
        !StockCorrectionHelper.canCorrectStockTransaction(transaction)) {
      setState(() {
        _loading = false;
        _errorMessage = 'This ledger entry cannot be corrected here.';
      });
      return;
    }
    setState(() {
      _original = transaction;
      _loading = false;
      _reasonController.text = 'Reversal';
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _transactionDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final original = _original;
    if (original == null) return;

    setState(() => _saving = true);
    try {
      await getIt<RawMaterialRepository>().recordCorrection(
        original: original,
        transactionDate: _transactionDate,
        reason: _reasonController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.stockCorrectionRecorded)),
      );
      context.pop(true);
    } on RawMaterialStockException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not record correction.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.ledgerCorrection)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final original = _original;
    if (original == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.ledgerCorrection)),
        body: Center(child: Text(_errorMessage ?? 'Entry not found')),
      );
    }

    final inverse =
        StockCorrectionHelper.inverseStockMovement(original.movementType);

    return Scaffold(
      appBar: AppBar(
        title: const AppFormAppBarTitle(
          title: AppStrings.ledgerCorrection,
          subtitle: AppStrings.correctLedgerEntry,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                AppStrings.ledgerCorrectionHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 11,
                      height: 1.35,
                    ),
              ),
            ),
            JobWorkDetailSection(
              title: AppStrings.stockHistory,
              icon: Icons.history_rounded,
              child: AppFormSectionBody(
                children: [
                  AppFormSummaryRow(
                    label: 'Original entry',
                    value: original.transactionNumber,
                  ),
                  AppFormFields.gap,
                  AppFormSummaryRow(
                    label: AppStrings.movementDate,
                    value: DateFormat.yMMMd().format(original.transactionDate),
                  ),
                  AppFormFields.gap,
                  AppFormSummaryRow(
                    label: 'Original movement',
                    value: original.movementType.label,
                  ),
                  AppFormFields.gap,
                  AppFormSummaryRow(
                    label: 'Quantity',
                    value: Formatters.stockQuantity(
                      original.quantity,
                      original.unit.label,
                    ),
                  ),
                  AppFormFields.gap,
                  AppFormSummaryRow(
                    label: 'Correction posts',
                    value: inverse.label,
                  ),
                ],
              ),
            ),
            JobWorkDetailSection(
              title: AppStrings.ledgerCorrection,
              icon: Icons.tune_outlined,
              child: AppFormSectionBody(
                children: [
                  AppFormDateField(
                    label: AppStrings.movementDate,
                    value: DateFormat.yMMMd().format(_transactionDate),
                    onTap: _saving ? null : _pickDate,
                  ),
                  AppFormFields.gap,
                  TextFormField(
                    initialValue: Formatters.stockQuantity(
                      original.quantity,
                      original.unit.label,
                    ),
                    readOnly: true,
                    style: AppFormFields.valueStyle(context),
                    decoration: AppFormFields.decoration(
                      context,
                      label: 'Quantity (${original.unit.label})',
                    ),
                  ),
                  AppFormFields.gap,
                  TextFormField(
                    controller: _reasonController,
                    style: AppFormFields.valueStyle(context),
                    decoration: AppFormFields.decoration(
                      context,
                      label: AppStrings.adjustmentReason,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppStrings.adjustmentReasonRequired;
                      }
                      return null;
                    },
                    enabled: !_saving,
                  ),
                  AppFormFields.gap,
                  TextFormField(
                    controller: _notesController,
                    style: AppFormFields.valueStyle(context),
                    decoration: AppFormFields.decoration(
                      context,
                      label: AppStrings.notes,
                    ),
                    maxLines: 3,
                    enabled: !_saving,
                  ),
                ],
              ),
            ),
            AppFormSubmitBar(
              label: AppStrings.correctLedgerEntry,
              isLoading: _saving,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

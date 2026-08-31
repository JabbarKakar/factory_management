import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/job_work_invoice_repository.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/services/job_work_container_sync_helper.dart';
import '../../../domain/entities/job_work_invoice.dart';
import '../../../domain/entities/job_work_load.dart';
import '../../../domain/enums/invoice_enums.dart';
import '../../../domain/enums/job_work_enums.dart';
import '../dialogs/app_dialog.dart';
import '../forms/app_form_fields.dart';

class ManageJobWorkCreditDialog extends StatefulWidget {
  const ManageJobWorkCreditDialog({
    required this.availableCredit,
    required this.loads,
    required this.invoices,
    required this.financeMap,
    super.key,
  });

  final double availableCredit;
  final List<JobWorkLoad> loads;
  final List<JobWorkInvoice> invoices;
  final Map<String, ({double charges, double paid, double due, double credit})>
      financeMap;

  static Future<bool> show(
    BuildContext context, {
    required double availableCredit,
    required List<JobWorkLoad> loads,
    required List<JobWorkInvoice> invoices,
    required Map<String, ({double charges, double paid, double due, double credit})>
        financeMap,
  }) async {
    final applied = await AppDialog.show<bool>(
      context,
      barrierDismissible: false,
      child: ManageJobWorkCreditDialog(
        availableCredit: availableCredit,
        loads: loads,
        invoices: invoices,
        financeMap: financeMap,
      ),
    );
    return applied == true;
  }

  @override
  State<ManageJobWorkCreditDialog> createState() =>
      _ManageJobWorkCreditDialogState();
}

class _ManageJobWorkCreditDialogState extends State<ManageJobWorkCreditDialog> {
  final _amountController = TextEditingController();
  String? _selectedLoadId;
  bool _submitting = false;
  String? _errorMessage;

  List<JobWorkLoad> get _loads {
    return widget.loads
        .where((load) => !load.isVirtual && load.status != JobWorkStatus.cancelled)
        .toList()
      ..sort((a, b) => a.loadSequence.compareTo(b.loadSequence));
  }

  double _dueFor(JobWorkLoad load) {
    return widget.financeMap[load.id]?.due ?? load.balanceDue;
  }

  JobWorkLoad? get _selectedLoad {
    final id = _selectedLoadId;
    if (id == null) return null;
    return _loads.where((load) => load.id == id).firstOrNull;
  }

  bool get _hasPayableLoad => _loads.any((load) => _dueFor(load) > 0.005);

  double get _maxForSelection {
    final load = _selectedLoad;
    if (load == null) return 0;
    return JobWorkContainerSyncHelper.maxCreditToApply(
      availableCredit: widget.availableCredit,
      loadDue: _dueFor(load),
    );
  }

  @override
  void initState() {
    super.initState();
    final firstDue = _loads.where((load) => _dueFor(load) > 0.005).firstOrNull;
    if (firstDue != null) {
      _selectedLoadId = firstDue.id;
      _amountController.text =
          ThousandsTextInputFormatter.format(_maxForSelection);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectLoad(String loadId) {
    setState(() {
      _selectedLoadId = loadId;
      _errorMessage = null;
    });
    _amountController.text =
        ThousandsTextInputFormatter.format(_maxForSelection);
  }

  JobWorkInvoice? _invoiceFor(JobWorkLoad load) {
    final loadInvoiceId = load.invoiceId?.trim() ?? '';
    if (loadInvoiceId.isNotEmpty) {
      final byId = widget.invoices.where((invoice) => invoice.id == loadInvoiceId);
      if (byId.isNotEmpty) return byId.first;
    }
    return widget.invoices
        .where((invoice) => (invoice.loadId?.trim() ?? '') == load.id)
        .firstOrNull;
  }

  Future<void> _apply() async {
    final load = _selectedLoad;
    if (load == null || _submitting) return;
    final amount =
        ThousandsTextInputFormatter.tryParseDouble(_amountController.text) ?? 0;
    final maxAmount = _maxForSelection;
    if (amount <= 0.005) {
      setState(() => _errorMessage = 'Enter an amount greater than zero.');
      return;
    }
    if (amount > maxAmount + 0.005) {
      setState(
        () => _errorMessage =
            'Amount cannot exceed ${Formatters.currencyPkr(maxAmount)}.',
      );
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      var invoice = _invoiceFor(load);
      invoice ??=
          await getIt<JobWorkInvoiceRepository>().generateFromLoad(load.id);
      await getIt<PaymentRepository>().applyCustomerCredit(
        invoiceId: invoice.id,
        invoiceType: InvoiceType.jobWork,
        appliedAmount: amount,
        method: PaymentMethod.cash,
        paymentDate: DateTime.now(),
        loadId: load.id,
        notes: 'Applied customer credit to ${load.loadNumber.isEmpty ? 'Load #${load.loadSequence}' : load.loadNumber}',
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = e is StateError
            ? e.message
            : e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final canApply = _hasPayableLoad &&
        _selectedLoad != null &&
        _maxForSelection > 0.005 &&
        !_submitting;

    return AppDialog(
      title: AppStrings.manageCreditTitle,
      message: AppStrings.manageCreditMessage,
      icon: Icons.account_balance_wallet_outlined,
      iconColor: AppColors.success,
      maxWidth: 440,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${AppStrings.availableCredit}: ${Formatters.currencyPkr(widget.availableCredit)}',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 12),
          if (!_hasPayableLoad)
            Text(
              AppStrings.noLoadDueForCredit,
              style: theme.textTheme.bodySmall?.copyWith(
                color: muted,
                fontSize: 12,
                height: 1.4,
              ),
            )
          else ...[
            Text(
              AppStrings.selectLoadToApplyCredit,
              style: AppFormFields.labelStyle(context),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final load in _loads)
                    _LoadChoiceTile(
                      load: load,
                      due: _dueFor(load),
                      paid: widget.financeMap[load.id]?.paid ??
                          load.advanceReceived,
                      selected: _selectedLoadId == load.id,
                      enabled: _dueFor(load) > 0.005 && !_submitting,
                      onTap: () => _selectLoad(load.id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              enabled: canApply,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                ThousandsTextInputFormatter(
                  allowDecimal: true,
                  decimalDigits: 2,
                ),
              ],
              style: AppFormFields.valueStyle(context),
              decoration: AppFormFields.decoration(
                context,
                label: AppStrings.paymentAmount,
              ).copyWith(
                helperText: _selectedLoad == null
                    ? null
                    : 'Up to ${Formatters.currencyPkr(_maxForSelection)}',
              ),
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      actions: [
        AppDialogActions.cancel(
          context,
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
        ),
        AppDialogActions.confirm(
          context,
          label: AppStrings.applyCreditToLoad,
          isLoading: _submitting,
          onPressed: canApply ? _apply : null,
        ),
      ],
    );
  }
}

class _LoadChoiceTile extends StatelessWidget {
  const _LoadChoiceTile({
    required this.load,
    required this.due,
    required this.paid,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final JobWorkLoad load;
  final double due;
  final double paid;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final label = load.loadNumber.isEmpty
        ? '${AppStrings.load} #${load.loadSequence}'
        : load.loadNumber;
    final dueLabel = due > 0.005
        ? '${AppStrings.amountDue}: ${Formatters.currencyPkr(due)}'
        : 'Paid ${Formatters.currencyPkr(paid)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 18,
                  color: enabled
                      ? (selected
                          ? theme.colorScheme.primary
                          : muted)
                      : muted.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: enabled ? null : muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dueLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: due > 0.005 ? AppColors.warning : muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

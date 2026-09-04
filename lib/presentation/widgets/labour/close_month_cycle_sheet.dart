import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/labour/employee_salary_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/monthly_ledger.dart';
import '../../../domain/enums/labour_enums.dart';
import '../../utils/user_permissions_context.dart';
import '../dialogs/app_bottom_sheet.dart';

class CloseMonthCycleSheet extends StatefulWidget {
  const CloseMonthCycleSheet({required this.ledger, super.key});

  final MonthlyLedger ledger;

  static Future<void> show(
    BuildContext context, {
    required MonthlyLedger ledger,
  }) {
    return AppBottomSheet.show<void>(
      context,
      isScrollControlled: true,
      child: BlocProvider.value(
        value: context.read<EmployeeSalaryBloc>(),
        child: CloseMonthCycleSheet(ledger: ledger),
      ),
    );
  }

  @override
  State<CloseMonthCycleSheet> createState() => _CloseMonthCycleSheetState();
}

class _CloseMonthCycleSheetState extends State<CloseMonthCycleSheet> {
  WageCycleRolloverAction _action = WageCycleRolloverAction.carryForward;

  void _submit() {
    final user = readCurrentUser(context);
    context.read<EmployeeSalaryBloc>().add(
          EmployeeSalaryCloseCycleRequested(
            rolloverAction: _action,
            closedBy: user?.id,
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ledger = widget.ledger;
    final remaining = ledger.remainingBalance;
    final nextKey = DateKeys.nextMonthKey(ledger.monthKey);
    final hasBalance = remaining.abs() > 0.005;

    return AppBottomSheet(
      title: AppStrings.closeMonthCycle,
      icon: Icons.lock_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.closeMonthCycleHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hasBalance
                ? remaining > 0
                    ? 'Unpaid ${Formatters.currencyPkr(remaining)} will be handled below.'
                    : 'Overpayment ${Formatters.currencyPkr(remaining.abs())} will be handled below.'
                : 'This month is fully settled. Closing archives the cycle and opens ${DateKeys.monthLabel(nextKey)}.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: remaining.abs() > 0.005
                  ? (remaining > 0 ? AppColors.warning : AppColors.error)
                  : AppColors.success,
            ),
          ),
          if (hasBalance) ...[
            const SizedBox(height: 12),
            RadioGroup<WageCycleRolloverAction>(
              groupValue: _action,
              onChanged: (value) {
                if (value != null) setState(() => _action = value);
              },
              child: Column(
                children: [
                  RadioListTile<WageCycleRolloverAction>(
                    value: WageCycleRolloverAction.carryForward,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      WageCycleRolloverAction.carryForward.label,
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      'Opening balance on ${DateKeys.monthLabel(nextKey)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  RadioListTile<WageCycleRolloverAction>(
                    value: WageCycleRolloverAction.writeOff,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      WageCycleRolloverAction.writeOff.label,
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      remaining > 0
                          ? 'Unpaid amount is not carried forward'
                          : 'Overpayment credit is not carried forward',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.lock_outline, size: 18),
            label: const Text(
              AppStrings.confirmCloseMonth,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

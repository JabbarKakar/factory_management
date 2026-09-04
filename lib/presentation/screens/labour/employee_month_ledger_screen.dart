import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/labour/employee_salary_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_keys.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/factory_role_enums.dart';
import '../../../domain/extensions/app_user_permissions.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/labour/close_month_cycle_sheet.dart';
import '../../widgets/labour/employee_salary_summary_banner.dart';
import '../../widgets/labour/monthly_ledger_breakdown_section.dart';
import '../../widgets/labour/record_wage_payment_sheet.dart';
import '../../widgets/labour/wage_payment_history_section.dart';

class EmployeeMonthLedgerScreen extends StatelessWidget {
  const EmployeeMonthLedgerScreen({
    required this.employeeId,
    required this.monthKey,
    super.key,
  });

  final String employeeId;
  final String monthKey;

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmployeeSalaryBloc, EmployeeSalaryState>(
      listenWhen: (previous, current) =>
          previous.snackbarMessage != current.snackbarMessage &&
          current.snackbarMessage != null,
      listener: (context, state) {
        final message = state.snackbarMessage;
        if (message == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor:
                state.actionStatus == EmployeeSalaryActionStatus.failure
                    ? Theme.of(context).colorScheme.error
                    : null,
          ),
        );
        context
            .read<EmployeeSalaryBloc>()
            .add(const EmployeeSalarySnackbarCleared());
      },
      child: BlocBuilder<EmployeeSalaryBloc, EmployeeSalaryState>(
        builder: (context, state) {
          final employee = state.employee;
          final busy = state.actionStatus == EmployeeSalaryActionStatus.saving;
          final canPay = context.userCanCreate(AppModule.labour) &&
              state.canRecordPayment;
          final canClose = context.userCanEdit(AppModule.labour) &&
              state.ledger != null &&
              !state.ledger!.isClosed;
          final user = readCurrentUser(context);
          final canReopen = state.ledger?.isClosed == true &&
              (user?.factoryRole == FactoryRole.owner ||
                  user?.factoryRole == FactoryRole.factoryManager);

          return Scaffold(
            appBar: AppBar(
              title: Text(DateKeys.monthLabel(monthKey)),
            ),
            floatingActionButton: canPay && employee != null
                ? FloatingActionButton.extended(
                    onPressed: busy
                        ? null
                        : () => RecordWagePaymentSheet.show(
                              context,
                              employee: employee,
                              ledger: state.ledger,
                            ),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text(AppStrings.recordWagePayment),
                  )
                : null,
            body: state.status == EmployeeSalaryStatus.loading ||
                    state.status == EmployeeSalaryStatus.initial
                ? const Center(child: CircularProgressIndicator())
                : employee == null
                    ? Center(
                        child: Text(
                          state.errorMessage ?? AppStrings.employeeNotFound,
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(top: 12, bottom: 88),
                        children: [
                          EmployeeSalarySummaryBanner(
                            employee: employee,
                            ledger: state.ledger,
                            monthKey: monthKey,
                            isBusy: busy,
                            onRecordPayment: canPay
                                ? () => RecordWagePaymentSheet.show(
                                      context,
                                      employee: employee,
                                      ledger: state.ledger,
                                    )
                                : null,
                            onCloseCycle: canClose
                                ? () => CloseMonthCycleSheet.show(
                                      context,
                                      ledger: state.ledger!,
                                    )
                                : null,
                            onReopenCycle: canReopen
                                ? () => _confirmReopen(context)
                                : null,
                            onRefreshPayable: context.userCanEdit(
                                      AppModule.labour,
                                    ) &&
                                    state.ledger?.isClosed != true
                                ? () => context.read<EmployeeSalaryBloc>().add(
                                      const EmployeeSalaryRefreshPayableRequested(),
                                    )
                                : null,
                          ),
                          if (state.ledger != null)
                            MonthlyLedgerBreakdownSection(
                              ledger: state.ledger!,
                            ),
                          WagePaymentHistorySection(
                            payments: state.payments,
                            errorMessage: state.paymentsErrorMessage,
                          ),
                        ],
                      ),
          );
        },
      ),
    );
  }

  Future<void> _confirmReopen(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.reopenMonthConfirmTitle,
      message: AppStrings.reopenMonthConfirmMessage,
      confirmLabel: AppStrings.reopenMonthCycle,
    );
    if (!confirmed || !context.mounted) return;
    context
        .read<EmployeeSalaryBloc>()
        .add(const EmployeeSalaryReopenRequested());
  }
}

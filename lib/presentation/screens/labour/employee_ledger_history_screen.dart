import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/labour/employee_ledger_history_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/labour/monthly_ledger_list_tile.dart';

class EmployeeLedgerHistoryScreen extends StatelessWidget {
  const EmployeeLedgerHistoryScreen({required this.employeeId, super.key});

  final String employeeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.monthlyLedgerHistory),
      ),
      body: BlocBuilder<EmployeeLedgerHistoryBloc, EmployeeLedgerHistoryState>(
        builder: (context, state) {
          if (state.status == EmployeeLedgerHistoryStatus.loading ||
              state.status == EmployeeLedgerHistoryStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == EmployeeLedgerHistoryStatus.failure) {
            return Center(
              child: Text(
                state.errorMessage ?? AppStrings.employeesLoadError,
              ),
            );
          }

          if (state.ledgers.isEmpty) {
            return const EmptyStateView(
              icon: Icons.receipt_long_outlined,
              title: AppStrings.noMonthlyLedgers,
              subtitle: AppStrings.noMonthlyLedgersHint,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            itemCount: state.ledgers.length,
            itemBuilder: (context, index) {
              return MonthlyLedgerListTile(
                employeeId: employeeId,
                ledger: state.ledgers[index],
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/labour/employee_detail_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/job_work/job_work_detail_row.dart';
import '../../widgets/job_work/job_work_detail_section.dart';
import '../../widgets/labour/employee_attendance_action_bar.dart';
import '../../widgets/labour/employee_attendance_history_section.dart';
import '../../widgets/labour/employee_detail_hero.dart';

class EmployeeDetailScreen extends StatelessWidget {
  const EmployeeDetailScreen({required this.employeeId, super.key});

  final String employeeId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeeDetailBloc, EmployeeDetailState>(
      builder: (context, state) {
        if (state.status == EmployeeDetailStatus.loading ||
            state.status == EmployeeDetailStatus.initial) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.employeeDetails)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state.employee == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.employeeDetails)),
            body: Center(
              child: Text(state.errorMessage ?? AppStrings.employeeNotFound),
            ),
          );
        }

        final employee = state.employee!;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.employeeDetails),
                Text(
                  employee.fullName,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: (Theme.of(context).appBarTheme.foregroundColor ??
                                Theme.of(context).colorScheme.onSurface)
                            .withValues(alpha: 0.78),
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
            actions: [
              if (context.userCanEdit(AppModule.labour))
                IconButton(
                  onPressed: () => context.push(
                    RoutePaths.employeeEdit(employee.id),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: AppStrings.editEmployee,
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              EmployeeDetailHero(employee: employee),
              if (employee.isActive &&
                  context.userCanCreate(AppModule.labour))
                EmployeeAttendanceActionBar(
                  onPressed: () => context.push(RoutePaths.attendance),
                ),
              JobWorkDetailSection(
                title: AppStrings.contactInformation,
                icon: Icons.contact_phone_outlined,
                child: JobWorkDetailRows(
                  rows: [
                    JobWorkDetailRow(
                      label: AppStrings.phone,
                      value: employee.phone,
                    ),
                    if (employee.cnic != null && employee.cnic!.isNotEmpty)
                      JobWorkDetailRow(
                        label: AppStrings.cnicNumber,
                        value: employee.cnic!,
                      ),
                  ],
                ),
              ),
              JobWorkDetailSection(
                title: AppStrings.employmentType,
                icon: Icons.payments_outlined,
                child: JobWorkDetailRows(
                  rows: [
                    JobWorkDetailRow(
                      label: AppStrings.workerCategory,
                      value: employee.workerCategory.label,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.employmentType,
                      value: employee.employmentType.label,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.salaryType,
                      value: employee.salaryType.label,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.rateAmount,
                      value:
                          '${Formatters.currencyPkr(employee.rateAmount)} ${employee.rateLabel}',
                      bold: true,
                      highlight: true,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.employeeJoinDate,
                      value: DateFormat.yMMMd().format(employee.joinDate),
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.employeeStatus,
                      value: employee.status.label,
                    ),
                  ],
                ),
              ),
              if (employee.notes != null && employee.notes!.isNotEmpty)
                JobWorkDetailSection(
                  title: AppStrings.notes,
                  icon: Icons.notes_outlined,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Text(
                      employee.notes!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            height: 1.35,
                          ),
                    ),
                  ),
                ),
              EmployeeAttendanceHistorySection(
                records: state.attendanceRecords,
              ),
            ],
          ),
        );
      },
    );
  }
}

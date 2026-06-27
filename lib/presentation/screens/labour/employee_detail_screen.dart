import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/labour/employee_detail_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/attendance_record.dart';
import '../../routes/route_paths.dart';
import '../../widgets/labour/employee_status_badge.dart';
import '../../widgets/settings_section.dart';

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
            title: const Text(AppStrings.employeeDetails),
            actions: [
              IconButton(
                onPressed: () => context.push(
                  RoutePaths.employeeEdit(employee.id),
                ),
                icon: const Icon(Icons.edit_outlined),
                tooltip: AppStrings.editEmployee,
              ),
            ],
          ),
          floatingActionButton: employee.isActive
              ? FloatingActionButton.extended(
                  heroTag: 'fab-employee-attendance',
                  onPressed: () => context.push(RoutePaths.attendance),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text(AppStrings.markAttendance),
                )
              : null,
          body: ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                employee.fullName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            EmployeeStatusBadge(status: employee.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          employee.employeeNumber,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(employee.workerCategory.label),
                      ],
                    ),
                  ),
                ),
              ),
              SettingsSection(
                title: AppStrings.contactInformation,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.phone_outlined),
                      title: const Text(AppStrings.phone),
                      subtitle: Text(employee.phone),
                    ),
                    if (employee.cnic != null && employee.cnic!.isNotEmpty)
                      ListTile(
                        leading: const Icon(Icons.badge_outlined),
                        title: const Text(AppStrings.cnicNumber),
                        subtitle: Text(employee.cnic!),
                      ),
                  ],
                ),
              ),
              SettingsSection(
                title: AppStrings.salaryType,
                child: Column(
                  children: [
                    ListTile(
                      title: const Text(AppStrings.employmentType),
                      trailing: Text(employee.employmentType.label),
                    ),
                    ListTile(
                      title: const Text(AppStrings.salaryType),
                      trailing: Text(employee.salaryType.label),
                    ),
                    ListTile(
                      title: const Text(AppStrings.rateAmount),
                      trailing: Text(
                        '${Formatters.currencyPkr(employee.rateAmount)} ${employee.rateLabel}',
                      ),
                    ),
                    ListTile(
                      title: const Text(AppStrings.employeeJoinDate),
                      trailing: Text(DateFormat.yMMMd().format(employee.joinDate)),
                    ),
                  ],
                ),
              ),
              if (employee.notes != null && employee.notes!.isNotEmpty)
                SettingsSection(
                  title: AppStrings.notes,
                  child: ListTile(
                    title: Text(employee.notes!),
                  ),
                ),
              SettingsSection(
                title: AppStrings.attendanceHistory,
                child: state.attendanceRecords.isEmpty
                    ? const ListTile(
                        title: Text(AppStrings.noAttendanceHistory),
                      )
                    : Column(
                        children: state.attendanceRecords
                            .map(
                              (record) => _AttendanceHistoryTile(record: record),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AttendanceHistoryTile extends StatelessWidget {
  const _AttendanceHistoryTile({required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return ListTile(
      leading: const Icon(Icons.event_available_outlined),
      title: Text(DateFormat.yMMMd().format(record.attendanceDate)),
      subtitle: Text(
        [
          record.status.label,
          if (record.shift != null) record.shift!.label,
        ].join(' · '),
        style: TextStyle(color: muted),
      ),
    );
  }
}

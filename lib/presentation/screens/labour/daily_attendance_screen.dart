import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/labour/daily_attendance_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/labour_enums.dart';
import '../../../domain/enums/production_enums.dart';
import '../../routes/route_paths.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/labour/attendance_status_selector.dart';

class DailyAttendanceScreen extends StatelessWidget {
  const DailyAttendanceScreen({this.initialDate, super.key});

  final DateTime? initialDate;

  Future<void> _pickDate(BuildContext context, DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && context.mounted) {
      context.read<DailyAttendanceBloc>().add(DailyAttendanceDateChanged(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DailyAttendanceBloc, DailyAttendanceState>(
      listenWhen: (prev, curr) =>
          prev.actionMessage != curr.actionMessage ||
          (prev.status != curr.status &&
              curr.status == DailyAttendanceStatus.failure),
      listener: (context, state) {
        if (state.actionMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.actionMessage!)),
          );
        }
        if (state.status == DailyAttendanceStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        final isSaving = state.status == DailyAttendanceStatus.saving;

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.dailyAttendance),
            actions: [
              TextButton.icon(
                onPressed: isSaving || state.entries.isEmpty
                    ? null
                    : () {
                        context.read<DailyAttendanceBloc>().add(
                              const DailyAttendanceMarkAllPresentRequested(),
                            );
                      },
                icon: const Icon(Icons.done_all_outlined),
                label: const Text(AppStrings.markAllPresent),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab-attendance-workers',
            onPressed: () => context.push(RoutePaths.employeesAdd),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text(AppStrings.addEmployee),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: isSaving
                                  ? null
                                  : () {
                                      final previous = state.selectedDate
                                          .subtract(const Duration(days: 1));
                                      context.read<DailyAttendanceBloc>().add(
                                            DailyAttendanceDateChanged(previous),
                                          );
                                    },
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: isSaving
                                    ? null
                                    : () => _pickDate(
                                          context,
                                          state.selectedDate,
                                        ),
                                child: Column(
                                  children: [
                                    Text(
                                      AppStrings.attendanceDate,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium,
                                    ),
                                    Text(
                                      DateFormat.yMMMEd()
                                          .format(state.selectedDate),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: isSaving
                                  ? null
                                  : () {
                                      final next = state.selectedDate
                                          .add(const Duration(days: 1));
                                      if (next.isAfter(DateTime.now())) return;
                                      context.read<DailyAttendanceBloc>().add(
                                            DailyAttendanceDateChanged(next),
                                          );
                                    },
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<AttendanceShift>(
                          key: ValueKey(state.defaultShift),
                          initialValue: state.defaultShift,
                          decoration: const InputDecoration(
                            labelText: AppStrings.defaultShift,
                            isDense: true,
                          ),
                          items: ProductionShift.values
                              .map(
                                (shift) => DropdownMenuItem(
                                  value: shift,
                                  child: Text(shift.label),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (shift) {
                                  if (shift != null) {
                                    context.read<DailyAttendanceBloc>().add(
                                          DailyAttendanceShiftChanged(shift),
                                        );
                                  }
                                },
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SummaryChip(
                              label: AppStrings.attendancePresent,
                              count: state.presentCount,
                              color: Colors.green,
                            ),
                            _SummaryChip(
                              label: AppStrings.attendanceAbsent,
                              count: state.absentCount,
                              color: Colors.red,
                            ),
                            _SummaryChip(
                              label: AppStrings.attendanceUnmarked,
                              count: state.unmarkedCount,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _buildBody(context, state, isSaving),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    DailyAttendanceState state,
    bool isSaving,
  ) {
    if (state.status == DailyAttendanceStatus.loading &&
        state.entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.entries.isEmpty) {
      return EmptyStateView(
        icon: Icons.groups_outlined,
        title: AppStrings.noActiveWorkersForAttendance,
        subtitle: AppStrings.noEmployeesHint,
        action: FilledButton.icon(
          onPressed: () => context.push(RoutePaths.employeesAdd),
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: const Text(AppStrings.addEmployee),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      itemCount: state.entries.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = state.entries[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.employee.fullName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.employee.workerCategory.label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                AttendanceStatusSelector(
                  key: ValueKey(
                    '${entry.employee.id}_${entry.status?.name ?? 'none'}',
                  ),
                  value: entry.status,
                  onChanged: isSaving
                      ? (_) {}
                      : (status) {
                          context.read<DailyAttendanceBloc>().add(
                                DailyAttendanceStatusChanged(
                                  employeeId: entry.employee.id,
                                  status: status,
                                ),
                              );
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Text(
          '$count',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
      label: Text(label),
    );
  }
}

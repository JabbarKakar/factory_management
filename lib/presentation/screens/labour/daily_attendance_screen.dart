import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/labour/daily_attendance_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/job_work/job_work_search_bar.dart';
import '../../widgets/labour/attendance_entry_tile.dart';
import '../../widgets/labour/attendance_header_card.dart';

class DailyAttendanceScreen extends StatefulWidget {
  const DailyAttendanceScreen({this.initialDate, super.key});

  final DateTime? initialDate;

  @override
  State<DailyAttendanceScreen> createState() => _DailyAttendanceScreenState();
}

class _DailyAttendanceScreenState extends State<DailyAttendanceScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchClear() {
    _searchController.clear();
    context.read<DailyAttendanceBloc>().add(
          const DailyAttendanceSearchChanged(''),
        );
  }

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

  Future<void> _handleMarkAllPresent(
    BuildContext context,
    DailyAttendanceState state,
  ) async {
    if (state.nonPresentMarkedCount > 0) {
      final confirmed = await AppConfirmDialog.show(
        context,
        title: AppStrings.markAllPresentConfirmTitle,
        message: AppStrings.markAllPresentConfirmMessage,
        confirmLabel: AppStrings.markAllPresent,
      );
      if (!context.mounted || !confirmed) return;
    }

    context.read<DailyAttendanceBloc>().add(
          const DailyAttendanceMarkAllPresentRequested(),
        );
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
        final dateSubtitle = DateFormat.yMMMd().format(state.selectedDate);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.dailyAttendance),
                Text(
                  state.entries.isEmpty
                      ? dateSubtitle
                      : '${state.visibleEntries.length} workers · '
                          '${state.markedCount} marked · $dateSubtitle',
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
          ),
          floatingActionButton: context.userCanCreate(AppModule.labour)
              ? FloatingActionButton.extended(
                  heroTag: 'fab-attendance-workers',
                  onPressed: () => context.push(RoutePaths.employeesAdd),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text(AppStrings.addEmployee),
                )
              : null,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AttendanceHeaderCard(
                selectedDate: state.selectedDate,
                defaultShift: state.defaultShift,
                presentCount: state.presentCount,
                absentCount: state.absentCount,
                unmarkedCount: state.unmarkedCount,
                isSaving: isSaving,
                canMarkAllPresent: state.entries.isNotEmpty,
                onPreviousDay: () {
                  final previous =
                      state.selectedDate.subtract(const Duration(days: 1));
                  context.read<DailyAttendanceBloc>().add(
                        DailyAttendanceDateChanged(previous),
                      );
                },
                onNextDay: () {
                  final next = state.selectedDate.add(const Duration(days: 1));
                  if (next.isAfter(DateTime.now())) return;
                  context.read<DailyAttendanceBloc>().add(
                        DailyAttendanceDateChanged(next),
                      );
                },
                onPickDate: () => _pickDate(context, state.selectedDate),
                onShiftChanged: (shift) => context
                    .read<DailyAttendanceBloc>()
                    .add(DailyAttendanceShiftChanged(shift)),
                onMarkAllPresent: () => _handleMarkAllPresent(context, state),
              ),
              if (state.entries.isNotEmpty) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: JobWorkSearchBar(
                    controller: _searchController,
                    hintText: AppStrings.searchAttendance,
                    onChanged: (value) => context
                        .read<DailyAttendanceBloc>()
                        .add(DailyAttendanceSearchChanged(value)),
                    onClear: _onSearchClear,
                  ),
                ),
              ],
              const SizedBox(height: 8),
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

    if (state.visibleEntries.isEmpty) {
      return EmptyStateView(
        icon: Icons.search_off_outlined,
        title: AppStrings.noAttendanceMatches,
        subtitle: AppStrings.tryDifferentSearch,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 88),
      itemCount: state.visibleEntries.length,
      itemBuilder: (context, index) {
        final entry = state.visibleEntries[index];
        return AttendanceEntryTile(
          key: ValueKey('${entry.employee.id}_${entry.status?.name ?? 'none'}'),
          entry: entry,
          enabled: !isSaving,
          onStatusChanged: (status) {
            context.read<DailyAttendanceBloc>().add(
                  DailyAttendanceStatusChanged(
                    employeeId: entry.employee.id,
                    status: status,
                  ),
                );
          },
        );
      },
    );
  }
}

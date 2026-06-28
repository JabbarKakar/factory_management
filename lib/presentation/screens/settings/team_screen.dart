import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/team/team_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/enums/factory_role_enums.dart';
import '../../../domain/extensions/app_user_permissions.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/team/team_member_tile.dart';
import '../../widgets/team/team_summary_card.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TeamBloc, TeamState>(
      listenWhen: (prev, curr) =>
          prev.successMessage != curr.successMessage ||
          prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        final message = state.successMessage ?? state.errorMessage;
        if (message == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
      builder: (context, state) {
        final appBarForeground =
            Theme.of(context).appBarTheme.foregroundColor ??
                Theme.of(context).colorScheme.onSurface;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.teamManagement),
                Text(
                  state.users.isEmpty
                      ? AppStrings.teamManagementSubtitle
                      : '${state.users.length} members',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: appBarForeground.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  int _driverCount(List<AppUser> users) {
    return users
        .where((user) => user.factoryRole == FactoryRole.driver)
        .length;
  }

  Widget _buildBody(BuildContext context, TeamState state) {
    if (state.status == TeamStatus.loading && state.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == TeamStatus.failure && state.users.isEmpty) {
      return EmptyStateView(
        icon: Icons.error_outline,
        title: AppStrings.teamLoadError,
        subtitle: state.errorMessage,
        action: ElevatedButton(
          onPressed: () {
            final factoryId = state.factoryId;
            final currentUserId = state.currentUserId;
            if (factoryId == null || currentUserId == null) return;
            context.read<TeamBloc>().add(
                  TeamWatchStarted(
                    factoryId: factoryId,
                    currentUserId: currentUserId,
                  ),
                );
          },
          child: const Text(AppStrings.retry),
        ),
      );
    }

    if (state.users.isEmpty) {
      return const EmptyStateView(
        icon: Icons.groups_outlined,
        title: AppStrings.teamEmpty,
        subtitle: AppStrings.teamManagementSubtitle,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TeamSummaryCard(
          memberCount: state.users.length,
          driverCount: _driverCount(state.users),
        ),
        if (state.isSaving) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(minHeight: 2),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 24),
            itemCount: state.users.length,
            itemBuilder: (context, index) {
              final member = state.users[index];
              final isSelf = member.id == state.currentUserId;

              return TeamMemberTile(
                key: ValueKey(member.id),
                member: member,
                employees: state.employees,
                isSelf: isSelf,
                enabled: !state.isSaving,
                onRoleChanged: (role) {
                  context.read<TeamBloc>().add(
                        TeamRoleChangeRequested(
                          userId: member.id,
                          role: role,
                        ),
                      );
                },
                onEmployeeLinkChanged: (employeeId) {
                  context.read<TeamBloc>().add(
                        TeamEmployeeLinkRequested(
                          userId: member.id,
                          employeeId: employeeId,
                        ),
                      );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

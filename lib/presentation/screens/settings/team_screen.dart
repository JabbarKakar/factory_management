import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/team/team_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/team_invite.dart';
import '../../../domain/enums/factory_role_enums.dart';
import '../../../domain/extensions/app_user_permissions.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/team/invite_code_dialog.dart';
import '../../widgets/team/invite_member_dialog.dart';
import '../../widgets/team/pending_invites_card.dart';
import '../../widgets/team/team_member_tile.dart';
import '../../widgets/team/team_summary_card.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  Future<void> _openInviteDialog(BuildContext context) async {
    final bloc = context.read<TeamBloc>();
    final request = await InviteMemberDialog.show(context);
    if (request == null) return;
    bloc.add(
      TeamInviteRequested(email: request.email, role: request.role),
    );
  }

  Future<void> _confirmRevoke(BuildContext context, TeamInvite invite) async {
    final bloc = context.read<TeamBloc>();
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.revokeInviteTitle,
      message: '${invite.email}\n\n${AppStrings.revokeInviteMessage}',
      confirmLabel: AppStrings.revokeInvite,
      destructive: true,
    );
    if (!confirmed) return;
    bloc.add(TeamInviteRevokeRequested(invite.id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TeamBloc, TeamState>(
      listenWhen: (prev, curr) =>
          prev.successMessage != curr.successMessage ||
          prev.errorMessage != curr.errorMessage ||
          prev.createdInvite != curr.createdInvite,
      listener: (context, state) {
        final createdInvite = state.createdInvite;
        if (createdInvite != null) {
          context.read<TeamBloc>().add(const TeamInviteShareHandled());
          InviteCodeDialog.show(context, createdInvite);
          return;
        }
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
          floatingActionButton: FloatingActionButton.extended(
            onPressed:
                state.isSaving ? null : () => _openInviteDialog(context),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text(AppStrings.inviteMember),
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
        if (state.isSaving) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 90),
            children: [
              TeamSummaryCard(
                memberCount: state.users.length,
                driverCount: _driverCount(state.users),
              ),
              if (state.pendingInvites.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PendingInvitesCard(
                    invites: state.pendingInvites,
                    enabled: !state.isSaving,
                    onRevoke: (invite) => _confirmRevoke(context, invite),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              for (final member in state.users)
                TeamMemberTile(
                  key: ValueKey(member.id),
                  member: member,
                  employees: state.employees,
                  isSelf: member.id == state.currentUserId,
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
                ),
            ],
          ),
        ),
      ],
    );
  }
}

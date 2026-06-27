import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/team/team_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/enums/factory_role_enums.dart';
import '../../../domain/extensions/app_user_permissions.dart';

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
        return Scaffold(
          appBar: AppBar(title: const Text(AppStrings.teamManagement)),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, TeamState state) {
    if (state.status == TeamStatus.loading && state.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == TeamStatus.failure && state.users.isEmpty) {
      return Center(child: Text(state.errorMessage ?? AppStrings.teamLoadError));
    }

    if (state.users.isEmpty) {
      return const Center(child: Text(AppStrings.teamEmpty));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final member = state.users[index];
        final isSelf = member.id == state.currentUserId;

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
              ),
            ),
            title: Text(member.name),
            subtitle: Text(member.email),
            trailing: SizedBox(
              width: 180,
              child: DropdownButtonFormField<FactoryRole>(
                isExpanded: true,
                value: member.factoryRole,
                decoration: InputDecoration(
                  labelText: AppStrings.role,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                items: FactoryRole.values
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(role.label),
                      ),
                    )
                    .toList(),
                onChanged: state.isSaving || isSelf
                    ? null
                    : (role) {
                        if (role == null) return;
                        context.read<TeamBloc>().add(
                              TeamRoleChangeRequested(
                                userId: member.id,
                                role: role,
                              ),
                            );
                      },
              ),
            ),
          ),
        );
      },
    );
  }
}

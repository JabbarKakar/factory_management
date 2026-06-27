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
        final isDriver = member.factoryRole == FactoryRole.driver;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      child: Text(
                        member.name.isNotEmpty
                            ? member.name[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(member.email),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<FactoryRole>(
                  isExpanded: true,
                  initialValue: member.factoryRole,
                  decoration: InputDecoration(
                    labelText: AppStrings.role,
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
                if (isDriver) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: member.employeeId,
                    decoration: InputDecoration(
                      labelText: AppStrings.linkedEmployee,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text(AppStrings.noEmployeeLinked),
                      ),
                      ...state.employees.map(
                        (employee) => DropdownMenuItem<String?>(
                          value: employee.id,
                          child: Text(employee.fullName),
                        ),
                      ),
                    ],
                    onChanged: state.isSaving || isSelf
                        ? null
                        : (employeeId) {
                            context.read<TeamBloc>().add(
                                  TeamEmployeeLinkRequested(
                                    userId: member.id,
                                    employeeId: employeeId,
                                  ),
                                );
                          },
                  ),
                  if (member.employeeId == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        AppStrings.driverEmployeeLinkHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

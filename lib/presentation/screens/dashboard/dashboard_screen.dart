import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/dashboard/dashboard_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/dashboard_kpis.dart';
import '../../widgets/account_menu_button.dart';
import '../../widgets/dashboard/command_center/dashboard_command_center_view.dart';
import '../../widgets/dashboard/command_center/dashboard_fx_theme.dart';
import '../../widgets/notification_bell.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final fxTheme = DashboardFx.theme(context);

    return Theme(
      data: fxTheme,
      child: Scaffold(
        backgroundColor: DashboardFx.bg,
        appBar: AppBar(
          backgroundColor: DashboardFx.bg,
          surfaceTintColor: Colors.transparent,
          title: const Text(AppStrings.dashboard),
          actions: const [
            NotificationBell(),
            AccountMenuButton(),
          ],
        ),
        body: BlocConsumer<DashboardBloc, DashboardState>(
          listenWhen: (prev, curr) =>
              prev.status != curr.status &&
              curr.status == DashboardStatus.failure,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
              );
            }
          },
          builder: (context, state) {
            final user =
                authState is AuthAuthenticated ? authState.user : null;

            if (state.status == DashboardStatus.loading &&
                state.kpis == DashboardKpis.empty) {
              return const Center(
                child: CircularProgressIndicator(
                  color: DashboardFx.primary,
                ),
              );
            }

            return RefreshIndicator(
              color: DashboardFx.primary,
              backgroundColor: DashboardFx.cardBg,
              onRefresh: () async {
                final factoryId = user?.factoryId;
                if (factoryId != null) {
                  context
                      .read<DashboardBloc>()
                      .add(DashboardWatchStarted(factoryId));
                }
              },
              child: Stack(
                children: [
                  DashboardCommandCenterView(
                    state: state,
                    user: user,
                  ),
                  if (state.status == DashboardStatus.failure)
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 8,
                      child: Material(
                        color: DashboardFx.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: DashboardFx.danger,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  state.errorMessage ??
                                      AppStrings.dashboardLoadError,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/dashboard/dashboard_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/dashboard_kpis.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/extensions/app_user_permissions.dart';
import '../../widgets/account_menu_button.dart';
import '../../widgets/dashboard/dashboard_kpi_grid.dart';
import '../../widgets/dashboard/dashboard_production_chart_card.dart';
import '../../widgets/dashboard/dashboard_quick_actions_grid.dart';
import '../../widgets/dashboard/dashboard_recent_activity_card.dart';
import '../../widgets/dashboard/dashboard_revenue_breakdown_card.dart';
import '../../widgets/dashboard/dashboard_revenue_chart_card.dart';
import '../../widgets/dashboard/dashboard_surface.dart';
import '../../widgets/dashboard/dashboard_welcome_banner.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/payment_reminders_card.dart';
import '../../widgets/pending_pickups_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    return Scaffold(
      appBar: AppBar(
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
          final user = authState is AuthAuthenticated ? authState.user : null;

          if (state.status == DashboardStatus.loading &&
              state.kpis == DashboardKpis.empty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              final factoryId = user?.factoryId;
              if (factoryId != null) {
                context
                    .read<DashboardBloc>()
                    .add(DashboardWatchStarted(factoryId));
              }
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                if (state.status == DashboardStatus.failure) ...[
                  _ErrorBanner(
                    message:
                        state.errorMessage ?? AppStrings.dashboardLoadError,
                  ),
                  const SizedBox(height: 16),
                ],
                DashboardWelcomeBanner(user: user),
                if (user != null &&
                    (user.canView(AppModule.sales) ||
                        user.canView(AppModule.jobWork))) ...[
                  const SizedBox(height: 16),
                  PaymentRemindersCard(factoryId: user.factoryId),
                ],
                if (user != null &&
                    user.canView(AppModule.jobWork) &&
                    (state.pendingPickups.isNotEmpty ||
                        state.kpis.pendingPickupCount > 0)) ...[
                  const SizedBox(height: 16),
                  PendingPickupsCard(
                    pendingPickups: state.pendingPickups,
                    totalCount: state.kpis.pendingPickupCount,
                  ),
                ],
                const SizedBox(height: 24),
                DashboardQuickActionsGrid(user: user),
                if (user != null &&
                    (user.canView(AppModule.production) ||
                        user.canView(AppModule.jobWork) ||
                        user.canView(AppModule.sales) ||
                        user.canView(AppModule.plReport))) ...[
                  const SizedBox(height: 28),
                  const DashboardSectionHeader(
                    title: AppStrings.analyticsSection,
                    subtitle: 'Production, revenue & activity',
                    icon: Icons.analytics_outlined,
                  ),
                  const SizedBox(height: 16),
                  if (user.canView(AppModule.production) ||
                      user.canView(AppModule.jobWork))
                    RepaintBoundary(
                      child: DashboardProductionChartCard(
                        points: state.analytics.productionLast7Days,
                        monthlyOwnProductionSqFt:
                            state.kpis.productionThisMonthSqFt,
                      ),
                    ),
                  if (user.canView(AppModule.production) ||
                      user.canView(AppModule.jobWork))
                    const SizedBox(height: 12),
                  if (user.canView(AppModule.sales) ||
                      user.canView(AppModule.jobWork))
                    RepaintBoundary(
                      child: DashboardRevenueChartCard(
                        points: state.analytics.revenueLast30Days,
                      ),
                    ),
                  if (user.canView(AppModule.sales) ||
                      user.canView(AppModule.jobWork))
                    const SizedBox(height: 12),
                  if (user.canView(AppModule.sales) ||
                      user.canView(AppModule.jobWork))
                    RepaintBoundary(
                      child: DashboardRevenueBreakdownCard(
                        slices: state.analytics.revenueBreakdownThisMonth,
                      ),
                    ),
                  if (user.canView(AppModule.sales) ||
                      user.canView(AppModule.jobWork))
                    const SizedBox(height: 12),
                  if (user.canView(AppModule.sales) ||
                      user.canView(AppModule.jobWork))
                    RepaintBoundary(
                      child: DashboardRecentActivityCard(
                        items: state.analytics.recentActivity,
                      ),
                    ),
                ],
                const SizedBox(height: 28),
                DashboardKpiGrid(kpis: state.kpis, user: user),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardSurfaceCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

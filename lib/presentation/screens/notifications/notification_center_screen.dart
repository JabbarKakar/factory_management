import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/notification/notification_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../domain/entities/app_notification.dart';
import '../../../domain/enums/invoice_enums.dart';
import '../../../domain/enums/notification_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/payment_reminder_actions.dart';
import '../../widgets/dashboard/dashboard_surface.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/notifications/notification_card.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({
    this.initialFilter = NotificationFilter.all,
    super.key,
  });

  final NotificationFilter initialFilter;

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != NotificationFilter.all) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        getIt<NotificationBloc>().add(
          NotificationFilterChanged(widget.initialFilter),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<NotificationBloc>(),
      child: const _NotificationCenterView(),
    );
  }
}

class _NotificationCenterView extends StatelessWidget {
  const _NotificationCenterView();

  static const double _compactBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        final isCompact =
            MediaQuery.sizeOf(context).width < _compactBreakpoint;
        final appBarForeground =
            Theme.of(context).appBarTheme.foregroundColor ??
                Theme.of(context).colorScheme.onSurface;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.notifications),
                if (state.unreadCount > 0)
                  Text(
                    '${state.unreadCount} unread',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: appBarForeground.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
              ],
            ),
            actions: [
              if (state.unreadCount > 0)
                IconButton(
                  onPressed: () => context.read<NotificationBloc>().add(
                        const NotificationMarkAllReadRequested(),
                      ),
                  icon: const Icon(Icons.done_all_outlined),
                  tooltip: AppStrings.markAllRead,
                ),
              IconButton(
                onPressed: state.isScanning
                    ? null
                    : () => context.read<NotificationBloc>().add(
                          const NotificationScanRequested(),
                        ),
                icon: state.isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded),
                tooltip: AppStrings.scanNotificationsHint,
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, isCompact ? 8 : 12),
                child: _NotificationSummaryStrip(state: state),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _NotificationFilterBar(
                  selected: state.filter,
                  compact: isCompact,
                  onChanged: (filter) => context.read<NotificationBloc>().add(
                        NotificationFilterChanged(filter),
                      ),
                ),
              ),
              SizedBox(height: isCompact ? 8 : 12),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, NotificationState state) {
    if (state.status == NotificationStatus.loading &&
        state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == NotificationStatus.failure &&
        state.notifications.isEmpty) {
      return EmptyStateView(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load notifications',
        subtitle: state.errorMessage,
        action: FilledButton.tonalIcon(
          onPressed: () => context.read<NotificationBloc>().add(
                const NotificationScanRequested(),
              ),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      );
    }

    if (state.visibleNotifications.isEmpty) {
      return EmptyStateView(
        icon: Icons.notifications_none_outlined,
        title: AppStrings.noNotifications,
        subtitle: state.filter == NotificationFilter.all
            ? 'Alerts for payments, stock, and operations appear here.'
            : 'No alerts match the "${state.filter.label}" filter.',
        action: state.filter != NotificationFilter.all
            ? FilledButton.tonal(
                onPressed: () => context.read<NotificationBloc>().add(
                      const NotificationFilterChanged(NotificationFilter.all),
                    ),
                child: const Text('Show all'),
              )
            : null,
      );
    }

    final groups = _groupNotifications(state.visibleNotifications);

    return RefreshIndicator(
      onRefresh: () async {
        context.read<NotificationBloc>().add(const NotificationScanRequested());
        await Future<void>.delayed(const Duration(milliseconds: 500));
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          for (final entry in groups) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: _SectionHeader(label: entry.key),
            ),
            for (final notification in entry.value)
              NotificationCard(
                notification: notification,
                isUnread: state.userId != null &&
                    !notification.isReadBy(state.userId!),
                onTap: () => _openNotification(context, notification),
                onDismissed: () => context.read<NotificationBloc>().add(
                      NotificationMarkReadRequested(notification.id),
                    ),
                onSendReminder: notification.type.isPaymentType &&
                        notification.invoiceId != null &&
                        notification.customerId != null
                    ? () => _sendPaymentReminder(context, notification)
                    : null,
              ),
          ],
        ],
      ),
    );
  }

  void _openNotification(BuildContext context, AppNotification notification) {
    final bloc = context.read<NotificationBloc>();
    bloc.add(NotificationMarkReadRequested(notification.id));

    if (notification.qualityCheckId != null) {
      context.push(RoutePaths.qualityCheckDetail(notification.qualityCheckId!));
      return;
    }
    if (notification.deliveryId != null) {
      context.push(RoutePaths.deliveryDetail(notification.deliveryId!));
      return;
    }
    if (notification.equipmentId != null) {
      context.push(RoutePaths.equipmentDetail(notification.equipmentId!));
      return;
    }
    if (notification.rawMaterialType != null) {
      context.push(
        RoutePaths.rawMaterialDetail(notification.rawMaterialType!),
      );
      return;
    }
    if (notification.finishedGoodId != null) {
      context.push(
        RoutePaths.finishedGoodDetail(notification.finishedGoodId!),
      );
      return;
    }
    if (notification.invoiceId != null) {
      final paymentRoute = notification.isSalesInvoice
          ? RoutePaths.salesRecordPayment(notification.invoiceId!)
          : RoutePaths.recordPayment(notification.invoiceId!);
      context.push(paymentRoute);
      return;
    }
    if (notification.salesOrderId != null) {
      context.push(RoutePaths.salesDetail(notification.salesOrderId!));
      return;
    }
    if (notification.customerId != null) {
      context.push(RoutePaths.customerDetail(notification.customerId!));
      return;
    }
    if (notification.jobWorkId != null) {
      context.push(RoutePaths.jobWorkDetail(notification.jobWorkId!));
    }
  }

  Future<void> _sendPaymentReminder(
    BuildContext context,
    AppNotification notification,
  ) async {
    final invoiceId = notification.invoiceId;
    final customerId = notification.customerId;
    if (invoiceId == null || customerId == null) return;

    final invoiceType = notification.invoiceType ??
        (notification.isSalesInvoice
            ? InvoiceType.sales
            : InvoiceType.jobWork);
    final amountDue = notification.amountDue ?? 0;
    if (amountDue <= 0) return;

    try {
      await PaymentReminderActions.sendWhatsApp(
        context: context,
        customerId: customerId,
        customerName: _customerNameFromTitle(notification.title),
        invoiceId: invoiceId,
        invoiceNumber: notification.invoiceNumber ?? invoiceId,
        invoiceType: invoiceType,
        amountDue: amountDue,
        dueDate: notification.dueDate,
        isOverdue: notification.type == NotificationType.paymentOverdue,
      );
    } catch (error) {
      if (context.mounted) {
        PaymentReminderActions.showError(context, error);
      }
    }
  }

  String _customerNameFromTitle(String title) {
    final parts = title.split('—');
    if (parts.length >= 2) {
      final name = parts.last.trim();
      if (name.isNotEmpty) return name;
    }
    return title;
  }

  List<MapEntry<String, List<AppNotification>>> _groupNotifications(
    List<AppNotification> notifications,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final order = [AppStrings.today, AppStrings.yesterday, AppStrings.earlier];
    final grouped = <String, List<AppNotification>>{};

    for (final notification in notifications) {
      final created = notification.createdAt;
      final day = DateTime(created.year, created.month, created.day);
      final label = day == today
          ? AppStrings.today
          : day == yesterday
              ? AppStrings.yesterday
              : AppStrings.earlier;
      grouped.putIfAbsent(label, () => []).add(notification);
    }

    return order
        .where(grouped.containsKey)
        .map((key) => MapEntry(key, grouped[key]!))
        .toList();
  }
}

class _NotificationSummaryStrip extends StatelessWidget {
  const _NotificationSummaryStrip({required this.state});

  final NotificationState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = state.visibleNotifications.length;
    final unread = state.unreadCount;

    return DashboardSurfaceCard(
      compact: true,
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              unread > 0
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unread > 0 ? '$unread need attention' : 'You are up to date',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  total == 0
                      ? 'No alerts in this view'
                      : '$total alert${total == 1 ? '' : 's'} in this view',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (state.isScanning)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _NotificationFilterBar extends StatelessWidget {
  const _NotificationFilterBar({
    required this.selected,
    required this.compact,
    required this.onChanged,
  });

  final NotificationFilter selected;
  final bool compact;
  final ValueChanged<NotificationFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: NotificationFilter.values.map((filter) {
          final isSelected = selected == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter.label,
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              avatar: Icon(
                _iconFor(filter),
                size: compact ? 14 : 16,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              selected: isSelected,
              visualDensity:
                  compact ? VisualDensity.compact : VisualDensity.standard,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 4 : 8,
                vertical: compact ? 0 : 2,
              ),
              onSelected: (_) => onChanged(filter),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _iconFor(NotificationFilter filter) {
    return switch (filter) {
      NotificationFilter.all => Icons.inbox_rounded,
      NotificationFilter.payments => Icons.payments_outlined,
      NotificationFilter.dueThisWeek => Icons.event_rounded,
      NotificationFilter.overdue => Icons.warning_amber_rounded,
      NotificationFilter.jobWork => Icons.content_cut_outlined,
      NotificationFilter.stock => Icons.inventory_2_outlined,
      NotificationFilter.operations => Icons.precision_manufacturing_outlined,
    };
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

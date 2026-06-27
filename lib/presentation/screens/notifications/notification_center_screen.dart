import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/notification/notification_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../domain/entities/app_notification.dart';
import '../../../domain/enums/notification_enums.dart';
import '../../routes/route_paths.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.notifications),
            actions: [
              if (state.unreadCount > 0)
                TextButton(
                  onPressed: () => context.read<NotificationBloc>().add(
                        const NotificationMarkAllReadRequested(),
                      ),
                  child: const Text(AppStrings.markAllRead),
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
                    : const Icon(Icons.refresh),
                tooltip: AppStrings.scanNotificationsHint,
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: NotificationFilter.values.map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter.label),
                          selected: state.filter == filter,
                          onSelected: (_) =>
                              context.read<NotificationBloc>().add(
                                    NotificationFilterChanged(filter),
                                  ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
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
      return Center(child: Text(state.errorMessage ?? 'Error'));
    }

    if (state.visibleNotifications.isEmpty) {
      return const Center(child: Text(AppStrings.noNotifications));
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                entry.key,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            for (final notification in entry.value)
              _NotificationTile(
                notification: notification,
                userId: state.userId,
                onTap: () => _openNotification(context, notification),
                onDismissed: () => context.read<NotificationBloc>().add(
                      NotificationMarkReadRequested(notification.id),
                    ),
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

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.userId,
    required this.onTap,
    required this.onDismissed,
  });

  final AppNotification notification;
  final String? userId;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final isUnread =
        userId != null && !notification.isReadBy(userId!);
    final accent = _priorityColor(notification.priority);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.primaryContainer,
        child: const Icon(Icons.done_all),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: accent.withValues(alpha: 0.15),
          child: Icon(_iconFor(notification.type), color: accent, size: 20),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.body),
            const SizedBox(height: 4),
            Text(
              DateFormat.yMMMd().add_jm().format(notification.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        isThreeLine: true,
        trailing: isUnread
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }

  Color _priorityColor(NotificationPriority priority) {
    return switch (priority) {
      NotificationPriority.critical => AppColors.overdue,
      NotificationPriority.high => AppColors.warning,
      NotificationPriority.medium => AppColors.dueSoon,
      NotificationPriority.low => AppColors.textSecondary,
      NotificationPriority.info => AppColors.primary,
    };
  }

  IconData _iconFor(NotificationType type) {
    return switch (type) {
      NotificationType.partialPaymentReceived => Icons.payments_outlined,
      NotificationType.paymentOverdue => Icons.warning_amber_rounded,
      NotificationType.lowRawMaterialStock ||
      NotificationType.lowFinishedGoodsStock =>
        Icons.inventory_2_outlined,
      NotificationType.equipmentMaintenanceDueSoon ||
      NotificationType.equipmentMaintenanceOverdue =>
        Icons.build_circle_outlined,
      NotificationType.pendingDelivery => Icons.local_shipping_outlined,
      NotificationType.qcReject => Icons.cancel_outlined,
      NotificationType.jobWorkReadyForPickup ||
      NotificationType.jobWorkNotCollected =>
        Icons.content_cut_outlined,
      _ => Icons.schedule,
    };
  }
}

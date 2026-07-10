import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/notification_repository.dart';
import '../../data/services/notification_engine_service.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/enums/notification_enums.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc({
    required NotificationRepository repository,
    required NotificationEngineService engineService,
  })  : _repository = repository,
        _engineService = engineService,
        super(const NotificationState()) {
    on<NotificationWatchStarted>(_onWatchStarted);
    on<NotificationWatchStopped>(_onWatchStopped);
    on<NotificationFilterChanged>(_onFilterChanged);
    on<NotificationMarkReadRequested>(_onMarkRead);
    on<NotificationMarkAllReadRequested>(_onMarkAllRead);
    on<NotificationScanRequested>(_onScanRequested);
    on<_NotificationListUpdated>(_onListUpdated);
    on<_NotificationStreamFailed>(_onStreamFailed);
  }

  final NotificationRepository _repository;
  final NotificationEngineService _engineService;
  StreamSubscription<List<AppNotification>>? _subscription;
  String? _userId;

  Future<void> _onWatchStarted(
    NotificationWatchStarted event,
    Emitter<NotificationState> emit,
  ) async {
    _userId = event.userId;
    emit(
      state.copyWith(
        status: NotificationStatus.loading,
        factoryId: event.factoryId,
        userId: event.userId,
      ),
    );

    await _subscription?.cancel();
    _subscription = _repository.watchNotifications(event.factoryId).listen(
          (notifications) => add(_NotificationListUpdated(notifications)),
          onError: (_) => add(
            const _NotificationStreamFailed(
              'Could not load notifications.',
            ),
          ),
        );

    await _engineService.runIfNeeded(event.factoryId);
  }

  Future<void> _onWatchStopped(
    NotificationWatchStopped event,
    Emitter<NotificationState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _onFilterChanged(
    NotificationFilterChanged event,
    Emitter<NotificationState> emit,
  ) {
    emit(
      state.copyWith(
        filter: event.filter,
        visibleNotifications: _applyFilter(state.notifications, event.filter),
      ),
    );
  }

  Future<void> _onMarkRead(
    NotificationMarkReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final userId = _userId;
    if (userId == null) return;
    await _repository.markAsRead(event.notificationId, userId);
  }

  Future<void> _onMarkAllRead(
    NotificationMarkAllReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final factoryId = state.factoryId;
    final userId = _userId;
    if (factoryId == null || userId == null) return;
    await _repository.markAllAsRead(factoryId, userId);
  }

  Future<void> _onScanRequested(
    NotificationScanRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final factoryId = state.factoryId;
    if (factoryId == null) return;
    emit(state.copyWith(isScanning: true));
    try {
      await _engineService.scan(factoryId);
    } finally {
      emit(state.copyWith(isScanning: false));
    }
  }

  void _onListUpdated(
    _NotificationListUpdated event,
    Emitter<NotificationState> emit,
  ) {
    final userId = _userId;
    final unreadCount = userId == null
        ? 0
        : event.notifications
            .where((notification) => !notification.isReadBy(userId))
            .length;

    emit(
      state.copyWith(
        status: NotificationStatus.loaded,
        notifications: event.notifications,
        visibleNotifications: _applyFilter(event.notifications, state.filter),
        unreadCount: unreadCount,
        errorMessage: null,
      ),
    );
  }

  void _onStreamFailed(
    _NotificationStreamFailed event,
    Emitter<NotificationState> emit,
  ) {
    emit(
      state.copyWith(
        status: NotificationStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  List<AppNotification> _applyFilter(
    List<AppNotification> notifications,
    NotificationFilter filter,
  ) {
    return switch (filter) {
      NotificationFilter.all => notifications,
      NotificationFilter.payments =>
        notifications.where((n) => n.type.isPaymentType).toList(),
      NotificationFilter.jobWork =>
        notifications.where((n) => n.type.isJobWorkType).toList(),
      NotificationFilter.stock =>
        notifications.where((n) => n.type.isStockType).toList(),
      NotificationFilter.operations =>
        notifications.where((n) => n.type.isOperationsType).toList(),
      NotificationFilter.dueThisWeek => notifications.where((n) {
          if (n.type == NotificationType.paymentOverdue ||
              n.type == NotificationType.partialPaymentReceived) {
            return false;
          }
          if (!n.type.isPaymentType) return false;
          final due = n.dueDate;
          if (due == null) return false;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final dueDay = DateTime(due.year, due.month, due.day);
          final daysUntil = dueDay.difference(today).inDays;
          return daysUntil >= 0 && daysUntil <= 7;
        }).toList(),
      NotificationFilter.overdue => notifications
          .where(
            (n) =>
                n.type == NotificationType.paymentOverdue ||
                (n.type == NotificationType.pendingDelivery &&
                    (n.daysOverdue ?? 0) > 0),
          )
          .toList(),
    };
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

final class _NotificationListUpdated extends NotificationEvent {
  const _NotificationListUpdated(this.notifications);

  final List<AppNotification> notifications;

  @override
  List<Object?> get props => [notifications];
}

final class _NotificationStreamFailed extends NotificationEvent {
  const _NotificationStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/notification_repository.dart';
import '../../data/services/payment_due_scanner_service.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/enums/notification_enums.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc({
    required NotificationRepository repository,
    required PaymentDueScannerService scannerService,
  })  : _repository = repository,
        _scannerService = scannerService,
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
  final PaymentDueScannerService _scannerService;
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

    await _scannerService.runIfNeeded(event.factoryId);
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
      await _scannerService.scan(factoryId);
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

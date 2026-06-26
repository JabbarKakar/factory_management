part of 'notification_bloc.dart';

sealed class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

final class NotificationWatchStarted extends NotificationEvent {
  const NotificationWatchStarted({
    required this.factoryId,
    required this.userId,
  });

  final String factoryId;
  final String userId;

  @override
  List<Object?> get props => [factoryId, userId];
}

final class NotificationWatchStopped extends NotificationEvent {
  const NotificationWatchStopped();
}

final class NotificationFilterChanged extends NotificationEvent {
  const NotificationFilterChanged(this.filter);

  final NotificationFilter filter;

  @override
  List<Object?> get props => [filter];
}

final class NotificationMarkReadRequested extends NotificationEvent {
  const NotificationMarkReadRequested(this.notificationId);

  final String notificationId;

  @override
  List<Object?> get props => [notificationId];
}

final class NotificationMarkAllReadRequested extends NotificationEvent {
  const NotificationMarkAllReadRequested();
}

final class NotificationScanRequested extends NotificationEvent {
  const NotificationScanRequested();
}

part of 'notification_bloc.dart';

enum NotificationStatus {
  initial,
  loading,
  loaded,
  failure,
}

class NotificationState extends Equatable {
  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notifications = const [],
    this.visibleNotifications = const [],
    this.unreadCount = 0,
    this.filter = NotificationFilter.all,
    this.factoryId,
    this.userId,
    this.isScanning = false,
    this.errorMessage,
  });

  final NotificationStatus status;
  final List<AppNotification> notifications;
  final List<AppNotification> visibleNotifications;
  final int unreadCount;
  final NotificationFilter filter;
  final String? factoryId;
  final String? userId;
  final bool isScanning;
  final String? errorMessage;

  NotificationState copyWith({
    NotificationStatus? status,
    List<AppNotification>? notifications,
    List<AppNotification>? visibleNotifications,
    int? unreadCount,
    NotificationFilter? filter,
    String? factoryId,
    String? userId,
    bool? isScanning,
    String? errorMessage,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      visibleNotifications:
          visibleNotifications ?? this.visibleNotifications,
      unreadCount: unreadCount ?? this.unreadCount,
      filter: filter ?? this.filter,
      factoryId: factoryId ?? this.factoryId,
      userId: userId ?? this.userId,
      isScanning: isScanning ?? this.isScanning,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        notifications,
        visibleNotifications,
        unreadCount,
        filter,
        factoryId,
        userId,
        isScanning,
        errorMessage,
      ];
}

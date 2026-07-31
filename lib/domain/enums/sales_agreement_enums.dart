import '../enums/sales_enums.dart';

/// Derived Sales Agreement container status (not the order dispatch FSM).
enum SalesAgreementSummaryStatus {
  active,
  pendingDelivery,
  idle,
  cancelled;

  String get firestoreValue => name;

  String get label => switch (this) {
        SalesAgreementSummaryStatus.active => 'Active',
        SalesAgreementSummaryStatus.pendingDelivery => 'Pending Delivery',
        SalesAgreementSummaryStatus.idle => 'Idle',
        SalesAgreementSummaryStatus.cancelled => 'Cancelled',
      };

  static SalesAgreementSummaryStatus fromString(String? value) {
    return SalesAgreementSummaryStatus.values.firstWhere(
      (status) => status.firestoreValue == value,
      orElse: () => SalesAgreementSummaryStatus.active,
    );
  }

  /// Derive summary from child order statuses.
  static SalesAgreementSummaryStatus fromOrderStatuses(
    Iterable<SalesOrderStatus> statuses,
  ) {
    final list = statuses.toList();
    if (list.isEmpty) return SalesAgreementSummaryStatus.idle;

    if (list.every((status) => status == SalesOrderStatus.cancelled)) {
      return SalesAgreementSummaryStatus.cancelled;
    }

    final nonCancelled =
        list.where((status) => status != SalesOrderStatus.cancelled);
    if (nonCancelled.isEmpty) return SalesAgreementSummaryStatus.cancelled;

    final terminal = nonCancelled.every(
      (status) =>
          status == SalesOrderStatus.paid ||
          status == SalesOrderStatus.closed ||
          status == SalesOrderStatus.delivered,
    );
    if (terminal) return SalesAgreementSummaryStatus.idle;

    if (nonCancelled.any(
      (status) =>
          status == SalesOrderStatus.ready ||
          status == SalesOrderStatus.partiallyDispatched,
    )) {
      return SalesAgreementSummaryStatus.pendingDelivery;
    }

    return SalesAgreementSummaryStatus.active;
  }
}

/// Schema versions on [salesAgreements] (Phase 0).
abstract final class SalesAgreementSchemaVersion {
  /// Pre-Agreement or incomplete link (dual-read).
  static const int legacy = 1;

  /// Child [salesOrders] under the Agreement are authoritative.
  static const int ordersAuthoritative = 2;
}

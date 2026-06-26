import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/formatters.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/job_work_invoice.dart';
import '../../domain/enums/notification_enums.dart';
import '../repositories/job_work_invoice_repository.dart';
import '../repositories/notification_repository.dart';

class PaymentDueScannerService {
  PaymentDueScannerService({
    required JobWorkInvoiceRepository invoiceRepository,
    required NotificationRepository notificationRepository,
    SharedPreferences? preferences,
  })  : _invoiceRepository = invoiceRepository,
        _notificationRepository = notificationRepository,
        _preferences = preferences;

  static const _prefKeyPrefix = 'payment_due_scan_';

  final JobWorkInvoiceRepository _invoiceRepository;
  final NotificationRepository _notificationRepository;
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<int> runIfNeeded(String factoryId) async {
    final prefs = await _prefs;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (prefs.getString('$_prefKeyPrefix$factoryId') == today) {
      return 0;
    }

    final created = await scan(factoryId);
    await prefs.setString('$_prefKeyPrefix$factoryId', today);
    return created;
  }

  Future<int> scan(String factoryId) async {
    final invoices = await _invoiceRepository.getOpenInvoicesForFactory(factoryId);
    var created = 0;

    for (final invoice in invoices) {
      final notification = _notificationForInvoice(invoice);
      if (notification == null) continue;

      final exists = await _notificationRepository.existsByDedupeKey(
        factoryId,
        notification.dedupeKey,
      );
      if (exists) continue;

      await _notificationRepository.createNotification(notification);
      created++;
    }

    return created;
  }

  PaymentDueSummary summarize(List<JobWorkInvoice> invoices) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = today.add(const Duration(days: 7));

    var dueThisWeekCount = 0;
    var dueThisWeekAmount = 0.0;
    var overdueCount = 0;
    var overdueAmount = 0.0;

    for (final invoice in invoices) {
      if (invoice.dueAmount <= 0) continue;
      final dueDate = invoice.dueDate;
      if (dueDate == null) continue;

      final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
      if (dueDay.isBefore(today)) {
        overdueCount++;
        overdueAmount += invoice.dueAmount;
      } else if (!dueDay.isAfter(weekEnd)) {
        dueThisWeekCount++;
        dueThisWeekAmount += invoice.dueAmount;
      }
    }

    return PaymentDueSummary(
      dueThisWeekCount: dueThisWeekCount,
      dueThisWeekAmount: dueThisWeekAmount,
      overdueCount: overdueCount,
      overdueAmount: overdueAmount,
    );
  }

  AppNotification? _notificationForInvoice(JobWorkInvoice invoice) {
    final dueDate = invoice.dueDate;
    if (dueDate == null || invoice.dueAmount <= 0) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final daysUntilDue = dueDay.difference(today).inDays;
    final scanDate = DateFormat('yyyy-MM-dd').format(today);
    final amountLabel = Formatters.currencyPkr(invoice.dueAmount);

    if (daysUntilDue == 7) {
      return _buildNotification(
        invoice: invoice,
        type: NotificationType.paymentDueIn7Days,
        priority: NotificationPriority.medium,
        title: 'Payment due in 7 days — ${invoice.customerName}',
        body: '${invoice.invoiceNumber}: $amountLabel due on ${DateFormat.yMMMd().format(dueDay)}',
        daysUntilDue: 7,
        dedupeKey: 'due_7_${invoice.id}_$scanDate',
      );
    }

    if (daysUntilDue == 3) {
      return _buildNotification(
        invoice: invoice,
        type: NotificationType.paymentDueIn3Days,
        priority: NotificationPriority.medium,
        title: 'Payment due in 3 days — ${invoice.customerName}',
        body: '${invoice.invoiceNumber}: $amountLabel due on ${DateFormat.yMMMd().format(dueDay)}',
        daysUntilDue: 3,
        dedupeKey: 'due_3_${invoice.id}_$scanDate',
      );
    }

    if (daysUntilDue == 1) {
      return _buildNotification(
        invoice: invoice,
        type: NotificationType.paymentDueTomorrow,
        priority: NotificationPriority.high,
        title: 'Payment due tomorrow — ${invoice.customerName}',
        body: '${invoice.invoiceNumber}: $amountLabel due tomorrow',
        daysUntilDue: 1,
        dedupeKey: 'due_1_${invoice.id}_$scanDate',
      );
    }

    if (daysUntilDue == 0) {
      return _buildNotification(
        invoice: invoice,
        type: NotificationType.paymentDueToday,
        priority: NotificationPriority.high,
        title: 'Payment due today — ${invoice.customerName}',
        body: '${invoice.invoiceNumber}: $amountLabel due today',
        daysUntilDue: 0,
        dedupeKey: 'due_0_${invoice.id}_$scanDate',
      );
    }

    if (daysUntilDue < 0) {
      final daysOverdue = -daysUntilDue;
      final priority = daysOverdue > 30
          ? NotificationPriority.critical
          : daysOverdue > 7
              ? NotificationPriority.critical
              : NotificationPriority.high;

      return _buildNotification(
        invoice: invoice,
        type: NotificationType.paymentOverdue,
        priority: priority,
        title: 'Overdue payment — ${invoice.customerName}',
        body:
            '${invoice.invoiceNumber}: $amountLabel overdue by $daysOverdue day${daysOverdue == 1 ? '' : 's'}',
        daysOverdue: daysOverdue,
        dedupeKey: 'overdue_${invoice.id}_$scanDate',
      );
    }

    return null;
  }

  AppNotification buildPartialPaymentNotification({
    required JobWorkInvoice invoice,
    required double amountPaid,
    required double remainingDue,
  }) {
    return AppNotification(
      id: '',
      factoryId: invoice.factoryId,
      type: NotificationType.partialPaymentReceived,
      priority: NotificationPriority.info,
      title: 'Partial payment — ${invoice.customerName}',
      body:
          '${invoice.invoiceNumber}: ${Formatters.currencyPkr(amountPaid)} received. ${Formatters.currencyPkr(remainingDue)} remaining.',
      customerId: invoice.customerId,
      invoiceId: invoice.id,
      jobWorkId: invoice.jobWorkId,
      invoiceNumber: invoice.invoiceNumber,
      amountDue: remainingDue,
      dueDate: invoice.dueDate,
      createdAt: DateTime.now(),
      dedupeKey: 'partial_${invoice.id}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  AppNotification _buildNotification({
    required JobWorkInvoice invoice,
    required NotificationType type,
    required NotificationPriority priority,
    required String title,
    required String body,
    int? daysUntilDue,
    int? daysOverdue,
    required String dedupeKey,
  }) {
    return AppNotification(
      id: '',
      factoryId: invoice.factoryId,
      type: type,
      priority: priority,
      title: title,
      body: body,
      customerId: invoice.customerId,
      invoiceId: invoice.id,
      jobWorkId: invoice.jobWorkId,
      invoiceNumber: invoice.invoiceNumber,
      amountDue: invoice.dueAmount,
      dueDate: invoice.dueDate,
      daysUntilDue: daysUntilDue,
      daysOverdue: daysOverdue,
      createdAt: DateTime.now(),
      dedupeKey: dedupeKey,
    );
  }
}

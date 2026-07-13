import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/formatters.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/job_work_invoice.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/enums/notification_enums.dart';
import '../../domain/enums/invoice_enums.dart';
import '../repositories/job_work_invoice_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/sales_invoice_repository.dart';

class PaymentDueScannerService {
  PaymentDueScannerService({
    required JobWorkInvoiceRepository jobWorkInvoiceRepository,
    required SalesInvoiceRepository salesInvoiceRepository,
    required NotificationRepository notificationRepository,
    SharedPreferences? preferences,
  })  : _jobWorkInvoiceRepository = jobWorkInvoiceRepository,
        _salesInvoiceRepository = salesInvoiceRepository,
        _notificationRepository = notificationRepository,
        _preferences = preferences;

  static const _prefKeyPrefix = 'payment_due_scan_';

  final JobWorkInvoiceRepository _jobWorkInvoiceRepository;
  final SalesInvoiceRepository _salesInvoiceRepository;
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
    final jobWorkInvoices =
        await _jobWorkInvoiceRepository.getOpenInvoicesForFactory(factoryId);
    final salesInvoices =
        await _salesInvoiceRepository.getOpenInvoicesForFactory(factoryId);
    var created = 0;

    for (final invoice in jobWorkInvoices) {
      created += await _createIfNeeded(_DueInvoiceRef.fromJobWork(invoice));
    }
    for (final invoice in salesInvoices) {
      created += await _createIfNeeded(_DueInvoiceRef.fromSales(invoice));
    }

    return created;
  }

  Future<int> _createIfNeeded(_DueInvoiceRef invoice) async {
    final notification = _notificationForInvoice(invoice);
    if (notification == null) return 0;

    final exists = await _notificationRepository.existsByDedupeKey(
      invoice.factoryId,
      notification.dedupeKey,
    );
    if (exists) return 0;

    await _notificationRepository.createNotification(notification);
    return 1;
  }

  PaymentDueSummary summarize(List<JobWorkInvoice> jobWorkInvoices) {
    return _summarizeRefs(
      jobWorkInvoices.map(_DueInvoiceRef.fromJobWork).toList(),
    );
  }

  PaymentDueSummary summarizeSales(List<SalesInvoice> salesInvoices) {
    return _summarizeRefs(
      salesInvoices.map(_DueInvoiceRef.fromSales).toList(),
    );
  }

  PaymentDueSummary summarizeAll({
    List<JobWorkInvoice> jobWorkInvoices = const [],
    List<SalesInvoice> salesInvoices = const [],
  }) {
    return _summarizeRefs([
      ...jobWorkInvoices.map(_DueInvoiceRef.fromJobWork),
      ...salesInvoices.map(_DueInvoiceRef.fromSales),
    ]);
  }

  PaymentDueSummary _summarizeRefs(List<_DueInvoiceRef> invoices) {
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

  AppNotification? _notificationForInvoice(_DueInvoiceRef invoice) {
    final dueDate = invoice.dueDate;
    if (dueDate == null || invoice.dueAmount <= 0) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final daysUntilDue = dueDay.difference(today).inDays;
    final scanDate = DateFormat('yyyy-MM-dd').format(today);
    final amountLabel = Formatters.currencyPkr(invoice.dueAmount);

    if (daysUntilDue == 15) {
      return _buildNotification(
        invoice: invoice,
        type: NotificationType.paymentDueIn15Days,
        priority: NotificationPriority.low,
        title: 'Payment due in 15 days — ${invoice.customerName}',
        body:
            '${invoice.displayLabel}: $amountLabel due on ${DateFormat.yMMMd().format(dueDay)}',
        daysUntilDue: 15,
        dedupeKey: 'due_15_${invoice.id}_$scanDate',
      );
    }

    if (daysUntilDue == 7) {
      return _buildNotification(
        invoice: invoice,
        type: NotificationType.paymentDueIn7Days,
        priority: NotificationPriority.medium,
        title: 'Payment due in 7 days — ${invoice.customerName}',
        body:
            '${invoice.displayLabel}: $amountLabel due on ${DateFormat.yMMMd().format(dueDay)}',
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
        body:
            '${invoice.displayLabel}: $amountLabel due on ${DateFormat.yMMMd().format(dueDay)}',
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
        body: '${invoice.displayLabel}: $amountLabel due tomorrow',
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
        body: '${invoice.displayLabel}: $amountLabel due today',
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
            '${invoice.displayLabel}: $amountLabel overdue by $daysOverdue day${daysOverdue == 1 ? '' : 's'}',
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
    return _buildPartialNotification(
      factoryId: invoice.factoryId,
      customerId: invoice.customerId,
      customerName: invoice.customerName,
      invoiceId: invoice.id,
      invoiceLabel: _jobWorkInvoiceLabel(invoice),
      dueDate: invoice.dueDate,
      amountPaid: amountPaid,
      remainingDue: remainingDue,
      jobWorkId: invoice.jobWorkId,
      invoiceType: InvoiceType.jobWork,
    );
  }

  AppNotification buildSalesPartialPaymentNotification({
    required SalesInvoice invoice,
    required double amountPaid,
    required double remainingDue,
  }) {
    return _buildPartialNotification(
      factoryId: invoice.factoryId,
      customerId: invoice.customerId,
      customerName: invoice.customerName,
      invoiceId: invoice.id,
      invoiceLabel: invoice.invoiceNumber,
      dueDate: invoice.dueDate,
      amountPaid: amountPaid,
      remainingDue: remainingDue,
      salesOrderId: invoice.salesOrderId,
      invoiceType: InvoiceType.sales,
    );
  }

  AppNotification _buildPartialNotification({
    required String factoryId,
    required String customerId,
    required String customerName,
    required String invoiceId,
    required String invoiceLabel,
    required DateTime? dueDate,
    required double amountPaid,
    required double remainingDue,
    String? jobWorkId,
    String? salesOrderId,
    InvoiceType? invoiceType,
  }) {
    return AppNotification(
      id: '',
      factoryId: factoryId,
      type: NotificationType.partialPaymentReceived,
      priority: NotificationPriority.info,
      title: 'Partial payment — $customerName',
      body:
          '$invoiceLabel: ${Formatters.currencyPkr(amountPaid)} received. ${Formatters.currencyPkr(remainingDue)} remaining.',
      customerId: customerId,
      invoiceId: invoiceId,
      invoiceType: invoiceType,
      jobWorkId: jobWorkId,
      salesOrderId: salesOrderId,
      invoiceNumber: invoiceLabel,
      amountDue: remainingDue,
      dueDate: dueDate,
      createdAt: DateTime.now(),
      dedupeKey: 'partial_${invoiceId}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  AppNotification _buildNotification({
    required _DueInvoiceRef invoice,
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
      invoiceType: invoice.invoiceType,
      jobWorkId: invoice.jobWorkId,
      salesOrderId: invoice.salesOrderId,
      invoiceNumber: invoice.invoiceNumber,
      amountDue: invoice.dueAmount,
      dueDate: invoice.dueDate,
      daysUntilDue: daysUntilDue,
      daysOverdue: daysOverdue,
      createdAt: DateTime.now(),
      dedupeKey: dedupeKey,
    );
  }

  static String _jobWorkInvoiceLabel(JobWorkInvoice invoice) {
    final refs = <String>[
      invoice.invoiceNumber,
      if (invoice.jobWorkNumber.isNotEmpty) invoice.jobWorkNumber,
      if (invoice.loadNumber != null && invoice.loadNumber!.trim().isNotEmpty)
        invoice.loadNumber!.trim(),
    ];
    return refs.join(' · ');
  }
}

class _DueInvoiceRef {
  const _DueInvoiceRef({
    required this.id,
    required this.factoryId,
    required this.customerId,
    required this.customerName,
    required this.invoiceNumber,
    required this.dueAmount,
    required this.dueDate,
    this.jobWorkId,
    this.jobWorkNumber,
    this.loadNumber,
    this.salesOrderId,
    required this.invoiceType,
  });

  final String id;
  final String factoryId;
  final String customerId;
  final String customerName;
  final String invoiceNumber;
  final double dueAmount;
  final DateTime? dueDate;
  final String? jobWorkId;
  final String? jobWorkNumber;
  final String? loadNumber;
  final String? salesOrderId;
  final InvoiceType invoiceType;

  String get displayLabel {
    final refs = <String>[
      invoiceNumber,
      if (jobWorkNumber != null && jobWorkNumber!.isNotEmpty) jobWorkNumber!,
      if (loadNumber != null && loadNumber!.trim().isNotEmpty)
        loadNumber!.trim(),
    ];
    return refs.join(' · ');
  }

  factory _DueInvoiceRef.fromJobWork(JobWorkInvoice invoice) {
    return _DueInvoiceRef(
      id: invoice.id,
      factoryId: invoice.factoryId,
      customerId: invoice.customerId,
      customerName: invoice.customerName,
      invoiceNumber: invoice.invoiceNumber,
      dueAmount: invoice.dueAmount,
      dueDate: invoice.dueDate,
      jobWorkId: invoice.jobWorkId,
      jobWorkNumber: invoice.jobWorkNumber,
      loadNumber: invoice.loadNumber,
      invoiceType: InvoiceType.jobWork,
    );
  }

  factory _DueInvoiceRef.fromSales(SalesInvoice invoice) {
    return _DueInvoiceRef(
      id: invoice.id,
      factoryId: invoice.factoryId,
      customerId: invoice.customerId,
      customerName: invoice.customerName,
      invoiceNumber: invoice.invoiceNumber,
      dueAmount: invoice.dueAmount,
      dueDate: invoice.dueDate,
      salesOrderId: invoice.salesOrderId,
      invoiceType: InvoiceType.sales,
    );
  }
}

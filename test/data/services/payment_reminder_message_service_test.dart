import 'package:factory_management/data/services/payment_reminder_message_service.dart';
import 'package:factory_management/domain/enums/invoice_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = PaymentReminderMessageService();

  test('builds due reminder with invoice details', () {
    final message = service.build(
      customerName: 'Ali Marble',
      invoiceNumber: 'SINV-2026-0001',
      amountDue: 50000,
      dueDate: DateTime(2026, 6, 30),
      invoiceType: InvoiceType.sales,
      factoryName: 'Test Factory',
    );

    expect(message, contains('Ali Marble'));
    expect(message, contains('SINV-2026-0001'));
    expect(message, contains('50,000'));
    expect(message, contains('Test Factory'));
  });

  test('builds overdue reminder wording', () {
    final message = service.build(
      customerName: 'Builder Co',
      invoiceNumber: 'JWI-2026-0002',
      amountDue: 12000,
      dueDate: DateTime(2026, 6, 1),
      invoiceType: InvoiceType.jobWork,
      isOverdue: true,
    );

    expect(message, contains('overdue'));
    expect(message, contains('JWI-2026-0002'));
  });
}

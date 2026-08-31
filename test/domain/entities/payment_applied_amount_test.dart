import 'package:factory_management/data/models/payment_model.dart';
import 'package:factory_management/domain/entities/payment.dart';
import 'package:factory_management/domain/enums/invoice_enums.dart';
import 'package:flutter_test/flutter_test.dart';

Payment _payment({
  required double amount,
  double? appliedAmount,
}) {
  return Payment(
    id: 'p1',
    factoryId: 'f1',
    customerId: 'c1',
    customerName: 'A',
    invoiceId: 'inv-1',
    invoiceType: InvoiceType.jobWork,
    invoiceNumber: 'INV-1',
    amount: amount,
    appliedAmount: appliedAmount,
    method: PaymentMethod.cash,
    paymentDate: DateTime(2026, 8, 31),
    createdAt: DateTime(2026, 8, 31),
  );
}

void main() {
  test('omitted appliedAmount equals cash amount (legacy rows)', () {
    final payment = _payment(amount: 300000);
    expect(payment.appliedAmount, 300000);
    expect(payment.unallocatedAmount, 0);
    expect(payment.isCreditApplication, isFalse);
  });

  test('overpay keeps leftover as unallocated credit', () {
    final payment = _payment(amount: 300000, appliedAmount: 200000);
    expect(payment.appliedAmount, 200000);
    expect(payment.unallocatedAmount, 100000);
    expect(payment.isCreditApplication, isFalse);
  });

  test('credit application is applied without cash', () {
    final payment = _payment(amount: 0, appliedAmount: 100000);
    expect(payment.isCreditApplication, isTrue);
    expect(payment.unallocatedAmount, 0);
    expect(Payment.unallocatedTotal([payment]), 0);
  });

  test('unallocatedTotal nets credit applications against leftover cash', () {
    final payments = [
      _payment(amount: 300000, appliedAmount: 200000),
      _payment(amount: 0, appliedAmount: 100000),
      _payment(amount: 50000, appliedAmount: 50000),
    ];
    expect(Payment.unallocatedTotal(payments), 0);
  });

  test('PaymentModel reads missing appliedAmount as amount', () {
    final model = PaymentModel.fromFirestore('p1', {
      'factoryId': 'f1',
      'customerId': 'c1',
      'customerName': 'A',
      'invoiceId': 'inv-1',
      'invoiceType': 'jobWork',
      'invoiceNumber': 'INV-1',
      'amount': 80,
      'method': 'cash',
    });
    expect(model.amount, 80);
    expect(model.appliedAmount, 80);
    expect(model.toEntity().unallocatedAmount, 0);
  });
}

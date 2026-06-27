import 'package:factory_management/core/constants/app_strings.dart';
import 'package:factory_management/data/services/export/customer_statement_excel_exporter.dart';
import 'package:factory_management/data/services/export/customer_statement_pdf_exporter.dart';
import 'package:factory_management/domain/entities/customer.dart';
import 'package:factory_management/domain/entities/customer_statement.dart';
import 'package:factory_management/domain/enums/customer_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final customer = Customer(
    id: 'cust-1',
    factoryId: 'factory-1',
    customerType: CustomerType.business,
    name: 'Test Customer',
    phone: '03001234567',
    serviceType: CustomerServiceType.both,
    category: CustomerCategory.builder,
    paymentTerms: PaymentTerms.days30,
    creditLimit: 100000,
    balance: 5000,
    openingBalance: 1000,
    createdAt: DateTime(2026, 1, 1),
  );

  final statement = CustomerStatement(
    customer: customer,
    fromDate: DateTime(2026, 1, 1),
    toDate: DateTime(2026, 1, 31),
    openingBalance: 1000,
    lines: const [],
    closingBalance: 1000,
  );

  test('customer statement excel encodes non-empty bytes', () {
    final bytes = CustomerStatementExcelExporter().build(statement);
    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(100));
  });

  test('customer statement pdf saves bytes', () async {
    final doc = await CustomerStatementPdfExporter().build(statement: statement);
    final bytes = await doc.save();
    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(100));
  });
}

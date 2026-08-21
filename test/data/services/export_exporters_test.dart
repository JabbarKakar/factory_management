import 'package:factory_management/data/services/export/customer_statement_excel_exporter.dart';
import 'package:factory_management/data/services/export/customer_statement_pdf_exporter.dart';
import 'package:factory_management/data/services/export/supplier_statement_excel_exporter.dart';
import 'package:factory_management/data/services/export/supplier_statement_pdf_exporter.dart';
import 'package:factory_management/data/services/export/invoice_excel_exporter.dart';
import 'package:factory_management/data/services/export/expense_summary_excel_exporter.dart';
import 'package:factory_management/data/services/export/expense_summary_pdf_exporter.dart';
import 'package:factory_management/data/services/export/job_work_collection_slip_pdf_exporter.dart';
import 'package:factory_management/data/services/expense_summary_service.dart';
import 'package:factory_management/domain/entities/expense.dart';
import 'package:factory_management/domain/entities/job_work_collection.dart';
import 'package:factory_management/domain/entities/job_work_invoice.dart';
import 'package:factory_management/domain/entities/sales_invoice.dart';
import 'package:factory_management/domain/entities/supplier.dart';
import 'package:factory_management/domain/entities/supplier_statement.dart';
import 'package:factory_management/domain/enums/expense_enums.dart';
import 'package:factory_management/domain/enums/job_work_collection_enums.dart';
import 'package:factory_management/domain/enums/invoice_enums.dart';
import 'package:factory_management/domain/entities/customer.dart';
import 'package:factory_management/domain/entities/customer_statement.dart';
import 'package:factory_management/domain/enums/customer_enums.dart';
import 'package:factory_management/domain/enums/supplier_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('invoice excel encodes non-empty bytes', () {
    final invoice = SalesInvoice(
      id: 'inv-1',
      invoiceNumber: 'SINV-2026-0001',
      factoryId: 'factory-1',
      salesOrderId: 'so-1',
      orderNumber: 'SO-2026-0001',
      customerId: 'cust-1',
      customerName: 'Test Customer',
      lineItems: const [
        InvoiceLineItem(description: 'Marble slab', amount: 50000),
      ],
      totalAmount: 50000,
      paidAmount: 20000,
      dueAmount: 30000,
      status: InvoiceStatus.partial,
      createdAt: DateTime(2026, 1, 15),
    );

    final bytes = InvoiceExcelExporter().buildSalesInvoice(
      invoice: invoice,
      payments: const [],
    );
    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(100));
  });

  test('expense summary exporters produce output', () async {
    final report = ExpenseSummaryService().build(
      year: 2026,
      month: 1,
      expenses: [
        Expense(
          id: 'exp-1',
          expenseNumber: 'EXP-2026-0001',
          factoryId: 'factory-1',
          expenseDate: DateTime(2026, 1, 10),
          category: ExpenseCategory.electricity,
          description: 'Electricity bill',
          amount: 15000,
          paymentMethod: PaymentMethod.cash,
          createdAt: DateTime(2026, 1, 10),
        ),
      ],
    );

    final excelBytes = ExpenseSummaryExcelExporter().build(report);
    expect(excelBytes, isNotEmpty);

    final doc = await ExpenseSummaryPdfExporter().build(report: report);
    final pdfBytes = await doc.save();
    expect(pdfBytes, isNotEmpty);
  });

  test('job work collection slip exporter produces pdf output with small and large stock summary', () async {
    final collection = JobWorkCollection(
      id: 'col-1',
      collectionNumber: 'JWC-2026-0001',
      factoryId: 'factory-1',
      jobWorkOrderId: 'jw-1',
      jobWorkNumber: 'JW-2026-0001',
      loadId: 'load-1',
      loadNumber: 'JWL-2026-0001',
      customerId: 'cust-1',
      customerName: 'Test Customer',
      collectedAt: DateTime(2026, 1, 20),
      status: JobWorkCollectionStatus.collected,
      lineItems: const [
        JobWorkCollectionLineItem(
          size: '4x24',
          pieces: 50,
          squareFeet: 33.33,
          isSmall: true,
        ),
        JobWorkCollectionLineItem(
          size: '12x24',
          pieces: 10,
          squareFeet: 20.00,
          isSmall: false,
        ),
      ],
      createdAt: DateTime(2026, 1, 20),
    );

    final exporter = JobWorkCollectionSlipPdfExporter();
    final bytes = await exporter.generateCollectionSlipPdf(
      collection: collection,
      smallStockRate: 75.0,
      largeStockRate: 85.0,
    );

    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(100));
  });

  test('supplier statement excel encodes non-empty bytes', () {
    final supplier = Supplier(
      id: 'sup-1',
      supplierNumber: 'SUP-2026-0001',
      factoryId: 'factory-1',
      name: 'Test Supplier',
      supplierType: SupplierType.marbleBlockSlab,
      phone: '03001234567',
      paymentTerms: PaymentTerms.days30,
      createdAt: DateTime(2026, 1, 1),
    );

    final supplierStatement = SupplierStatement(
      supplier: supplier,
      fromDate: DateTime(2026, 1, 1),
      toDate: DateTime(2026, 1, 31),
      openingBalance: 10000,
      lines: [
        SupplierStatementLine(
          date: DateTime(2026, 1, 10),
          description: 'Marble block purchase',
          reference: 'STK-IN-2026-0001',
          debit: 50000,
          credit: 0,
          quantity: 2,
          unit: 'Tons',
          unitPrice: 25000,
        ),
        SupplierStatementLine(
          date: DateTime(2026, 1, 20),
          description: 'Payment via Bank',
          reference: 'EXP-2026-0001',
          debit: 0,
          credit: 30000,
        ),
      ],
      closingBalance: 30000,
    );

    final bytes = SupplierStatementExcelExporter().build(supplierStatement);
    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(100));
  });

  test('supplier statement pdf saves bytes', () async {
    final supplier = Supplier(
      id: 'sup-1',
      supplierNumber: 'SUP-2026-0001',
      factoryId: 'factory-1',
      name: 'Test Supplier',
      supplierType: SupplierType.marbleBlockSlab,
      phone: '03001234567',
      paymentTerms: PaymentTerms.days30,
      createdAt: DateTime(2026, 1, 1),
    );

    final supplierStatement = SupplierStatement(
      supplier: supplier,
      fromDate: DateTime(2026, 1, 1),
      toDate: DateTime(2026, 1, 31),
      openingBalance: 10000,
      lines: [
        SupplierStatementLine(
          date: DateTime(2026, 1, 10),
          description: 'Marble block purchase',
          reference: 'STK-IN-2026-0001',
          debit: 50000,
          credit: 0,
          quantity: 2,
          unit: 'Tons',
          unitPrice: 25000,
        ),
      ],
      closingBalance: 60000,
    );

    final doc = await SupplierStatementPdfExporter().build(statement: supplierStatement);
    final bytes = await doc.save();
    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(100));
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/job_work_invoice.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/enums/invoice_enums.dart';
import '../../domain/enums/sales_enums.dart';
import '../models/sales_invoice_model.dart';
import 'invoice_exception.dart';
import 'sales_order_repository.dart';

class SalesInvoiceRepository {
  SalesInvoiceRepository({
    FirebaseFirestore? firestore,
    required SalesOrderRepository salesOrderRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _salesOrderRepository = salesOrderRepository;

  final FirebaseFirestore _firestore;
  final SalesOrderRepository _salesOrderRepository;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get collection => _collection;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('salesInvoices');

  Future<SalesInvoice?> getInvoice(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return SalesInvoiceModel.fromFirestore(doc.id, doc.data()!).toEntity();
  }

  Future<SalesInvoice?> getInvoiceBySalesOrderId({
    required String factoryId,
    required String salesOrderId,
  }) async {
    final snapshot = await _collection
        .where('factoryId', isEqualTo: factoryId)
        .where('salesOrderId', isEqualTo: salesOrderId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return SalesInvoiceModel.fromFirestore(doc.id, doc.data()).toEntity();
  }

  Future<List<SalesInvoice>> getInvoicesForCustomer({
    required String factoryId,
    required String customerId,
  }) async {
    final snapshot = await _collection
        .where('factoryId', isEqualTo: factoryId)
        .where('customerId', isEqualTo: customerId)
        .get();
    final invoices = snapshot.docs
        .map((doc) => SalesInvoiceModel.fromFirestore(doc.id, doc.data()))
        .map((model) => model.toEntity())
        .toList();
    invoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return invoices;
  }

  Stream<List<SalesInvoice>> watchInvoicesForCustomer({
    required String factoryId,
    required String customerId,
  }) {
    return _collection
        .where('factoryId', isEqualTo: factoryId)
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          final invoices = snapshot.docs
              .map((doc) =>
                  SalesInvoiceModel.fromFirestore(doc.id, doc.data()))
              .map((model) => model.toEntity())
              .toList();
          invoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return invoices;
        });
  }

  Future<List<SalesInvoice>> getOpenInvoicesForFactory(String factoryId) async {
    final snapshot =
        await _collection.where('factoryId', isEqualTo: factoryId).get();
    return snapshot.docs
        .map((doc) => SalesInvoiceModel.fromFirestore(doc.id, doc.data()))
        .map((model) => model.toEntity())
        .where((invoice) => invoice.dueAmount > 0)
        .toList();
  }

  Stream<List<SalesInvoice>> watchOpenInvoicesForFactory(String factoryId) {
    return _collection
        .where('factoryId', isEqualTo: factoryId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) =>
                  SalesInvoiceModel.fromFirestore(doc.id, doc.data()))
              .map((model) => model.toEntity())
              .where((invoice) => invoice.dueAmount > 0)
              .toList();
        });
  }

  Future<SalesInvoice> generateFromSalesOrder(String salesOrderId) async {
    final order = await _salesOrderRepository.getSalesOrder(salesOrderId);
    if (order == null) {
      throw StateError('Sales order not found.');
    }
    if (order.status != SalesOrderStatus.ready) {
      throw StateError('Invoice can only be generated for ready orders.');
    }
    if (order.invoiceId != null && order.invoiceId!.isNotEmpty) {
      final existing = await getInvoice(order.invoiceId!);
      if (existing != null) return existing;
    }

    final existingByOrder = await getInvoiceBySalesOrderId(
      factoryId: order.factoryId,
      salesOrderId: salesOrderId,
    );
    if (existingByOrder != null) return existingByOrder;

    final id = _uuid.v4();
    final invoiceNumber = await _generateInvoiceNumber(order.factoryId);
    final dueDate = order.paymentDueDate ??
        DateTime.now().add(const Duration(days: 7));

    final lineItems = _buildLineItems(order);
    final totalAmount = order.grandTotal;
    final paidAmount = order.advanceReceived;
    final dueAmount = order.balanceDue;

    final invoice = SalesInvoice(
      id: id,
      invoiceNumber: invoiceNumber,
      factoryId: order.factoryId,
      salesOrderId: order.id,
      orderNumber: order.orderNumber,
      customerId: order.customerId,
      customerName: order.customerName,
      lineItems: lineItems,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      dueAmount: dueAmount,
      dueDate: dueDate,
      status: InvoiceStatus.fromAmounts(
        dueAmount: dueAmount,
        paidAmount: paidAmount,
        totalAmount: totalAmount,
        dueDate: dueDate,
      ),
      createdAt: DateTime.now(),
    );

    final model = SalesInvoiceModel.fromEntity(invoice);
    final batch = _firestore.batch();
    final orderStatus = dueAmount <= 0
        ? SalesOrderStatus.paid
        : SalesOrderStatus.invoiced;

    batch.set(_collection.doc(id), model.toFirestore(isCreate: true));
    batch.update(_salesOrderRepository.salesOrderDoc(order.id), {
      'invoiceId': id,
      'status': orderStatus.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    final created = await getInvoice(id);
    return created ?? invoice;
  }

  Future<SalesInvoice> updateInvoiceDetails({
    required SalesInvoice existing,
    required List<InvoiceLineItem> lineItems,
    DateTime? dueDate,
  }) async {
    if (existing.status == InvoiceStatus.cancelled) {
      throw const InvoiceException('Cancelled invoices cannot be edited.');
    }

    final totalAmount =
        lineItems.fold<double>(0, (sum, item) => sum + item.amount);
    if (totalAmount + 0.01 < existing.paidAmount) {
      throw InvoiceException(
        'Invoice total cannot be less than amount already paid '
        '(${existing.paidAmount.toStringAsFixed(0)}).',
      );
    }

    final dueAmount =
        (totalAmount - existing.paidAmount).clamp(0, totalAmount).toDouble();
    final effectiveDueDate = dueDate ?? existing.dueDate;
    final status = InvoiceStatus.fromAmounts(
      dueAmount: dueAmount,
      paidAmount: existing.paidAmount,
      totalAmount: totalAmount,
      dueDate: effectiveDueDate,
    );

    final updated = existing.copyWith(
      lineItems: lineItems,
      totalAmount: totalAmount,
      dueAmount: dueAmount,
      dueDate: effectiveDueDate,
      status: status,
      updatedAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    batch.update(
      _collection.doc(existing.id),
      SalesInvoiceModel.fromEntity(updated).toFirestore(),
    );

    final order =
        await _salesOrderRepository.getSalesOrder(existing.salesOrderId);
    if (order != null) {
      final orderStatus = dueAmount <= 0 && totalAmount > 0
          ? SalesOrderStatus.paid
          : order.status == SalesOrderStatus.paid && dueAmount > 0
              ? SalesOrderStatus.invoiced
              : order.status;
      batch.update(_salesOrderRepository.salesOrderDoc(existing.salesOrderId), {
        'balanceDue': dueAmount,
        'status': orderStatus.firestoreValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    return await getInvoice(existing.id) ?? updated;
  }

  Future<void> deleteInvoicesForCustomer(String customerId) async {
    final snapshot =
        await _collection.where('customerId', isEqualTo: customerId).get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  List<InvoiceLineItem> _buildLineItems(SalesOrder order) {
    return order.lineItems
        .map(
          (item) => InvoiceLineItem(
            description:
                '${item.productType.label} — ${item.marbleVariety} · '
                '${item.totalPieces} pcs · '
                '${item.totalSquareFeet.toStringAsFixed(2)} sq. ft',
            amount: item.lineTotal,
          ),
        )
        .toList();
  }

  Future<String> _generateInvoiceNumber(String factoryId) async {
    final year = DateTime.now().year;
    final snapshot =
        await _collection.where('factoryId', isEqualTo: factoryId).get();
    final count = snapshot.docs.length + 1;
    return 'INV-$year-${count.toString().padLeft(4, '0')}';
  }
}

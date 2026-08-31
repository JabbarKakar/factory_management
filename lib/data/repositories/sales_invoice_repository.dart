import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/observability/tracked_firestore.dart';
import '../../core/utils/firestore_query_constraints.dart';
import '../../domain/entities/job_work_invoice.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/enums/document_sequence.dart';
import '../../domain/enums/invoice_enums.dart';
import '../../domain/enums/sales_agreement_enums.dart';
import '../../domain/enums/sales_enums.dart';
import '../models/sales_invoice_model.dart';
import '../models/payment_model.dart';
import '../services/sales_container_sync_helper.dart';
import '../services/sequence_number_service.dart';
import 'invoice_exception.dart';
import 'sales_agreement_repository.dart';
import 'sales_order_repository.dart';

class SalesInvoiceRepository {
  SalesInvoiceRepository({
    FirebaseFirestore? firestore,
    required SalesOrderRepository salesOrderRepository,
    SalesAgreementRepository? salesAgreementRepository,
    SequenceNumberService? sequenceNumberService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _salesOrderRepository = salesOrderRepository,
        _salesAgreementRepository = salesAgreementRepository ??
            SalesAgreementRepository(firestore: firestore),
        _sequenceNumberService =
            sequenceNumberService ?? SequenceNumberService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final SalesOrderRepository _salesOrderRepository;
  final SalesAgreementRepository _salesAgreementRepository;
  final SequenceNumberService _sequenceNumberService;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get collection => _collection;

  CollectionReference<Map<String, dynamic>> get _collection =>
      trackedCollection(_firestore, 'salesInvoices');

  Future<SalesInvoice?> getInvoice(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return SalesInvoiceModel.fromFirestore(doc.id, doc.data()!).toEntity();
  }

  Future<SalesInvoice?> getInvoiceBySalesOrderId({
    required String factoryId,
    required String salesOrderId,
  }) async {
    if (salesOrderId.trim().isEmpty) return null;
    final snapshot = await _collection
        .where('factoryId', isEqualTo: factoryId)
        .where('salesOrderId', isEqualTo: salesOrderId)
        .get();
    if (snapshot.docs.isEmpty) return null;

    final invoices = snapshot.docs
        .map((doc) => SalesInvoiceModel.fromFirestore(doc.id, doc.data()))
        .map((model) => model.toEntity())
        .toList();
    return SalesContainerSyncHelper.preferActiveSingleInvoice(invoices);
  }

  /// Live single-order invoice (skips cancelled when an active one exists).
  Stream<SalesInvoice?> watchInvoiceBySalesOrderId({
    required String factoryId,
    required String salesOrderId,
  }) {
    if (salesOrderId.trim().isEmpty) {
      return Stream<SalesInvoice?>.value(null);
    }
    return _collection
        .where('factoryId', isEqualTo: factoryId)
        .where('salesOrderId', isEqualTo: salesOrderId)
        .snapshots()
        .map((snapshot) {
      final invoices = snapshot.docs
          .map((doc) => SalesInvoiceModel.fromFirestore(doc.id, doc.data()))
          .map((model) => model.toEntity())
          .toList();
      return SalesContainerSyncHelper.preferActiveSingleInvoice(invoices);
    });
  }

  Future<List<SalesInvoice>> getInvoicesForAgreement({
    required String factoryId,
    required String agreementId,
  }) async {
    final snapshot = await _collection
        .where('factoryId', isEqualTo: factoryId)
        .where('agreementId', isEqualTo: agreementId)
        .get();
    final invoices = snapshot.docs
        .map((doc) => SalesInvoiceModel.fromFirestore(doc.id, doc.data()))
        .map((model) => model.toEntity())
        .toList();
    invoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return invoices;
  }

  Stream<List<SalesInvoice>> watchInvoicesForAgreement({
    required String factoryId,
    required String agreementId,
  }) {
    return _collection
        .where('factoryId', isEqualTo: factoryId)
        .where('agreementId', isEqualTo: agreementId)
        .snapshots()
        .map((snapshot) {
      final invoices = snapshot.docs
          .map((doc) => SalesInvoiceModel.fromFirestore(doc.id, doc.data()))
          .map((model) => model.toEntity())
          .toList();
      invoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return invoices;
    });
  }

  Future<SalesInvoice?> getGrandInvoiceForAgreement({
    required String factoryId,
    required String agreementId,
  }) async {
    final invoices = await getInvoicesForAgreement(
      factoryId: factoryId,
      agreementId: agreementId,
    );
    for (final invoice in invoices) {
      if (invoice.isGrandInvoice) return invoice;
    }
    return null;
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

  Stream<List<SalesInvoice>> watchInvoicesForFactory(
    String factoryId, {
    int? limit,
  }) {
    return constrainFactoryQuery(
      _collection.where('factoryId', isEqualTo: factoryId),
      limit: limit,
    ).snapshots().map((snapshot) {
          final invoices = snapshot.docs
              .map((doc) =>
                  SalesInvoiceModel.fromFirestore(doc.id, doc.data()))
              .map((model) => model.toEntity())
              .toList();
          invoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return invoices;
        });
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
    if (order.status != SalesOrderStatus.ready &&
        order.status != SalesOrderStatus.partiallyDispatched) {
      throw StateError(
        'Invoice can only be generated for ready or partially dispatched orders.',
      );
    }
    final agreementId = order.agreementId?.trim() ?? '';
    if (agreementId.isEmpty) {
      throw StateError(
        'Sales order must be linked to a Sales Agreement before invoicing.',
      );
    }
    if (order.invoiceId != null && order.invoiceId!.isNotEmpty) {
      final existing = await getInvoice(order.invoiceId!);
      if (existing != null &&
          !existing.isGrandInvoice &&
          existing.status != InvoiceStatus.cancelled) {
        return existing;
      }
    }

    final existingByOrder = await getInvoiceBySalesOrderId(
      factoryId: order.factoryId,
      salesOrderId: salesOrderId,
    );
    if (existingByOrder != null &&
        existingByOrder.status != InvoiceStatus.cancelled) {
      return existingByOrder;
    }

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
      agreementId: agreementId,
      agreementNumber: order.agreementNumber,
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

    await _salesAgreementRepository.syncAgreementContainer(agreementId);
    await syncGrandInvoice(
      factoryId: order.factoryId,
      agreementId: agreementId,
    );

    final created = await getInvoice(id);
    return created ?? invoice;
  }

  /// Creates or syncs the Agreement-level Grand Sales Invoice
  /// (`agreementId` set, empty `salesOrderId`).
  Future<SalesInvoice> generateGrandFromAgreement(String agreementId) async {
    final agreement =
        await _salesAgreementRepository.getAgreement(agreementId);
    if (agreement == null) {
      throw StateError('Sales agreement not found.');
    }
    if (agreement.summaryStatus ==
        SalesAgreementSummaryStatus.cancelled) {
      throw StateError('Cannot invoice a cancelled sales agreement.');
    }

    final existingGrand = await getGrandInvoiceForAgreement(
      factoryId: agreement.factoryId,
      agreementId: agreementId,
    );
    if (existingGrand != null) {
      final synced = await syncGrandInvoice(
        factoryId: agreement.factoryId,
        agreementId: agreementId,
      );
      return synced ?? existingGrand;
    }

    final orders = await _salesOrderRepository.getOrdersForAgreement(
      factoryId: agreement.factoryId,
      agreementId: agreementId,
    );
    final billable =
        SalesContainerSyncHelper.billableOrdersForGrandInvoice(orders);
    if (billable.isEmpty) {
      throw StateError(
        'No orders with charges are ready for a grand invoice.',
      );
    }

    final allInvoices = await getInvoicesForAgreement(
      factoryId: agreement.factoryId,
      agreementId: agreementId,
    );
    final paidAmount = await _recordedPaymentsTotalForInvoices(
      factoryId: agreement.factoryId,
      customerId: agreement.customerId,
      invoices: allInvoices,
      billableOrders: billable,
    );
    final totalAmount =
        billable.fold<double>(0, (total, order) => total + order.grandTotal);
    final dueAmount =
        (totalAmount - paidAmount).clamp(0, totalAmount).toDouble();
    final lineItems = buildLineItemsForGrandInvoice(
      orders: billable,
      invoices: allInvoices,
      totalPaid: paidAmount,
    );

    final id = _uuid.v4();
    final invoiceNumber = await _generateInvoiceNumber(agreement.factoryId);
    final dueDate = DateTime.now().add(const Duration(days: 7));

    final invoice = SalesInvoice(
      id: id,
      invoiceNumber: invoiceNumber,
      factoryId: agreement.factoryId,
      agreementId: agreement.id,
      agreementNumber: agreement.agreementNumber,
      salesOrderId: '',
      orderNumber: '',
      customerId: agreement.customerId,
      customerName: agreement.customerName,
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

    await _collection
        .doc(id)
        .set(SalesInvoiceModel.fromEntity(invoice).toFirestore(isCreate: true));

    await _salesAgreementRepository.syncAgreementContainer(agreementId);

    final created = await getInvoice(id);
    return created ?? invoice;
  }

  /// Recalculates Grand Invoice totals/line items from billable orders + payments.
  Future<SalesInvoice?> syncGrandInvoice({
    required String factoryId,
    required String agreementId,
  }) async {
    final grandInvoice = await getGrandInvoiceForAgreement(
      factoryId: factoryId,
      agreementId: agreementId,
    );
    if (grandInvoice == null) return null;

    final agreement =
        await _salesAgreementRepository.getAgreement(agreementId);
    if (agreement == null) return grandInvoice;

    final orders = await _salesOrderRepository.getOrdersForAgreement(
      factoryId: factoryId,
      agreementId: agreementId,
    );
    final billable =
        SalesContainerSyncHelper.billableOrdersForGrandInvoice(orders);
    final allInvoices = await getInvoicesForAgreement(
      factoryId: factoryId,
      agreementId: agreementId,
    );

    final newTotalAmount = billable.isNotEmpty
        ? billable.fold<double>(0, (total, order) {
            final fin = SalesContainerSyncHelper.financeForOrderOnGrand(
              order: order,
              invoices: allInvoices,
            );
            return total + fin.charges;
          })
        : (agreement.totalAmount ?? grandInvoice.totalAmount);

    final newPaidAmount = await _recordedPaymentsTotalForInvoices(
      factoryId: factoryId,
      customerId: agreement.customerId,
      invoices: allInvoices,
      billableOrders: billable,
    );

    final newDueAmount =
        (newTotalAmount - newPaidAmount).clamp(0, newTotalAmount).toDouble();
    final newStatus = InvoiceStatus.fromAmounts(
      dueAmount: newDueAmount,
      paidAmount: newPaidAmount,
      totalAmount: newTotalAmount,
      dueDate: grandInvoice.dueDate,
    );
    final newLineItems = buildLineItemsForGrandInvoice(
      orders: billable,
      invoices: allInvoices,
      totalPaid: newPaidAmount,
    );

    final totalUnchanged =
        (newTotalAmount - grandInvoice.totalAmount).abs() < 0.01;
    final paidUnchanged =
        (newPaidAmount - grandInvoice.paidAmount).abs() < 0.01;
    final dueUnchanged = (newDueAmount - grandInvoice.dueAmount).abs() < 0.01;
    final statusUnchanged = newStatus == grandInvoice.status;
    var itemsUnchanged =
        grandInvoice.lineItems.length == newLineItems.length;
    if (itemsUnchanged) {
      for (var i = 0; i < newLineItems.length; i++) {
        if (grandInvoice.lineItems[i].description !=
                newLineItems[i].description ||
            (grandInvoice.lineItems[i].amount - newLineItems[i].amount)
                    .abs() >
                0.01) {
          itemsUnchanged = false;
          break;
        }
      }
    }

    if (totalUnchanged &&
        paidUnchanged &&
        dueUnchanged &&
        statusUnchanged &&
        itemsUnchanged) {
      return grandInvoice;
    }

    await _collection.doc(grandInvoice.id).update({
      'total': newTotalAmount,
      'paid': newPaidAmount,
      'due': newDueAmount,
      'status': newStatus.firestoreValue,
      'items': newLineItems
          .map(
            (item) => {
              'description': item.description,
              'amount': item.amount,
            },
          )
          .toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return getInvoice(grandInvoice.id);
  }

  List<InvoiceLineItem> buildLineItemsForGrandInvoice({
    required List<SalesOrder> orders,
    List<SalesInvoice> invoices = const [],
    double totalPaid = 0.0,
  }) {
    final items = <InvoiceLineItem>[];
    for (final order in orders) {
      final fin = SalesContainerSyncHelper.financeForOrderOnGrand(
        order: order,
        invoices: invoices,
      );
      final label = order.orderNumber.isNotEmpty
          ? order.orderNumber
          : 'Order ${order.orderSequence ?? ''}';
      items.add(
        InvoiceLineItem(
          description:
              '$label · Total: Rs ${fin.charges.toStringAsFixed(0)} · '
              'Paid: Rs ${fin.paid.toStringAsFixed(0)} · '
              'Remaining: Rs ${fin.due.toStringAsFixed(0)}',
          amount: fin.charges,
        ),
      );
      for (final line in order.lineItems) {
        items.add(
          InvoiceLineItem(
            description:
                '  └ ${line.productType.label} — ${line.marbleVariety} · '
                '${line.totalPieces} pcs · '
                '${line.totalSquareFeet.toStringAsFixed(1)} sq. ft',
            amount: 0,
          ),
        );
      }
    }
    if (items.isEmpty && totalPaid > 0) {
      items.add(
        InvoiceLineItem(
          description: 'Sales Agreement charges',
          amount: totalPaid,
        ),
      );
    }
    return items;
  }

  Future<double> _recordedPaymentsTotalForInvoices({
    required String factoryId,
    required String customerId,
    required List<SalesInvoice> invoices,
    required List<SalesOrder> billableOrders,
  }) async {
    final invoiceIds = invoices.map((invoice) => invoice.id).toSet();
    final grandInvoiceIds = invoices
        .where((invoice) => invoice.isGrandInvoice)
        .map((invoice) => invoice.id)
        .toSet();
    if (invoiceIds.isNotEmpty) {
      final paymentsSnap = await _firestore
          .collection('payments')
          .where('factoryId', isEqualTo: factoryId)
          .where('customerId', isEqualTo: customerId)
          .get();
      final recorded = paymentsSnap.docs
          .where((doc) {
            final data = doc.data();
            final linkedInvoiceId = data['invoiceId'] as String? ?? '';
            if (!invoiceIds.contains(linkedInvoiceId)) return false;
            // Ignore phantom advances seeded on grand (rollup of real payments).
            if (grandInvoiceIds.contains(linkedInvoiceId) &&
                doc.id.startsWith('advance_sales_')) {
              return false;
            }
            return true;
          })
          .fold<double>(
            0,
            (total, doc) =>
                total + PaymentModel.appliedFromFirestore(doc.data()),
          );
      if (recorded > 0) return recorded;
    }

    return billableOrders.fold<double>(
      0,
      (total, order) {
        final fin = SalesContainerSyncHelper.financeForOrderOnGrand(
          order: order,
          invoices: invoices,
        );
        return total + fin.paid;
      },
    );
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
        lineItems.fold<double>(0, (total, item) => total + item.amount);
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

    final agreementId = existing.agreementId?.trim() ?? '';
    if (agreementId.isNotEmpty) {
      await syncGrandInvoice(
        factoryId: existing.factoryId,
        agreementId: agreementId,
      );
      await _salesAgreementRepository.syncAgreementContainer(agreementId);
    }

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

  Future<String> _generateInvoiceNumber(String factoryId) {
    return _sequenceNumberService.allocate(
      factoryId: factoryId,
      sequence: DocumentSequence.salesInvoice,
    );
  }
}

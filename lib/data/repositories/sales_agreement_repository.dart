import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/observability/tracked_firestore.dart';
import '../../domain/entities/sales_agreement.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/enums/document_sequence.dart';
import '../../domain/enums/sales_agreement_enums.dart';
import '../../domain/enums/sales_enums.dart';
import '../models/sales_agreement_model.dart';
import '../models/sales_invoice_model.dart';
import '../models/sales_order_model.dart';
import '../services/sales_container_sync_helper.dart';
import '../services/sequence_number_service.dart';

class SalesAgreementRepository {
  SalesAgreementRepository({
    FirebaseFirestore? firestore,
    SequenceNumberService? sequenceNumberService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _sequenceNumberService =
            sequenceNumberService ?? SequenceNumberService(firestore: firestore);

  final FirebaseFirestore _firestore;
  final SequenceNumberService _sequenceNumberService;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _agreements =>
      trackedCollection(_firestore, 'salesAgreements');

  CollectionReference<Map<String, dynamic>> get _orders =>
      trackedCollection(_firestore, 'salesOrders');

  CollectionReference<Map<String, dynamic>> get _invoices =>
      trackedCollection(_firestore, 'salesInvoices');

  DocumentReference<Map<String, dynamic>> agreementDoc(String id) =>
      _agreements.doc(id);

  Stream<List<SalesAgreement>> watchAgreements(String factoryId) {
    return _agreements
        .where('factoryId', isEqualTo: factoryId)
        .snapshots()
        .map((snapshot) {
      final agreements = snapshot.docs
          .map((doc) => SalesAgreementModel.fromFirestore(doc.id, doc.data()))
          .map((model) => model.toEntity())
          .toList();
      agreements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return agreements;
    });
  }

  Stream<SalesAgreement?> watchAgreement(String agreementId) {
    return _agreements.doc(agreementId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return SalesAgreementModel.fromFirestore(doc.id, doc.data()!).toEntity();
    });
  }

  Future<SalesAgreement?> getAgreement(String id) async {
    final doc = await _agreements.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return SalesAgreementModel.fromFirestore(doc.id, doc.data()!).toEntity();
  }

  Future<List<SalesAgreement>> getAgreements(String factoryId) async {
    final snapshot =
        await _agreements.where('factoryId', isEqualTo: factoryId).get();
    final agreements = snapshot.docs
        .map((doc) => SalesAgreementModel.fromFirestore(doc.id, doc.data()))
        .map((model) => model.toEntity())
        .toList();
    agreements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return agreements;
  }

  Future<SalesAgreement> createAgreement(SalesAgreement agreement) async {
    final id = agreement.id.isEmpty ? _uuid.v4() : agreement.id;
    final agreementNumber = agreement.agreementNumber.isEmpty
        ? await generateAgreementNumber(agreement.factoryId)
        : agreement.agreementNumber;

    final withIds = agreement.copyWith(
      id: id,
      agreementNumber: agreementNumber,
      schemaVersion: SalesAgreementSchemaVersion.ordersAuthoritative,
    );
    final model = SalesAgreementModel.fromEntity(withIds);
    await _agreements.doc(id).set(model.toFirestore(isCreate: true));
    return await getAgreement(id) ?? withIds;
  }

  Future<void> updateAgreement(SalesAgreement agreement) async {
    final model = SalesAgreementModel.fromEntity(agreement);
    await _agreements.doc(agreement.id).update(model.toFirestore());
  }

  /// Recomputes denormalized Agreement fields from child Orders / invoices.
  Future<SalesAgreement?> syncAgreementContainer(String agreementId) async {
    final agreement = await getAgreement(agreementId);
    if (agreement == null) return null;

    final ordersSnapshot = await _orders
        .where('factoryId', isEqualTo: agreement.factoryId)
        .where('agreementId', isEqualTo: agreementId)
        .get();
    final orders = ordersSnapshot.docs
        .map((doc) => SalesOrderModel.fromFirestore(doc.id, doc.data()))
        .map((model) => model.toEntity())
        .toList();

    final invoicesSnapshot = await _invoices
        .where('factoryId', isEqualTo: agreement.factoryId)
        .where('agreementId', isEqualTo: agreementId)
        .get();
    final invoices = invoicesSnapshot.docs
        .map((doc) => SalesInvoiceModel.fromFirestore(doc.id, doc.data()))
        .map((model) => model.toEntity())
        .toList();

    final rolled = SalesContainerSyncHelper.applyOrderRollup(
      agreement: agreement,
      orders: orders,
      invoices: invoices,
    );

    await _agreements.doc(agreementId).update({
      'summaryStatus': rolled.summaryStatus.firestoreValue,
      'schemaVersion': rolled.schemaVersion,
      'orderCount': rolled.orderCount,
      'activeOrderCount': rolled.activeOrderCount,
      'totalAmount': rolled.totalAmount,
      'paidAmount': rolled.paidAmount,
      'balanceDue': rolled.balanceDue,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return await getAgreement(agreementId) ?? rolled;
  }

  Future<int> nextOrderSequence({
    required String factoryId,
    required String agreementId,
  }) async {
    final snapshot = await _orders
        .where('factoryId', isEqualTo: factoryId)
        .where('agreementId', isEqualTo: agreementId)
        .get();
    var maxSequence = 0;
    for (final doc in snapshot.docs) {
      final sequence = (doc.data()['orderSequence'] as num?)?.toInt() ?? 0;
      if (sequence > maxSequence) maxSequence = sequence;
    }
    return maxSequence + 1;
  }

  Future<String> generateAgreementNumber(String factoryId) {
    return _sequenceNumberService.allocate(
      factoryId: factoryId,
      sequence: DocumentSequence.salesAgreement,
    );
  }

  /// Idempotent: link a legacy order to a 1:1 Agreement when missing.
  Future<SalesAgreement> ensureAgreementForOrder(SalesOrder order) async {
    final existingId = order.agreementId?.trim() ?? '';
    if (existingId.isNotEmpty) {
      final existing = await getAgreement(existingId);
      if (existing != null) return existing;
    }

    final agreement = await createAgreement(
      SalesAgreement(
        id: '',
        agreementNumber: '',
        factoryId: order.factoryId,
        customerId: order.customerId,
        customerName: order.customerName,
        summaryStatus: SalesAgreementSummaryStatus.fromOrderStatuses(
          [order.status],
        ),
        schemaVersion: SalesAgreementSchemaVersion.ordersAuthoritative,
        orderCount: 1,
        activeOrderCount: order.status == SalesOrderStatus.cancelled ? 0 : 1,
        totalAmount: order.grandTotal,
        paidAmount: order.advanceReceived,
        balanceDue: order.balanceDue,
        createdAt: order.createdAt,
      ),
    );

    await _orders.doc(order.id).update({
      'agreementId': agreement.id,
      'agreementNumber': agreement.agreementNumber,
      'orderSequence': 1,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _stampInvoicesForOrder(
      factoryId: order.factoryId,
      salesOrderId: order.id,
      agreementId: agreement.id,
      agreementNumber: agreement.agreementNumber,
    );

    return agreement;
  }

  Future<void> _stampInvoicesForOrder({
    required String factoryId,
    required String salesOrderId,
    required String agreementId,
    required String agreementNumber,
  }) async {
    final snapshot = await _invoices
        .where('factoryId', isEqualTo: factoryId)
        .where('salesOrderId', isEqualTo: salesOrderId)
        .get();

    if (snapshot.docs.isEmpty) return;

    const batchLimit = 400;
    for (var i = 0; i < snapshot.docs.length; i += batchLimit) {
      final batch = _firestore.batch();
      final chunk = snapshot.docs.skip(i).take(batchLimit);
      for (final doc in chunk) {
        final data = doc.data();
        final existingAgreementId =
            (data['agreementId'] as String?)?.trim() ?? '';
        if (existingAgreementId.isNotEmpty) continue;
        batch.update(doc.reference, {
          'agreementId': agreementId,
          'agreementNumber': agreementNumber,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }
}

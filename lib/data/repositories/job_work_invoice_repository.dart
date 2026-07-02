import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/job_work_invoice.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/enums/invoice_enums.dart';
import '../../domain/enums/job_work_enums.dart';
import '../models/job_work_invoice_model.dart';
import 'job_work_repository.dart';

class JobWorkInvoiceRepository {
  JobWorkInvoiceRepository({
    FirebaseFirestore? firestore,
    required JobWorkRepository jobWorkRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _jobWorkRepository = jobWorkRepository;

  final FirebaseFirestore _firestore;
  final JobWorkRepository _jobWorkRepository;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get collection => _collection;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('jobWorkInvoices');

  Future<JobWorkInvoice?> getInvoice(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return JobWorkInvoiceModel.fromFirestore(doc.id, doc.data()!).toEntity();
  }

  Future<JobWorkInvoice?> getInvoiceByJobWorkId(String jobWorkId) async {
    final snapshot =
        await _collection.where('jobWorkId', isEqualTo: jobWorkId).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return JobWorkInvoiceModel.fromFirestore(doc.id, doc.data()).toEntity();
  }

  Future<List<JobWorkInvoice>> getInvoicesForCustomer(String customerId) async {
    final snapshot =
        await _collection.where('customerId', isEqualTo: customerId).get();
    final invoices = snapshot.docs
        .map((doc) => JobWorkInvoiceModel.fromFirestore(doc.id, doc.data()))
        .map((model) => model.toEntity())
        .toList();
    invoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return invoices;
  }

  Stream<List<JobWorkInvoice>> watchInvoicesForCustomer(String customerId) {
    return _collection
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          final invoices = snapshot.docs
              .map((doc) =>
                  JobWorkInvoiceModel.fromFirestore(doc.id, doc.data()))
              .map((model) => model.toEntity())
              .toList();
          invoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return invoices;
        });
  }

  Future<List<JobWorkInvoice>> getOpenInvoicesForFactory(String factoryId) async {
    final snapshot =
        await _collection.where('factoryId', isEqualTo: factoryId).get();
    final invoices = snapshot.docs
        .map((doc) => JobWorkInvoiceModel.fromFirestore(doc.id, doc.data()))
        .map((model) => model.toEntity())
        .where((invoice) => invoice.dueAmount > 0)
        .toList();
    return invoices;
  }

  Stream<List<JobWorkInvoice>> watchOpenInvoicesForFactory(String factoryId) {
    return _collection
        .where('factoryId', isEqualTo: factoryId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) =>
                  JobWorkInvoiceModel.fromFirestore(doc.id, doc.data()))
              .map((model) => model.toEntity())
              .where((invoice) => invoice.dueAmount > 0)
              .toList();
        });
  }

  Future<JobWorkInvoice> generateFromJobWorkOrder(String jobWorkId) async {
    final order = await _jobWorkRepository.getJobWorkOrder(jobWorkId);
    if (order == null) {
      throw StateError('Job work order not found.');
    }
    if (order.status != JobWorkStatus.ready) {
      throw StateError('Invoice can only be generated for ready orders.');
    }
    if (order.finalCuttingCharges <= 0) {
      throw StateError(
        'Record output and finalize cutting charges before invoicing.',
      );
    }
    if (order.invoiceId != null && order.invoiceId!.isNotEmpty) {
      final existing = await getInvoice(order.invoiceId!);
      if (existing != null) return existing;
    }

    final existingByJob = await getInvoiceByJobWorkId(jobWorkId);
    if (existingByJob != null) return existingByJob;

    final id = _uuid.v4();
    final invoiceNumber = await _generateInvoiceNumber(order.factoryId);
    final dueDate = order.paymentDueDate ??
        DateTime.now().add(const Duration(days: 7));

    final lineItems = _buildLineItems(order);
    final totalAmount = order.finalCuttingCharges;
    final paidAmount = order.advanceReceived;
    final dueAmount = order.balanceDue;

    final invoice = JobWorkInvoice(
      id: id,
      invoiceNumber: invoiceNumber,
      factoryId: order.factoryId,
      jobWorkId: order.id,
      jobWorkNumber: order.jobWorkNumber,
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
      mineLocation: order.mineLocation,
      mineOwner: order.mineOwner,
      createdAt: DateTime.now(),
    );

    final model = JobWorkInvoiceModel.fromEntity(invoice);
    final batch = _firestore.batch();

    batch.set(_collection.doc(id), model.toFirestore(isCreate: true));
    final orderStatus = dueAmount <= 0
        ? JobWorkStatus.paid
        : JobWorkStatus.invoiced;
    batch.update(_jobWorkRepository.jobWorkDoc(order.id), {
      'invoiceId': id,
      'status': orderStatus.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    final created = await getInvoice(id);
    return created ?? invoice;
  }

  Future<void> updateInvoice(JobWorkInvoice invoice) async {
    final model = JobWorkInvoiceModel.fromEntity(invoice);
    await _collection.doc(invoice.id).update(model.toFirestore());
  }

  List<InvoiceLineItem> _buildLineItems(JobWorkOrder order) {
    final items = <InvoiceLineItem>[
      InvoiceLineItem(
        description: _cuttingFeeDescription(order),
        amount: order.finalCuttingCharges,
      ),
    ];

    final output = order.output;
    if (output != null && output.isRecorded) {
      items.add(
        InvoiceLineItem(
          description:
              'Output: ${output.totalUsableSqFt.toStringAsFixed(0)} sq. ft usable',
          amount: 0,
        ),
      );
    }

    return items;
  }

  String _cuttingFeeDescription(JobWorkOrder order) {
    final details = <String>['Cutting fee — ${order.marbleVariety}'];
    if (order.mineLocation != null && order.mineLocation!.isNotEmpty) {
      details.add(order.mineLocation!);
    }
    if (order.mineOwner != null && order.mineOwner!.isNotEmpty) {
      details.add(order.mineOwner!);
    }
    if (order.smallSizes.isNotEmpty && order.smallStockPrice > 0) {
      details.add(
        'Small ${order.smallSizes.length}× PKR ${order.smallStockPrice.toStringAsFixed(0)}',
      );
    }
    if (order.largeSizes.isNotEmpty && order.largeStockPrice > 0) {
      details.add(
        'Large ${order.largeSizes.length}× PKR ${order.largeStockPrice.toStringAsFixed(0)}',
      );
    }
    return details.join(' · ');
  }

  Future<String> _generateInvoiceNumber(String factoryId) async {
    final year = DateTime.now().year;
    final snapshot =
        await _collection.where('factoryId', isEqualTo: factoryId).get();
    final count = snapshot.docs.length + 1;
    return 'JWI-$year-${count.toString().padLeft(4, '0')}';
  }
}

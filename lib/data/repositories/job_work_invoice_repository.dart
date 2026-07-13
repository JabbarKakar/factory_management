import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/job_work_invoice.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/enums/invoice_enums.dart';
import '../../domain/enums/job_work_enums.dart';
import '../models/job_work_invoice_model.dart';
import '../services/job_work_container_sync_helper.dart';
import 'invoice_exception.dart';
import 'job_work_load_repository.dart';
import 'job_work_repository.dart';

class JobWorkInvoiceRepository {
  JobWorkInvoiceRepository({
    FirebaseFirestore? firestore,
    required JobWorkRepository jobWorkRepository,
    required JobWorkLoadRepository loadRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _jobWorkRepository = jobWorkRepository,
        _loadRepository = loadRepository;

  final FirebaseFirestore _firestore;
  final JobWorkRepository _jobWorkRepository;
  final JobWorkLoadRepository _loadRepository;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get collection => _collection;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('jobWorkInvoices');

  Future<JobWorkInvoice?> getInvoice(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return JobWorkInvoiceModel.fromFirestore(doc.id, doc.data()!).toEntity();
  }

  Future<JobWorkInvoice?> getInvoiceByJobWorkId({
    required String factoryId,
    required String jobWorkId,
  }) async {
    final snapshot = await _collection
        .where('factoryId', isEqualTo: factoryId)
        .where('jobWorkId', isEqualTo: jobWorkId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return JobWorkInvoiceModel.fromFirestore(doc.id, doc.data()).toEntity();
  }

  Stream<JobWorkInvoice?> watchInvoice(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return JobWorkInvoiceModel.fromFirestore(doc.id, doc.data()!).toEntity();
    });
  }

  Stream<JobWorkInvoice?> watchInvoiceByJobWorkId({
    required String factoryId,
    required String jobWorkId,
  }) {
    return _collection
        .where('factoryId', isEqualTo: factoryId)
        .where('jobWorkId', isEqualTo: jobWorkId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final doc = snapshot.docs.first;
          return JobWorkInvoiceModel.fromFirestore(doc.id, doc.data()).toEntity();
        });
  }

  Future<List<JobWorkInvoice>> getInvoicesForCustomer({
    required String factoryId,
    required String customerId,
  }) async {
    final snapshot = await _collection
        .where('factoryId', isEqualTo: factoryId)
        .where('customerId', isEqualTo: customerId)
        .get();
    final invoices = snapshot.docs
        .map((doc) => JobWorkInvoiceModel.fromFirestore(doc.id, doc.data()))
        .map((model) => model.toEntity())
        .toList();
    invoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return invoices;
  }

  Stream<List<JobWorkInvoice>> watchInvoicesForCustomer({
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

  Stream<List<JobWorkInvoice>> watchInvoicesForFactory(String factoryId) {
    return _collection
        .where('factoryId', isEqualTo: factoryId)
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

    final loads = await _loadRepository.fetchLoadsForJobWork(
      factoryId: order.factoryId,
      jobWorkId: jobWorkId,
    );

    if (order.invoiceId != null && order.invoiceId!.isNotEmpty) {
      final existing = await getInvoice(order.invoiceId!);
      if (existing != null) return existing;
    }

    final existingByJob = await getInvoiceByJobWorkId(
      factoryId: order.factoryId,
      jobWorkId: jobWorkId,
    );
    if (existingByJob != null) return existingByJob;

    if (!JobWorkContainerSyncHelper.canGenerateInvoice(
      order: order,
      loads: loads,
    )) {
      final charges = JobWorkContainerSyncHelper.rollupFinalCuttingCharges(
        order: order,
        loads: loads,
      );
      if (charges <= 0) {
        throw StateError(
          'Record output and finalize cutting charges before invoicing.',
        );
      }
      throw StateError(
        'Invoice can only be generated for ready or partially collected orders.',
      );
    }

    final id = _uuid.v4();
    final invoiceNumber = await _generateInvoiceNumber(order.factoryId);
    final dueDate = order.paymentDueDate ??
        DateTime.now().add(const Duration(days: 7));

    final lineItems = _buildLineItems(order, loads);
    final totalAmount = JobWorkContainerSyncHelper.rollupFinalCuttingCharges(
      order: order,
      loads: loads,
    );
    final paidAmount = JobWorkContainerSyncHelper.rollupAdvanceReceived(
      order: order,
      loads: loads,
    );
    final dueAmount =
        (totalAmount - paidAmount).clamp(0, double.infinity).toDouble();

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
    final orderUpdates = <String, dynamic>{
      'invoiceId': id,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    // Do not overwrite collection progress with invoiced/paid.
    if (!order.status.isCollectionStatus) {
      orderUpdates['status'] = (dueAmount <= 0
              ? JobWorkStatus.paid
              : JobWorkStatus.invoiced)
          .firestoreValue;
    }
    batch.update(_jobWorkRepository.jobWorkDoc(order.id), orderUpdates);

    await batch.commit();

    final created = await getInvoice(id);
    return created ?? invoice;
  }

  Future<JobWorkInvoice> updateInvoiceDetails({
    required JobWorkInvoice existing,
    required List<InvoiceLineItem> lineItems,
    DateTime? dueDate,
    String? mineLocation,
    String? mineOwner,
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

    final normalizedMineLocation = mineLocation?.trim();
    final normalizedMineOwner = mineOwner?.trim();

    final updated = existing.copyWith(
      lineItems: lineItems,
      totalAmount: totalAmount,
      dueAmount: dueAmount,
      dueDate: effectiveDueDate,
      mineLocation: normalizedMineLocation == null
          ? existing.mineLocation
          : normalizedMineLocation.isEmpty
              ? null
              : normalizedMineLocation,
      mineOwner: normalizedMineOwner == null
          ? existing.mineOwner
          : normalizedMineOwner.isEmpty
              ? null
              : normalizedMineOwner,
      status: status,
      updatedAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    batch.update(
      _collection.doc(existing.id),
      JobWorkInvoiceModel.fromEntity(updated).toFirestore(),
    );

    final order = await _jobWorkRepository.getJobWorkOrder(existing.jobWorkId);
    if (order != null) {
      final orderUpdates = <String, dynamic>{
        'finalCuttingCharges': totalAmount,
        'balanceDue': dueAmount,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (!order.status.isCollectionStatus) {
        final orderStatus = dueAmount <= 0 && totalAmount > 0
            ? JobWorkStatus.paid
            : order.status == JobWorkStatus.paid && dueAmount > 0
                ? JobWorkStatus.invoiced
                : order.status;
        orderUpdates['status'] = orderStatus.firestoreValue;
      }
      batch.update(
        _jobWorkRepository.jobWorkDoc(existing.jobWorkId),
        orderUpdates,
      );
    }

    await batch.commit();

    return await getInvoice(existing.id) ?? updated;
  }

  List<InvoiceLineItem> _buildLineItems(
    JobWorkOrder order,
    List<JobWorkLoad> loads,
  ) {
    final orderLoads =
        JobWorkContainerSyncHelper.persistedLoadsForOrder(order, loads);
    final items = <InvoiceLineItem>[];

    if (orderLoads.isEmpty) {
      items.add(
        InvoiceLineItem(
          description: _cuttingFeeDescription(order),
          amount: order.finalCuttingCharges,
        ),
      );
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

    for (final load in orderLoads) {
      if (load.finalCuttingCharges <= 0) continue;
      final label = load.loadNumber.isEmpty
          ? 'Load #${load.loadSequence}'
          : load.loadNumber;
      items.add(
        InvoiceLineItem(
          description: 'Cutting fee — $label · ${order.marbleVariety}',
          amount: load.finalCuttingCharges,
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        InvoiceLineItem(
          description: _cuttingFeeDescription(order),
          amount: JobWorkContainerSyncHelper.rollupFinalCuttingCharges(
            order: order,
            loads: loads,
          ),
        ),
      );
    }

    final usableSqFt = orderLoads.fold<double>(
      0,
      (total, load) => total + (load.output?.totalUsableSqFt ?? 0),
    );
    if (usableSqFt > 0) {
      items.add(
        InvoiceLineItem(
          description:
              'Output: ${usableSqFt.toStringAsFixed(0)} sq. ft usable',
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

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
    final invoices = await getInvoicesByJobWorkId(
      factoryId: factoryId,
      jobWorkId: jobWorkId,
    );
    final grandInvoices = invoices.where((i) => i.loadId == null || i.loadId!.isEmpty).toList();
    if (grandInvoices.isEmpty) return null;
    return grandInvoices.first;
  }

  Future<List<JobWorkInvoice>> getInvoicesByJobWorkId({
    required String factoryId,
    required String jobWorkId,
  }) async {
    final snapshot = await _collection
        .where('factoryId', isEqualTo: factoryId)
        .where('jobWorkId', isEqualTo: jobWorkId)
        .get();
    final invoices = snapshot.docs
        .map((doc) => JobWorkInvoiceModel.fromFirestore(doc.id, doc.data()))
        .map((model) => model.toEntity())
        .toList();
    invoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return invoices;
  }

  Future<JobWorkInvoice?> getInvoiceByLoadId({
    required String factoryId,
    required String loadId,
  }) async {
    final snapshot = await _collection
        .where('factoryId', isEqualTo: factoryId)
        .where('loadId', isEqualTo: loadId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return JobWorkInvoiceModel.fromFirestore(doc.id, doc.data()).toEntity();
  }

  /// Load-scoped invoice, with no fallback to Job Work level invoice.
  Future<JobWorkInvoice?> getInvoiceForLoad({
    required String factoryId,
    required String loadId,
  }) async {
    final load = await _loadRepository.getLoad(loadId);
    if (load == null) return null;

    final stampedId = load.invoiceId?.trim();
    if (stampedId != null && stampedId.isNotEmpty) {
      final invoice = await getInvoice(stampedId);
      if (invoice != null && invoice.loadId == loadId) {
        return invoice;
      }
    }

    return getInvoiceByLoadId(
      factoryId: factoryId,
      loadId: loadId,
    );
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
    return watchInvoicesByJobWorkId(
      factoryId: factoryId,
      jobWorkId: jobWorkId,
    ).map((invoices) {
      final grandInvoices = invoices.where((i) => i.loadId == null || i.loadId!.isEmpty).toList();
      return grandInvoices.isEmpty ? null : grandInvoices.first;
    });
  }

  Stream<List<JobWorkInvoice>> watchInvoicesByJobWorkId({
    required String factoryId,
    required String jobWorkId,
  }) {
    return _collection
        .where('factoryId', isEqualTo: factoryId)
        .where('jobWorkId', isEqualTo: jobWorkId)
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

  Stream<JobWorkInvoice?> watchInvoiceByLoadId({
    required String factoryId,
    required String loadId,
  }) {
    return _collection
        .where('factoryId', isEqualTo: factoryId)
        .where('loadId', isEqualTo: loadId)
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

  /// Generates or retrieves a single consolidated grand invoice for the entire Job Work order.
  Future<JobWorkInvoice> generateFromJobWorkOrder(String jobWorkId) async {
    final order = await _jobWorkRepository.getJobWorkOrder(jobWorkId);
    if (order == null) {
      throw StateError('Job work order not found.');
    }

    if (order.invoiceId != null && order.invoiceId!.isNotEmpty) {
      final existing = await getInvoice(order.invoiceId!);
      if (existing != null) return existing;
    }

    final existingByJobWork = await getInvoiceByJobWorkId(
      factoryId: order.factoryId,
      jobWorkId: order.id,
    );
    if (existingByJobWork != null) return existingByJobWork;

    final loads = await _loadRepository.fetchLoadsForJobWork(
      factoryId: order.factoryId,
      jobWorkId: jobWorkId,
    );
    final billable =
        JobWorkContainerSyncHelper.billableLoadsForGrandInvoice(loads);

    final double totalAmount;
    final double paidAmount;
    final List<InvoiceLineItem> lineItems;

    final existingInvoices = await getInvoicesByJobWorkId(
      factoryId: order.factoryId,
      jobWorkId: jobWorkId,
    );
    final invoiceIds = existingInvoices.map((i) => i.id).toSet();
    var recordedPaymentsTotal = 0.0;
    if (invoiceIds.isNotEmpty) {
      final paymentsSnap = await _firestore
          .collection('payments')
          .where('factoryId', isEqualTo: order.factoryId)
          .where('customerId', isEqualTo: order.customerId)
          .get();
      recordedPaymentsTotal = paymentsSnap.docs
          .map((doc) => doc.data())
          .where((data) => invoiceIds.contains(data['invoiceId']))
          .fold<double>(0, (sum, data) => sum + ((data['amount'] as num?)?.toDouble() ?? 0.0));
    }

    if (billable.isNotEmpty) {
      totalAmount = billable.fold<double>(0, (acc, load) => acc + load.finalCuttingCharges);
      paidAmount = recordedPaymentsTotal > 0
          ? recordedPaymentsTotal
          : billable.fold<double>(0, (acc, load) => acc + load.advanceReceived);
      lineItems = buildLineItemsForGrandInvoice(
        order: order,
        loads: billable,
        totalPaid: paidAmount,
      );
    } else {
      totalAmount = order.finalCuttingCharges;
      paidAmount = recordedPaymentsTotal > 0
          ? recordedPaymentsTotal
          : order.advanceReceived;
      lineItems = [
        InvoiceLineItem(
          description: 'Cutting fee — Job Work #${order.jobWorkNumber}',
          amount: totalAmount,
        ),
      ];
    }

    final dueAmount = (totalAmount - paidAmount).clamp(0, double.infinity).toDouble();
    final id = _uuid.v4();
    final invoiceNumber = await _generateInvoiceNumber(order.factoryId);
    final dueDate = order.paymentDueDate ?? DateTime.now().add(const Duration(days: 7));

    final invoice = JobWorkInvoice(
      id: id,
      invoiceNumber: invoiceNumber,
      factoryId: order.factoryId,
      jobWorkId: order.id,
      jobWorkNumber: order.jobWorkNumber,
      loadId: null,
      loadNumber: null,
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

    // Update Job Work Order with the invoiceId
    batch.update(
      _jobWorkRepository.jobWorkDoc(order.id),
      {
        'invoiceId': id,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    // Update all loads with the invoiceId
    for (final load in billable) {
      final loadUpdates = <String, dynamic>{
        'invoiceId': id,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final financeStatus = JobWorkContainerSyncHelper.financeStatusForLoad(
        load: load,
        dueAmount: load.balanceDue,
      );
      if (financeStatus != null) {
        loadUpdates['status'] = financeStatus.firestoreValue;
      }
      batch.update(_loadRepository.loadDoc(load.id), loadUpdates);
    }

    await batch.commit();
    await _loadRepository.refreshContainerFromLoads(order.id);

    final created = await getInvoice(id);
    return created ?? invoice;
  }

  Future<JobWorkInvoice> generateFromLoad(String loadId) async {
    final load = await _loadRepository.getLoad(loadId);
    if (load == null || load.isVirtual) {
      throw StateError('Load not found.');
    }

    final order = await _jobWorkRepository.getJobWorkOrder(load.jobWorkId);
    if (order == null) {
      throw StateError('Job work order not found.');
    }

    final existing = await getInvoiceByLoadId(
      factoryId: order.factoryId,
      loadId: load.id,
    );
    if (existing != null) return existing;

    final double totalAmount = load.finalCuttingCharges;
    final double paidAmount = load.advanceReceived;
    final dueAmount = (totalAmount - paidAmount).clamp(0, double.infinity).toDouble();

    final lineItems = [
      InvoiceLineItem(
        description: 'Cutting fee — Load ${load.loadNumber.isNotEmpty ? load.loadNumber : "#" + load.loadSequence.toString()}',
        amount: totalAmount,
      ),
    ];

    final id = _uuid.v4();
    final invoiceNumber = await _generateInvoiceNumber(order.factoryId);
    final dueDate = order.paymentDueDate ?? DateTime.now().add(const Duration(days: 7));

    final invoice = JobWorkInvoice(
      id: id,
      invoiceNumber: invoiceNumber,
      factoryId: order.factoryId,
      jobWorkId: order.id,
      jobWorkNumber: order.jobWorkNumber,
      loadId: load.id,
      loadNumber: load.loadNumber,
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
      mineLocation: load.mineLocation,
      mineOwner: load.mineOwner,
      createdAt: DateTime.now(),
    );

    final model = JobWorkInvoiceModel.fromEntity(invoice);
    final batch = _firestore.batch();
    batch.set(_collection.doc(id), model.toFirestore(isCreate: true));

    // Update the load doc with the invoiceId
    final loadUpdates = <String, dynamic>{
      'invoiceId': id,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final financeStatus = JobWorkContainerSyncHelper.financeStatusForLoad(
      load: load,
      dueAmount: dueAmount,
    );
    if (financeStatus != null) {
      loadUpdates['status'] = financeStatus.firestoreValue;
    }
    batch.update(_loadRepository.loadDoc(load.id), loadUpdates);

    await batch.commit();

    await _loadRepository.refreshContainerFromLoads(order.id);

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

    final loadId = existing.loadId;
    if (loadId != null && loadId.isNotEmpty) {
      final load = await _loadRepository.getLoad(loadId);
      if (load != null) {
        final loadUpdates = <String, dynamic>{
          'pricing.finalCuttingCharges': totalAmount,
          'pricing.balanceDue': dueAmount,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        final financeStatus = JobWorkContainerSyncHelper.financeStatusForLoad(
          load: load,
          dueAmount: dueAmount,
        );
        if (financeStatus != null) {
          loadUpdates['status'] = financeStatus.firestoreValue;
        }
        batch.update(_loadRepository.loadDoc(loadId), loadUpdates);
      }
    } else {
      final order =
          await _jobWorkRepository.getJobWorkOrder(existing.jobWorkId);
      if (order != null) {
        final orderUpdates = <String, dynamic>{
          'pricing.finalCuttingCharges': totalAmount,
          'pricing.balanceDue': dueAmount,
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
    }

    await batch.commit();
    if (loadId != null && loadId.isNotEmpty) {
      await _loadRepository.refreshContainerFromLoads(existing.jobWorkId);
    }

    return await getInvoice(existing.id) ?? updated;
  }



  List<InvoiceLineItem> buildLineItemsForGrandInvoice({
    required JobWorkOrder order,
    required List<JobWorkLoad> loads,
    List<JobWorkInvoice> invoices = const [],
    double totalPaid = 0.0,
  }) {
    final items = <InvoiceLineItem>[];
    final financeMap = JobWorkContainerSyncHelper.calculatePerLoadFinanceMap(
      order: order,
      loads: loads,
      invoices: invoices,
    );

    for (final load in loads) {
      final label = load.loadNumber.isEmpty
          ? 'Load #${load.loadSequence}'
          : load.loadNumber;
      final total = load.finalCuttingCharges;

      final fin = financeMap[load.id];
      final paid = fin?.paid ?? (totalPaid > 0 ? 0.0 : load.advanceReceived);
      final remaining = fin?.due ?? (totalPaid > 0 ? total : load.balanceDue);

      items.add(
        InvoiceLineItem(
          description:
              '$label · Total: Rs ${total.toStringAsFixed(0)} · Paid: Rs ${paid.toStringAsFixed(0)} · Remaining: Rs ${remaining.toStringAsFixed(0)}',
          amount: total,
        ),
      );

      final output = load.output;
      if (output != null && output.isRecorded) {
        items.add(
          InvoiceLineItem(
            description:
                '  └ Output: ${output.totalUsableSqFt.toStringAsFixed(0)} sq. ft usable',
            amount: 0,
          ),
        );
      }
    }
    return items;
  }

  Future<List<InvoiceLineItem>> rebuildGrandInvoiceLineItems({
    required String jobWorkId,
    required double totalPaid,
  }) async {
    final order = await _jobWorkRepository.getJobWorkOrder(jobWorkId);
    if (order == null) return const [];
    final loads = await _loadRepository.fetchLoadsForJobWork(
      factoryId: order.factoryId,
      jobWorkId: jobWorkId,
    );
    final billable =
        JobWorkContainerSyncHelper.billableLoadsForGrandInvoice(loads);
    final invoices = await getInvoicesByJobWorkId(
      factoryId: order.factoryId,
      jobWorkId: jobWorkId,
    );
    return buildLineItemsForGrandInvoice(
      order: order,
      loads: billable,
      invoices: invoices,
      totalPaid: totalPaid,
    );
  }

  /// Creates a single grand consolidated invoice for the Job Work order.
  /// Returns a list containing only the consolidated Job Work invoice.
  Future<List<JobWorkInvoice>> generateMissingInvoicesForJobWork(
    String jobWorkId,
  ) async {
    final order = await _jobWorkRepository.getJobWorkOrder(jobWorkId);
    if (order == null) {
      throw StateError('Job work order not found.');
    }

    final loads = await _loadRepository.fetchLoadsForJobWork(
      factoryId: order.factoryId,
      jobWorkId: jobWorkId,
    );
    final billable =
        JobWorkContainerSyncHelper.billableLoadsForGrandInvoice(loads);
    if (billable.isEmpty) {
      throw StateError(
        'No Loads with cutting charges are ready to invoice.',
      );
    }

    final invoice = await generateFromJobWorkOrder(jobWorkId);
    return [invoice];
  }

  /// Fully syncs a Grand Invoice for a Job Work order across all present and future loads & payments.
  Future<JobWorkInvoice?> syncGrandInvoice({
    required String factoryId,
    required String jobWorkId,
  }) async {
    final grandInvoice = await getInvoiceByJobWorkId(
      factoryId: factoryId,
      jobWorkId: jobWorkId,
    );
    if (grandInvoice == null) return null;

    final order = await _jobWorkRepository.getJobWorkOrder(jobWorkId);
    if (order == null) return grandInvoice;

    final loads = await _loadRepository.fetchLoadsForJobWork(
      factoryId: factoryId,
      jobWorkId: jobWorkId,
    );
    final billable =
        JobWorkContainerSyncHelper.billableLoadsForGrandInvoice(loads);

    final newTotalAmount = billable.isNotEmpty
        ? billable.fold<double>(0, (sum, load) => sum + load.finalCuttingCharges)
        : order.finalCuttingCharges;

    final allInvoices = await getInvoicesByJobWorkId(
      factoryId: factoryId,
      jobWorkId: jobWorkId,
    );
    final invoiceIds = allInvoices.map((i) => i.id).toSet();

    var recordedPaymentsTotal = 0.0;
    if (invoiceIds.isNotEmpty) {
      final paymentsSnap = await _firestore
          .collection('payments')
          .where('factoryId', isEqualTo: factoryId)
          .where('customerId', isEqualTo: order.customerId)
          .get();
      recordedPaymentsTotal = paymentsSnap.docs
          .map((doc) => doc.data())
          .where((data) => invoiceIds.contains(data['invoiceId']))
          .fold<double>(0, (sum, data) => sum + ((data['amount'] as num?)?.toDouble() ?? 0.0));
    }

    final newPaidAmount = recordedPaymentsTotal > 0
        ? recordedPaymentsTotal
        : billable.isNotEmpty
            ? billable.fold<double>(0, (sum, load) => sum + load.advanceReceived)
            : order.advanceReceived;

    final newDueAmount = (newTotalAmount - newPaidAmount)
        .clamp(0, newTotalAmount)
        .toDouble();
    final newStatus = InvoiceStatus.fromAmounts(
      dueAmount: newDueAmount,
      paidAmount: newPaidAmount,
      totalAmount: newTotalAmount,
      dueDate: grandInvoice.dueDate,
    );

    final newLineItems = buildLineItemsForGrandInvoice(
      order: order,
      loads: billable,
      invoices: allInvoices,
      totalPaid: newPaidAmount,
    );

    final totalUnchanged = (newTotalAmount - grandInvoice.totalAmount).abs() < 0.01;
    final paidUnchanged = (newPaidAmount - grandInvoice.paidAmount).abs() < 0.01;
    final dueUnchanged = (newDueAmount - grandInvoice.dueAmount).abs() < 0.01;
    final statusUnchanged = newStatus == grandInvoice.status;

    var itemsUnchanged = grandInvoice.lineItems.length == newLineItems.length;
    if (itemsUnchanged) {
      for (var i = 0; i < newLineItems.length; i++) {
        if (grandInvoice.lineItems[i].description != newLineItems[i].description ||
            (grandInvoice.lineItems[i].amount - newLineItems[i].amount).abs() > 0.01) {
          itemsUnchanged = false;
          break;
        }
      }
    }

    if (totalUnchanged && paidUnchanged && dueUnchanged && statusUnchanged && itemsUnchanged) {
      return grandInvoice;
    }

    final updates = <String, dynamic>{
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
    };

    await _collection.doc(grandInvoice.id).update(updates);
    return getInvoice(grandInvoice.id);
  }

  Future<void> updateInvoicePaidAndDue({
    required String invoiceId,
    required double paidAmount,
    required double dueAmount,
    required InvoiceStatus status,
    List<InvoiceLineItem>? lineItems,
  }) async {
    final updates = <String, dynamic>{
      'paid': paidAmount,
      'due': dueAmount,
      'status': status.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (lineItems != null) {
      updates['items'] = lineItems
          .map(
            (item) => {
              'description': item.description,
              'amount': item.amount,
            },
          )
          .toList();
    }
    await _collection.doc(invoiceId).update(updates);
  }

  Future<String> _generateInvoiceNumber(String factoryId) async {
    final year = DateTime.now().year;
    final snapshot =
        await _collection.where('factoryId', isEqualTo: factoryId).get();
    final count = snapshot.docs.length + 1;
    return 'JWI-$year-${count.toString().padLeft(4, '0')}';
  }
}

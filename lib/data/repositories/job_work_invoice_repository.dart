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
    if (invoices.isEmpty) return null;
    return invoices.first;
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

  /// Load-scoped invoice, with legacy fallback via [JobWorkLoad.invoiceId]
  /// when the invoice doc still has a null `loadId`.
  Future<JobWorkInvoice?> getInvoiceForLoad({
    required String factoryId,
    required String loadId,
  }) async {
    final byLoadId = await getInvoiceByLoadId(
      factoryId: factoryId,
      loadId: loadId,
    );
    if (byLoadId != null) return byLoadId;

    final load = await _loadRepository.getLoad(loadId);
    final stampedId = load?.invoiceId?.trim();
    if (stampedId == null || stampedId.isEmpty) return null;
    return getInvoice(stampedId);
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
    ).map((invoices) => invoices.isEmpty ? null : invoices.first);
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

  /// Prefer [generateFromLoad]. Kept only to open/migrate a single default Load
  /// invoice when a route still arrives without `loadId` (throws if multi-Load).
  Future<JobWorkInvoice> generateFromJobWorkOrder(String jobWorkId) async {
    final order = await _jobWorkRepository.getJobWorkOrder(jobWorkId);
    if (order == null) {
      throw StateError('Job work order not found.');
    }

    final loads = await _loadRepository.fetchLoadsForJobWork(
      factoryId: order.factoryId,
      jobWorkId: jobWorkId,
    );
    final persisted =
        JobWorkContainerSyncHelper.persistedLoadsForOrder(order, loads);

    if (persisted.length > 1) {
      throw StateError('Select a load before generating an invoice.');
    }

    final load = persisted.isEmpty
        ? await _loadRepository.ensureDefaultLoad(jobWorkId)
        : persisted.first;
    return generateFromLoad(load.id);
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

    if (load.invoiceId != null && load.invoiceId!.isNotEmpty) {
      final existing = await getInvoice(load.invoiceId!);
      if (existing != null) return existing;
    }

    final existingByLoad = await getInvoiceByLoadId(
      factoryId: load.factoryId,
      loadId: load.id,
    );
    if (existingByLoad != null) return existingByLoad;

    if (!JobWorkContainerSyncHelper.canGenerateInvoiceForLoad(load)) {
      if (load.status == JobWorkStatus.cancelled) {
        throw StateError('Cannot generate invoice for a cancelled load.');
      }
      throw StateError(
        'Record output and finalize cutting charges before invoicing.',
      );
    }

    final id = _uuid.v4();
    final invoiceNumber = await _generateInvoiceNumber(load.factoryId);
    final dueDate = load.paymentDueDate ??
        order.paymentDueDate ??
        DateTime.now().add(const Duration(days: 7));

    final totalAmount = load.finalCuttingCharges;
    final paidAmount = load.advanceReceived;
    final dueAmount =
        (totalAmount - paidAmount).clamp(0, double.infinity).toDouble();
    final lineItems = _buildLineItemsForLoad(order, load);

    final invoice = JobWorkInvoice(
      id: id,
      invoiceNumber: invoiceNumber,
      factoryId: load.factoryId,
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
      mineLocation: load.mineLocation ?? order.mineLocation,
      mineOwner: load.mineOwner ?? order.mineOwner,
      createdAt: DateTime.now(),
    );

    final model = JobWorkInvoiceModel.fromEntity(invoice);
    final batch = _firestore.batch();
    batch.set(_collection.doc(id), model.toFirestore(isCreate: true));

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

    // Container denorm (status / pricing rollups) comes from Load refresh only.
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

  List<InvoiceLineItem> _buildLineItemsForLoad(
    JobWorkOrder order,
    JobWorkLoad load,
  ) {
    final label = load.loadNumber.isEmpty
        ? 'Load #${load.loadSequence}'
        : load.loadNumber;
    final items = <InvoiceLineItem>[
      InvoiceLineItem(
        description: 'Cutting fee — $label · ${load.marbleVariety.isNotEmpty ? load.marbleVariety : order.marbleVariety}',
        amount: load.finalCuttingCharges,
      ),
    ];

    final output = load.output;
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

  /// Creates Load invoices for every billable Load that still needs one.
  /// Returns the invoices for all billable Loads (existing + newly created).
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

    final invoices = <JobWorkInvoice>[];
    for (final load in billable) {
      if (load.invoiceId != null && load.invoiceId!.isNotEmpty) {
        final existing = await getInvoice(load.invoiceId!);
        if (existing != null) {
          invoices.add(existing);
          continue;
        }
      }
      final byLoad = await getInvoiceByLoadId(
        factoryId: load.factoryId,
        loadId: load.id,
      );
      if (byLoad != null) {
        invoices.add(byLoad);
        continue;
      }
      if (!JobWorkContainerSyncHelper.canGenerateInvoiceForLoad(load)) {
        continue;
      }
      invoices.add(await generateFromLoad(load.id));
    }

    if (invoices.isEmpty) {
      throw StateError('Could not generate invoices for this Job Work.');
    }
    return invoices;
  }

  Future<String> _generateInvoiceNumber(String factoryId) async {
    final year = DateTime.now().year;
    final snapshot =
        await _collection.where('factoryId', isEqualTo: factoryId).get();
    final count = snapshot.docs.length + 1;
    return 'JWI-$year-${count.toString().padLeft(4, '0')}';
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/events/entity_reactive_event_bus.dart';
import '../../core/utils/firestore_paginator.dart';
import '../models/paginated_result.dart';
import '../../core/observability/tracked_firestore.dart';
import '../../core/utils/firestore_query_constraints.dart';
import '../../domain/entities/customer.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  CustomerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _collection =>
      trackedCollection(_firestore, 'customers');

  Future<PaginatedResult<Customer>> fetchCustomersPage({
    required String factoryId,
    DocumentSnapshot? startAfter,
    int limit = 20,
    String? categoryFilter,
  }) async {
    Query<Map<String, dynamic>> query =
        _collection.where('factoryId', isEqualTo: factoryId);

    if (categoryFilter != null &&
        categoryFilter.isNotEmpty &&
        categoryFilter != 'all') {
      query = query.where('category', isEqualTo: categoryFilter);
    }

    return FirestorePaginator.fetchPage<Customer>(
      query: query,
      orderByField: 'createdAt',
      descending: true,
      startAfter: startAfter,
      limit: limit,
      mapDoc: (id, data) => CustomerModel.fromFirestore(id, data).toEntity(),
    );
  }

  Stream<List<Customer>> watchCustomers(
    String factoryId, {
    int? limit,
  }) {
    return constrainFactoryQuery(
      _collection.where('factoryId', isEqualTo: factoryId),
      limit: limit,
    ).snapshots().map((snapshot) {
          final customers = snapshot.docs
              .map((doc) => CustomerModel.fromFirestore(doc.id, doc.data()))
              .map((model) => model.toEntity())
              .toList();
          customers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return customers;
        });
  }

  Future<Customer?> getCustomer(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return CustomerModel.fromFirestore(doc.id, doc.data()!).toEntity();
  }

  Stream<Customer?> watchCustomer(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return CustomerModel.fromFirestore(doc.id, doc.data()!).toEntity();
    });
  }

  Future<Customer> createCustomer(Customer customer) async {
    final id = customer.id.isEmpty ? _uuid.v4() : customer.id;
    final model = CustomerModel.fromEntity(
      customer.copyWith(
        id: id,
        balance: customer.openingBalance,
      ),
    );

    await _collection.doc(id).set(model.toFirestore(isCreate: true));
    final created = (await getCustomer(id)) ?? model.toEntity();
    EntityReactiveEventBus.instance.notifyCreated<Customer>(created);
    return created;
  }

  Future<void> updateCustomer(Customer customer) async {
    final model = CustomerModel.fromEntity(customer);
    await _collection.doc(customer.id).update(model.toFirestore());
    EntityReactiveEventBus.instance.notifyUpdated<Customer>(customer);
  }

  Future<void> deleteCustomer(String id) async {
    final existing = await getCustomer(id);
    await _collection.doc(id).delete();
    if (existing != null) {
      EntityReactiveEventBus.instance.notifyDeleted<Customer>(existing);
    }
  }

  /// Cascading removal of a customer and all linked records.
  ///
  /// Uses targeted `factoryId` + `customerId` queries so only the documents
  /// belonging specifically to this customer are fetched and batch-deleted,
  /// executing in milliseconds without scanning whole collections.
  Future<void> deleteCustomerCascade({
    required String customerId,
    String? factoryId,
  }) async {
    if (customerId.trim().isEmpty) return;

    final customer = await getCustomer(customerId);
    final fid = (factoryId != null && factoryId.isNotEmpty)
        ? factoryId
        : (customer?.factoryId ?? '');

    if (fid.isEmpty) {
      await deleteCustomer(customerId);
      return;
    }

    final toDelete = <DocumentReference<Map<String, dynamic>>>[];

    // 1. Fetch records linked directly to customerId
    final directResults = await Future.wait([
      _firestore
          .collection('jobWorkOrders')
          .where('factoryId', isEqualTo: fid)
          .where('customerId', isEqualTo: customerId)
          .get(),
      _firestore
          .collection('jobWorkCollections')
          .where('factoryId', isEqualTo: fid)
          .where('customerId', isEqualTo: customerId)
          .get(),
      _firestore
          .collection('jobWorkInvoices')
          .where('factoryId', isEqualTo: fid)
          .where('customerId', isEqualTo: customerId)
          .get(),
      _firestore
          .collection('salesOrders')
          .where('factoryId', isEqualTo: fid)
          .where('customerId', isEqualTo: customerId)
          .get(),
      _firestore
          .collection('salesInvoices')
          .where('factoryId', isEqualTo: fid)
          .where('customerId', isEqualTo: customerId)
          .get(),
      _firestore
          .collection('deliveries')
          .where('factoryId', isEqualTo: fid)
          .where('customerId', isEqualTo: customerId)
          .get(),
      _firestore
          .collection('payments')
          .where('factoryId', isEqualTo: fid)
          .where('customerId', isEqualTo: customerId)
          .get(),
      _firestore
          .collection('paymentReminders')
          .where('factoryId', isEqualTo: fid)
          .where('customerId', isEqualTo: customerId)
          .get(),
      _firestore
          .collection('salesAgreements')
          .where('factoryId', isEqualTo: fid)
          .where('customerId', isEqualTo: customerId)
          .get(),
    ]);

    final jwOrderDocs = directResults[0].docs;
    final jwCollDocs = directResults[1].docs;
    final jwInvDocs = directResults[2].docs;
    final salesOrderDocs = directResults[3].docs;
    final salesInvDocs = directResults[4].docs;
    final deliveryDocs = directResults[5].docs;
    final paymentDocs = directResults[6].docs;
    final reminderDocs = directResults[7].docs;
    final agreementDocs = directResults[8].docs;

    // Collect direct doc refs
    toDelete.addAll(jwOrderDocs.map((d) => d.reference));
    toDelete.addAll(jwCollDocs.map((d) => d.reference));
    toDelete.addAll(jwInvDocs.map((d) => d.reference));
    toDelete.addAll(salesOrderDocs.map((d) => d.reference));
    toDelete.addAll(salesInvDocs.map((d) => d.reference));
    toDelete.addAll(deliveryDocs.map((d) => d.reference));
    toDelete.addAll(paymentDocs.map((d) => d.reference));
    toDelete.addAll(reminderDocs.map((d) => d.reference));
    toDelete.addAll(agreementDocs.map((d) => d.reference));

    // 2. Fetch nested Job Work Loads and Quality Checks ONLY if customer had Job Work Orders
    final jwOrderIds = jwOrderDocs.map((d) => d.id).toList();
    if (jwOrderIds.isNotEmpty) {
      for (final jwId in jwOrderIds) {
        final loadSnap = await _firestore
            .collection('jobWorkLoads')
            .where('factoryId', isEqualTo: fid)
            .where('jobWorkId', isEqualTo: jwId)
            .get();

        for (final loadDoc in loadSnap.docs) {
          toDelete.add(loadDoc.reference);
          final qcSnap = await _firestore
              .collection('qualityChecks')
              .where('factoryId', isEqualTo: fid)
              .where('referenceId', isEqualTo: loadDoc.id)
              .get();
          toDelete.addAll(qcSnap.docs.map((d) => d.reference));
        }

        final orderQcSnap = await _firestore
            .collection('qualityChecks')
            .where('factoryId', isEqualTo: fid)
            .where('referenceId', isEqualTo: jwId)
            .get();
        toDelete.addAll(orderQcSnap.docs.map((d) => d.reference));
      }
    }

    // 3. Batch-delete all linked documents (if any)
    if (toDelete.isNotEmpty) {
      const batchLimit = 400;
      for (var i = 0; i < toDelete.length; i += batchLimit) {
        final batch = _firestore.batch();
        final chunk = toDelete.skip(i).take(batchLimit);
        for (final ref in chunk) {
          batch.delete(ref);
        }
        await batch.commit();
      }
    }

    // 4. Delete the customer document itself
    await deleteCustomer(customerId);
  }

}

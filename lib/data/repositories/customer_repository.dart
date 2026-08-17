import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/events/entity_reactive_event_bus.dart';
import '../../core/utils/firestore_paginator.dart';
import '../models/paginated_result.dart';
import '../../domain/entities/customer.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  CustomerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('customers');

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

  Stream<List<Customer>> watchCustomers(String factoryId) {
    return _collection
        .where('factoryId', isEqualTo: factoryId)
        .snapshots()
        .map((snapshot) {
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

  /// Cascading removal of a customer and all linked records across collections
  /// using safe single-field queries (no composite index requirements).
  Future<void> deleteCustomerCascade({
    required String customerId,
    String? factoryId,
  }) async {
    if (customerId.trim().isEmpty) return;

    // 1. Delete Sales Invoices & Sales Orders
    await _deleteCollectionByField('salesInvoices', 'customerId', customerId);
    await _deleteCollectionByField('salesOrders', 'customerId', customerId);

    // 2. Delete Job Work Orders & their nested entities
    try {
      final jwSnap = await _firestore
          .collection('jobWorkOrders')
          .where('customerId', isEqualTo: customerId)
          .get();

      for (final doc in jwSnap.docs) {
        await _deleteJobWorkOrderNested(doc.id);
        try {
          await doc.reference.delete();
        } catch (e) {
          debugPrint('Error deleting jobWorkOrder doc ${doc.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error querying jobWorkOrders for customer $customerId: $e');
    }

    // 3. Delete Job Work Collections, Invoices, Loads
    await _deleteCollectionByField('jobWorkCollections', 'customerId', customerId);
    await _deleteCollectionByField('jobWorkInvoices', 'customerId', customerId);
    await _deleteCollectionByField('jobWorkLoads', 'customerId', customerId);

    // 4. Delete Deliveries, Payments, Reminders, Agreements
    await _deleteCollectionByField('deliveries', 'customerId', customerId);
    await _deleteCollectionByField('payments', 'customerId', customerId);
    await _deleteCollectionByField('paymentReminders', 'customerId', customerId);
    await _deleteCollectionByField('salesAgreements', 'customerId', customerId);

    // 5. Delete Customer document itself
    await deleteCustomer(customerId);
  }

  Future<void> _deleteCollectionByField(
    String collectionName,
    String fieldName,
    String value,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .where(fieldName, isEqualTo: value)
          .get();

      if (snapshot.docs.isEmpty) return;

      const batchLimit = 400;
      final docs = snapshot.docs;
      for (var i = 0; i < docs.length; i += batchLimit) {
        final batch = _firestore.batch();
        final chunk = docs.skip(i).take(batchLimit);
        for (final doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error deleting $collectionName for $fieldName=$value: $e');
    }
  }

  Future<void> _deleteJobWorkOrderNested(String jobWorkId) async {
    try {
      final loadSnap = await _firestore
          .collection('jobWorkLoads')
          .where('jobWorkId', isEqualTo: jobWorkId)
          .get();

      for (final loadDoc in loadSnap.docs) {
        await _deleteCollectionByField('qualityChecks', 'referenceId', loadDoc.id);
        try {
          await loadDoc.reference.delete();
        } catch (e) {
          debugPrint('Error deleting loadDoc ${loadDoc.id}: $e');
        }
      }

      await _deleteCollectionByField('qualityChecks', 'referenceId', jobWorkId);
      await _deleteCollectionByField('jobWorkCollections', 'jobWorkOrderId', jobWorkId);

      final invSnap = await _firestore
          .collection('jobWorkInvoices')
          .where('jobWorkId', isEqualTo: jobWorkId)
          .get();

      for (final invDoc in invSnap.docs) {
        await _deleteCollectionByField('payments', 'invoiceId', invDoc.id);
        try {
          await invDoc.reference.delete();
        } catch (e) {
          debugPrint('Error deleting invDoc ${invDoc.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up nested job work order $jobWorkId: $e');
    }
  }
}

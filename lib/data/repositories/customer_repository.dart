import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/customer.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  CustomerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('customers');

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
    final created = await getCustomer(id);
    return created ?? model.toEntity();
  }

  Future<void> updateCustomer(Customer customer) async {
    final model = CustomerModel.fromEntity(customer);
    await _collection.doc(customer.id).update(model.toFirestore());
  }

  Future<void> deleteCustomer(String id) async {
    await _collection.doc(id).delete();
  }
}

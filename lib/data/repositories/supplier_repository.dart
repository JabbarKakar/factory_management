import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/supplier.dart';
import '../models/supplier_model.dart';

class SupplierRepository {
  SupplierRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get collection =>
      _firestore.collection('suppliers');

  Stream<List<Supplier>> watchSuppliers(String factoryId) {
    return collection.where('factoryId', isEqualTo: factoryId).snapshots().map(
      (snapshot) {
        final suppliers = snapshot.docs
            .map((doc) => SupplierModel.fromFirestore(doc.id, doc.data()))
            .map((model) => model.toEntity())
            .toList();
        suppliers.sort((a, b) => a.name.compareTo(b.name));
        return suppliers;
      },
    );
  }

  Stream<Supplier?> watchSupplier(String id) {
    return collection.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return SupplierModel.fromFirestore(doc.id, doc.data()!).toEntity();
    });
  }

  Future<Supplier?> getSupplier(String id) async {
    final doc = await collection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return SupplierModel.fromFirestore(doc.id, doc.data()!).toEntity();
  }

  Future<Supplier> createSupplier(Supplier supplier) async {
    final id = supplier.id.isEmpty ? _uuid.v4() : supplier.id;
    final supplierNumber = supplier.supplierNumber.isEmpty
        ? await _generateSupplierNumber(supplier.factoryId)
        : supplier.supplierNumber;

    final model = SupplierModel.fromEntity(
      supplier.copyWith(id: id, supplierNumber: supplierNumber),
    );

    await collection.doc(id).set(model.toFirestore(isCreate: true));
    final created = await getSupplier(id);
    return created ?? model.toEntity();
  }

  Future<void> updateSupplier(Supplier supplier) async {
    final model = SupplierModel.fromEntity(supplier);
    await collection.doc(supplier.id).update(model.toFirestore());
  }

  Future<void> deleteSupplier(String id) async {
    await collection.doc(id).delete();
  }

  Future<String> _generateSupplierNumber(String factoryId) async {
    final year = DateTime.now().year;
    final snapshot =
        await collection.where('factoryId', isEqualTo: factoryId).get();
    final count = snapshot.docs.length + 1;
    return 'SUP-$year-${count.toString().padLeft(4, '0')}';
  }
}

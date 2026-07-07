import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/factory_profile.dart';
import '../../domain/enums/factory_enums.dart';
import '../models/factory_model.dart';

class FactoryRepository {
  FactoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('factories');

  Future<FactoryProfile?> getFactory(String factoryId) async {
    final doc = await _collection.doc(factoryId).get();
    if (!doc.exists || doc.data() == null) return null;
    return FactoryModel.fromFirestore(doc.id, doc.data()!).toEntity();
  }

  Stream<FactoryProfile?> watchFactory(String factoryId) {
    return _collection.doc(factoryId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return FactoryModel.fromFirestore(doc.id, doc.data()!).toEntity();
    });
  }

  Future<FactoryProfile> createFactory({
    required String name,
    required String ownerUserId,
    String? ownerName,
    String? phone,
    String? address,
  }) async {
    final docRef = _collection.doc();
    final profile = FactoryProfile(
      id: docRef.id,
      name: name.trim(),
      ownerUserId: ownerUserId,
      ownerName: ownerName?.trim(),
      phone: phone?.trim(),
      address: address?.trim(),
      status: FactoryStatus.active,
    );
    final model = FactoryModel.fromEntity(profile);
    await docRef.set(model.toFirestore(isCreate: true));
    return profile;
  }

  Future<void> updateFactory(FactoryProfile profile) async {
    final model = FactoryModel.fromEntity(profile);
    await _collection.doc(profile.id).update(model.toFirestore());
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/factory_profile.dart';
import '../models/factory_model.dart';

class FactoryRepository {
  FactoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<FactoryProfile?> getFactory(String factoryId) async {
    final doc = await _firestore.collection('factories').doc(factoryId).get();
    if (!doc.exists || doc.data() == null) return null;
    return FactoryModel.fromFirestore(doc.id, doc.data()!).toEntity();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/enums/factory_role_enums.dart';
import '../models/user_model.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users');

  Stream<List<AppUser>> watchFactoryUsers(String factoryId) {
    return _collection
        .where('factoryId', isEqualTo: factoryId)
        .snapshots()
        .map((snapshot) {
          final users = snapshot.docs
              .map(
                (doc) => UserModel.fromFirestore(doc.id, doc.data()).toEntity(),
              )
              .toList();
          users.sort((a, b) => a.name.compareTo(b.name));
          return users;
        });
  }

  Future<void> updateUserRole({
    required String userId,
    required FactoryRole role,
  }) async {
    await _collection.doc(userId).update({
      'role': role.firestoreValue,
    });
  }
}

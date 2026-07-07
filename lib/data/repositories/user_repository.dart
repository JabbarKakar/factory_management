import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/enums/factory_role_enums.dart';
import '../../domain/enums/user_enums.dart';
import '../models/user_model.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users');

  Stream<AppUser?> watchUser(String userId, {String? authPhotoUrl}) {
    return _collection.doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromFirestore(
        doc.id,
        doc.data()!,
        authPhotoUrl: authPhotoUrl,
      ).toEntity();
    });
  }

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
    final updates = <String, dynamic>{
      'role': role.firestoreValue,
    };
    if (role != FactoryRole.driver) {
      updates['employeeId'] = FieldValue.delete();
    }
    await _collection.doc(userId).update(updates);
  }

  Future<void> updateUserEmployeeLink({
    required String userId,
    String? employeeId,
  }) async {
    if (employeeId == null || employeeId.isEmpty) {
      await _collection.doc(userId).update({
        'employeeId': FieldValue.delete(),
      });
      return;
    }

    await _collection.doc(userId).update({
      'employeeId': employeeId,
    });
  }

  Future<void> setUserStatus({
    required String userId,
    required UserAccountStatus status,
  }) async {
    await _collection.doc(userId).update({
      'status': status.firestoreValue,
    });
  }

  /// Owner blocks a member's access without deleting their history (S35).
  Future<void> disableUser(String userId) =>
      setUserStatus(userId: userId, status: UserAccountStatus.disabled);

  /// Owner restores a previously disabled member (S35).
  Future<void> enableUser(String userId) =>
      setUserStatus(userId: userId, status: UserAccountStatus.active);
}

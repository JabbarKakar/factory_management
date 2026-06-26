import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/app_notification.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('notifications');

  Stream<List<AppNotification>> watchNotifications(String factoryId) {
    return _collection
        .where('factoryId', isEqualTo: factoryId)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) =>
                  NotificationModel.fromFirestore(doc.id, doc.data()).toEntity())
              .toList();
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notifications;
        });
  }

  Future<bool> existsByDedupeKey(String factoryId, String dedupeKey) async {
    final snapshot = await _collection
        .where('factoryId', isEqualTo: factoryId)
        .where('dedupeKey', isEqualTo: dedupeKey)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> createNotification(AppNotification notification) async {
    final exists = await existsByDedupeKey(
      notification.factoryId,
      notification.dedupeKey,
    );
    if (exists) return;

    final id = notification.id.isEmpty ? _uuid.v4() : notification.id;
    final model = NotificationModel.fromEntity(notification.copyWith(id: id));
    await _collection.doc(id).set(model.toFirestore(isCreate: true));
  }

  Future<void> markAsRead(String notificationId, String userId) async {
    await _collection.doc(notificationId).update({
      'readBy': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> markAllAsRead(String factoryId, String userId) async {
    final snapshot =
        await _collection.where('factoryId', isEqualTo: factoryId).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      final readBy = (doc.data()['readBy'] as List?)?.whereType<String>() ?? [];
      if (readBy.contains(userId)) continue;
      batch.update(doc.reference, {
        'readBy': FieldValue.arrayUnion([userId]),
      });
    }
    await batch.commit();
  }
}

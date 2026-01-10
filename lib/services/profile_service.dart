import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save User Profile
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _firestore.collection('users').doc(profile.uid).set(profile.toMap());
    } catch (e) {
      debugPrint('Error saving profile: $e');
      rethrow;
    }
  }

  // Get User Profile
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting profile: $e');
      rethrow;
    }
  }

  // Check if User has a Factory
  // Assuming 'factories' collection where a document exists with ownerId == uid
  // Or simpler: check if 'factories' collection has a doc with ID that matches some logic,
  // but usually it's a query.
  Future<bool> hasFactory(String uid) async {
    try {
      final querySnapshot = await _firestore
          .collection('factories')
          .where('ownerId', isEqualTo: uid)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking factory: $e');
      return false; // Fail safe
    }
  }
}

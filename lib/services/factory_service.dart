import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import '../models/factory_model.dart';

class FactoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Generate Factory Code
  String generateFactoryCode() {
    // Basic implementation: FAC-RANDOM_4_DIGITS
    // In production, you might check for uniqueness.
    var rng = Random();
    int code = rng.nextInt(9000) + 1000;
    return 'FAC-$code';
  }

  // Create Factory
  Future<void> createFactory(FactoryModel factory, File? logoFile) async {
    try {
      String? logoUrl;
      
      if (logoFile != null) {
        final ref = _storage.ref().child('factory_logos/${factory.id}/logo.jpg');
        // Await the upload task directly. This ensures it completes (or throws) before proceeding.
        final TaskSnapshot snapshot = await ref.putFile(logoFile);
        
        if (snapshot.state == TaskState.success) {
          logoUrl = await ref.getDownloadURL();
        } else {
          debugPrint('Factory logo upload failed: State is ${snapshot.state}');
          // Decide: Don't block factory creation if logo fails, or throw?
          // For now, just continue without logoUrl if it fails, but technically await putFile throws on error.
        }
      }

      // Create a new map to include the logoUrl if it was uploaded
      Map<String, dynamic> factoryData = factory.toMap();
      if (logoUrl != null) {
        factoryData['logoUrl'] = logoUrl;
      }

      await _firestore.collection('factories').doc(factory.id).set(factoryData);
    
    } catch (e) {
      debugPrint('Error creating factory: $e');
      rethrow;
    }
  }

  // Check if user has factory - reusing similar logic from profile service or consolidating
  Future<bool> hasFactory(String uid) async {
    try {
      final querySnapshot = await _firestore
          .collection('factories')
          .where('ownerId', isEqualTo: uid)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get Factory Stream (assuming 1 factory per user for now)
  Stream<FactoryModel?> getFactoryStream(String ownerId) {
    return _firestore
        .collection('factories')
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return FactoryModel.fromMap(snapshot.docs.first.data());
      }
      return null;
    });
  }

  // Update Factory
  Future<void> updateFactory(FactoryModel factory) async {
    try {
      await _firestore.collection('factories').doc(factory.id).update(factory.toMap());
    } catch (e) {
      debugPrint('Error updating factory: $e');
      rethrow;
    }
  }
}

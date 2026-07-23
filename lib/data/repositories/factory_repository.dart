import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/entities/bank_account.dart';
import '../../domain/entities/factory_profile.dart';
import '../../domain/enums/business_profile_enums.dart';
import '../../domain/enums/factory_enums.dart';
import '../models/bank_account_model.dart';
import '../models/factory_model.dart';

class FactoryRepository {
  FactoryRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

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
    final profile = FactoryProfile.legacy(
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

  /// Updates a specific section or nested map of the business profile in Firestore
  Future<void> updateSection({
    required String factoryId,
    required ProfileSection section,
    required FactoryProfile profile,
  }) async {
    final model = FactoryModel.fromEntity(profile);
    final fullData = model.toFirestore();

    Map<String, dynamic> updatePayload = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    switch (section) {
      case ProfileSection.identity:
        updatePayload['identity'] = fullData['identity'];
        updatePayload['name'] = fullData['name']; // sync legacy root field
        break;
      case ProfileSection.contact:
        updatePayload['contact'] = fullData['contact'];
        updatePayload['address'] = fullData['address']; // sync legacy root field
        updatePayload['phone'] = fullData['phone']; // sync legacy root field
        break;
      case ProfileSection.legal:
        updatePayload['legal'] = fullData['legal'];
        break;
      case ProfileSection.bankAccounts:
        updatePayload['bankAccounts'] = fullData['bankAccounts'];
        break;
      case ProfileSection.paymentMethods:
        updatePayload['paymentMethodsAccepted'] = fullData['paymentMethodsAccepted'];
        break;
      case ProfileSection.invoiceSettings:
        updatePayload['invoiceSettings'] = fullData['invoiceSettings'];
        break;
      case ProfileSection.operational:
        updatePayload['operational'] = fullData['operational'];
        break;
      case ProfileSection.ownership:
        updatePayload['ownership'] = fullData['ownership'];
        updatePayload['ownerName'] = fullData['ownerName']; // sync legacy root field
        break;
    }

    await _collection.doc(factoryId).update(updatePayload);
  }

  /// Add a bank account to the business profile
  Future<void> addBankAccount(String factoryId, BankAccount account) async {
    final profile = await getFactory(factoryId);
    if (profile == null) return;

    var updatedAccounts = List<BankAccount>.from(profile.bankAccounts);
    // If set to default, set all others to false
    if (account.isDefault) {
      updatedAccounts = updatedAccounts
          .map((b) => b.copyWith(isDefault: false))
          .toList();
    }
    updatedAccounts.add(account);

    await _collection.doc(factoryId).update({
      'bankAccounts': updatedAccounts
          .map((b) => BankAccountModel.fromEntity(b).toMap())
          .toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update an existing bank account
  Future<void> updateBankAccount(String factoryId, BankAccount account) async {
    final profile = await getFactory(factoryId);
    if (profile == null) return;

    var updatedAccounts = profile.bankAccounts.map((b) {
      if (b.id == account.id) {
        return account;
      }
      return account.isDefault ? b.copyWith(isDefault: false) : b;
    }).toList();

    await _collection.doc(factoryId).update({
      'bankAccounts': updatedAccounts
          .map((b) => BankAccountModel.fromEntity(b).toMap())
          .toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a bank account by ID
  Future<void> deleteBankAccount(String factoryId, String accountId) async {
    final profile = await getFactory(factoryId);
    if (profile == null) return;

    final updatedAccounts =
        profile.bankAccounts.where((b) => b.id != accountId).toList();

    await _collection.doc(factoryId).update({
      'bankAccounts': updatedAccounts
          .map((b) => BankAccountModel.fromEntity(b).toMap())
          .toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Uploads an image (logo, signature, stamp) to Firebase Storage and returns download URL
  Future<String> uploadProfileImage({
    required String factoryId,
    required File imageFile,
    required ImageType type,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path =
        'factories/$factoryId/branding/${type.storagePathSegment}_$timestamp.jpg';

    final ref = _storage.ref().child(path);
    final uploadTask = ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }
}

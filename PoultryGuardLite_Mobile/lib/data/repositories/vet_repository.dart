import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/vet/models/vet_model.dart';
import 'base_repository.dart';

final vetRepositoryProvider = Provider<VetRepository>((ref) {
  return VetRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

class VetRepository extends BaseFirestoreRepository<VetModel> {
  VetRepository(super.firestore, super.auth);

  @override
  VetModel fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    return VetModel.fromMap(doc.data()!, doc.id);
  }

  /// Returns a stream of all veterinarian contacts for the current user.
  Stream<List<VetModel>> watchVeterinarians() {
    final user = requireCurrentUser();
    final query = firestore
        .collection('veterinarians')
        .where('ownerId', isEqualTo: user.uid);
    
    return safeCollectionStream(query.snapshots(), 'VetRepository.watchVeterinarians').map((vets) {
      return vets..sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return -1;
        if (bDate == null) return 1;
        return bDate.compareTo(aDate);
      });
    });
  }

  /// Adds a new veterinarian contact.
  Future<void> addVeterinarian(VetModel vet) async {
    final user = requireCurrentUser();
    final docRef = firestore
        .collection('veterinarians')
        .doc(); // Auto-generate ID

    final data = withTimestamps(
      {...vet.toMap(), 'ownerId': user.uid},
      isCreate: true,
    );
    await docRef.set(data);
  }

  /// Updates an existing veterinarian contact.
  Future<void> updateVeterinarian(VetModel vet) async {
    requireCurrentUser();
    final docRef = firestore
        .collection('veterinarians')
        .doc(vet.id);

    final data = withTimestamps(vet.toMap(), isCreate: false);
    await docRef.update(data);
  }

  /// Deletes a veterinarian contact by ID.
  Future<void> deleteVeterinarian(String vetId) async {
    requireCurrentUser();
    await firestore
        .collection('veterinarians')
        .doc(vetId)
        .delete();
  }

  /// Migrates the legacy single profile if it exists and no contacts exist yet.
  Future<void> migrateLegacyVetIfNeeded() async {
    final user = auth.currentUser;
    if (user == null) return;

    // We use a marker in the user's document to avoid checking every time.
    final userDocRef = firestore.collection('users').doc(user.uid);
    final userDoc = await userDocRef.get();
    
    final hasMigratedVets = userDoc.data()?['hasMigratedVets'] as bool? ?? false;
    if (hasMigratedVets) return;

    // Check if legacy profile exists
    final legacyProfileRef = userDocRef.collection('vet').doc('profile');
    final legacyProfileDoc = await legacyProfileRef.get();
    
    if (legacyProfileDoc.exists && legacyProfileDoc.data() != null) {
      // Check if new collection is empty
      final contactsSnapshot = await userDocRef.collection('vet_contacts').limit(1).get();
      if (contactsSnapshot.docs.isEmpty) {
        // Copy to new collection
        final legacyData = legacyProfileDoc.data()!;
        final newDocRef = userDocRef.collection('vet_contacts').doc(); // Auto-generate ID
        
        final data = withTimestamps(legacyData, isCreate: true);
        await newDocRef.set(data);
      }
    }

    // Mark migration as completed regardless of whether we had to migrate
    await userDocRef.set({'hasMigratedVets': true}, SetOptions(merge: true));
  }
}

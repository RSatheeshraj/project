import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/services/logger_service.dart';
import '../../features/flock/models/farm_model.dart';
import 'base_repository.dart';

// ── Provider ───────────────────────────────────────────────────────────────────

final farmRepositoryProvider = Provider<FarmRepository>((ref) {
  return FarmRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

// ── Repository ─────────────────────────────────────────────────────────────────

/// Manages all Firestore operations for the top-level `farms` collection.
///
/// ### Firestore Path
/// ```
/// /farms/{farmId}
/// ```
///
/// ### Query Strategy
/// [watchFarms] filters by `ownerId` (single-field, auto-indexed by Firestore)
/// and sorts the result **in-memory** after the snapshot arrives. This eliminates
/// the `ownerId + createdAt` composite index that the previous implementation
/// required, reducing Firebase Console configuration and Firestore costs.
class FarmRepository extends BaseFirestoreRepository<FarmModel> {
  FarmRepository(super.firestore, super.auth);

  CollectionReference<Map<String, dynamic>> get _farms =>
      firestore.collection('farms');

  // ── fromDocument ─────────────────────────────────────────────────────────

  @override
  FarmModel fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    return FarmModel.fromMap(doc.data()!, doc.id);
  }

  // ── Streams ───────────────────────────────────────────────────────────────

  /// Streams all farms belonging to the current user, sorted by [FarmModel.createdAt]
  /// descending (most recent first).
  Stream<List<FarmModel>> watchFarms() {
    final uid = currentUserId;

    if (uid == null) {
      AppLogger.w(
        '[FarmRepository] watchFarms called with no authenticated user.',
      );
      return Stream.value([]);
    }

    AppLogger.d('[FarmRepository] watchFarms → uid: $uid');

    return safeCollectionStream(
      _farms.where('ownerId', isEqualTo: uid).snapshots(),
      'FarmRepository.watchFarms',
    ).map((farms) {
      AppLogger.d(
        '[FarmRepository] watchFarms → ${farms.length} farm(s) received.',
      );
      // Sort in-memory: newest first. Null createdAt falls to the end.
      return farms..sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return -1; // Pending writes (null) are the newest
        if (bDate == null) return 1;
        return bDate.compareTo(aDate);
      });
    });
  }

  /// Streams a single farm document by [farmId].
  Stream<FarmModel?> watchFarm(String farmId) {
    final uid = currentUserId;
    if (uid == null) {
      AppLogger.w(
        '[FarmRepository] watchFarm called with no authenticated user.',
      );
      return Stream.value(null);
    }

    return _farms
        .doc(farmId)
        .snapshots()
        .handleError((Object error, StackTrace stackTrace) {
          AppLogger.e(
            '[FarmRepository.watchFarm] Firestore stream error for $farmId',
            error: error,
            stackTrace: stackTrace,
          );
          throw RepositoryException('Failed to load farm.', cause: error);
        })
        .map((snap) => snap.exists ? FarmModel.fromMap(snap.data()!, snap.id) : null);
  }

  // ── Write Operations ──────────────────────────────────────────────────────

  /// Creates a new farm document in Firestore.
  Future<void> addFarm(FarmModel farm) async {
    try {
      AppLogger.d('[FarmRepository] addFarm() called. Attempting to get current user...');
      final user = requireCurrentUser();
      AppLogger.d('[FarmRepository] Current user found: ${user.uid}. Preparing data...');
      
      final data = withTimestamps(
        farm.copyWith(ownerId: user.uid).toMap(),
        isCreate: true,
      );
      
      AppLogger.d('[FarmRepository] Data prepared. Writing to Firestore path: farms');
      await _farms.add(data);
      AppLogger.i('[FarmRepository] addFarm → farm created successfully.');
    } on UnauthenticatedException {
      AppLogger.e('[FarmRepository] addFarm failed: Unauthenticated user');
      rethrow;
    } catch (e, st) {
      AppLogger.e('[FarmRepository] addFarm failed with exception: $e', error: e, stackTrace: st);
      throw RepositoryException('Failed to create farm: $e', cause: e);
    }
  }

  /// Updates an existing farm document.
  Future<void> updateFarm(FarmModel farm) async {
    try {
      requireOwnership(farm.ownerId);
      final data = withTimestamps(farm.toMap(), isCreate: false);
      await _farms.doc(farm.id).update(data);
      AppLogger.i(
        '[FarmRepository] updateFarm → ${farm.id} updated successfully.',
      );
    } on UnauthenticatedException {
      rethrow;
    } on UnauthorizedException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(
        '[FarmRepository] updateFarm failed',
        error: e,
        stackTrace: st,
      );
      throw RepositoryException('Failed to update farm.', cause: e);
    }
  }

  /// Deletes a farm document by [farmId].
  Future<void> deleteFarm(String farmId) async {
    try {
      requireCurrentUser();
      await _farms.doc(farmId).delete();
      AppLogger.i('[FarmRepository] deleteFarm → $farmId deleted.');
    } on UnauthenticatedException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(
        '[FarmRepository] deleteFarm failed',
        error: e,
        stackTrace: st,
      );
      throw RepositoryException('Failed to delete farm.', cause: e);
    }
  }
}

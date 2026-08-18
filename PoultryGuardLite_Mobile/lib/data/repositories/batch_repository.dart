import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/services/logger_service.dart';
import '../../features/flock/models/batch_model.dart';
import 'base_repository.dart';

// ── Provider ───────────────────────────────────────────────────────────────────

final batchRepositoryProvider = Provider<BatchRepository>((ref) {
  return BatchRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

// ── Repository ─────────────────────────────────────────────────────────────────

/// Manages all Firestore operations for the `batches` sub-collection.
///
/// ### Firestore Path
/// ```
/// /farms/{farmId}/batches/{batchId}
/// ```
///
/// ### Query Strategy — Sub-Collection Ownership
/// The `batches` sub-collection is path-scoped: a client can only reach
/// `farms/{farmId}/batches` if it already possesses the `farmId`. Ownership
/// is structurally guaranteed by the path hierarchy itself and enforced
/// server-side by Firestore Security Rules.
///
/// Therefore, [watchBatches] uses only `.orderBy('createdAt')` — a single-field
/// index that Firestore creates automatically. The previous `where('ownerId')`
/// filter is removed, eliminating the composite index requirement.
///
/// [watchAllUserBatches] uses a collection group query (required for dashboard
/// statistics) and retains the `where('ownerId')` filter. This requires a
/// **collection group index** in Firebase Console:
/// Collection group `batches`, field `ownerId` (Ascending), scope: Collection group.
class BatchRepository extends BaseFirestoreRepository<BatchModel> {
  BatchRepository(super.firestore, super.auth);

  CollectionReference<Map<String, dynamic>> _batches(String farmId) {
    return firestore.collection('farms').doc(farmId).collection('batches');
  }

  // ── fromDocument ─────────────────────────────────────────────────────────

  @override
  BatchModel fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    return BatchModel.fromMap(doc.data()!, doc.id);
  }

  // ── Streams ───────────────────────────────────────────────────────────────

  /// Streams all batches for a specific [farmId], ordered by creation date
  /// descending (most recent first).
  Stream<List<BatchModel>> watchBatches(String farmId) {
    final uid = currentUserId;
    if (uid == null) {
      AppLogger.w(
        '[BatchRepository] watchBatches called with no authenticated user.',
      );
      return Stream.value([]);
    }

    return safeCollectionStream(
      _batches(farmId).orderBy('createdAt', descending: true).snapshots(),
      'BatchRepository.watchBatches[$farmId]',
    );
  }

  /// Streams ALL batches across ALL farms for the current user.
  Stream<List<BatchModel>> watchAllUserBatches() {
  final uid = currentUserId;

  if (uid == null) {
    AppLogger.w(
      '[BatchRepository] watchAllUserBatches called with no authenticated user.',
    );
    return Stream.value([]);
  }

  final rawStream = firestore
      .collectionGroup('batches')
      .where('ownerId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots();

  return rawStream
      .handleError((Object error, StackTrace stackTrace) {
        AppLogger.e(
          '[BatchRepository.watchAllUserBatches] Firestore stream error',
          error: error,
          stackTrace: stackTrace,
        );
        throw RepositoryException(
          'Failed to load batches.',
          cause: error,
        );
      })
      .map(
        (snapshot) => snapshot.docs
            .map(
              (doc) => BatchModel.fromMap(
                doc.data(),
                doc.id,
              ),
            )
            .toList(),
      );
}

  /// Streams a single batch document by [farmId] and [batchId].
  Stream<BatchModel?> watchBatch(String farmId, String batchId) {
    final uid = currentUserId;
    if (uid == null) {
      AppLogger.w(
        '[BatchRepository] watchBatch called with no authenticated user.',
      );
      return Stream.value(null);
    }

    return _batches(farmId)
        .doc(batchId)
        .snapshots()
        .handleError((Object error, StackTrace stackTrace) {
          AppLogger.e(
            '[BatchRepository.watchBatch] Firestore stream error for $farmId/$batchId',
            error: error,
            stackTrace: stackTrace,
          );
          throw RepositoryException('Failed to load batch.', cause: error);
        })
        .map(
          (snap) =>
              snap.exists ? BatchModel.fromMap(snap.data()!, snap.id) : null,
        );
  }

  // ── Write Operations ──────────────────────────────────────────────────────

  /// Creates a new batch document under the given farm.
  Future<void> addBatch(BatchModel batch) async {
    try {
      final user = requireCurrentUser();
      final data = withTimestamps(
        batch.copyWith(ownerId: user.uid).toMap(),
        isCreate: true,
      );
      await _batches(batch.farmId).add(data);
      AppLogger.i(
        '[BatchRepository] addBatch → batch created in farm ${batch.farmId}.',
      );
    } on UnauthenticatedException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(
        '[BatchRepository] addBatch failed',
        error: e,
        stackTrace: st,
      );
      throw RepositoryException('Failed to create batch.', cause: e);
    }
  }

  /// Updates an existing batch document.
  Future<void> updateBatch(BatchModel batch) async {
    try {
      requireOwnership(batch.ownerId);
      final data = withTimestamps(batch.toMap(), isCreate: false);
      await _batches(batch.farmId).doc(batch.id).update(data);
      AppLogger.i('[BatchRepository] updateBatch → ${batch.id} updated.');
    } on UnauthenticatedException {
      rethrow;
    } on UnauthorizedException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(
        '[BatchRepository] updateBatch failed',
        error: e,
        stackTrace: st,
      );
      throw RepositoryException('Failed to update batch.', cause: e);
    }
  }

  /// Deletes a batch document by [batchId] within the given [farmId].
  Future<void> deleteBatch(String farmId, String batchId) async {
    try {
      requireCurrentUser();
      await _batches(farmId).doc(batchId).delete();
      AppLogger.i(
        '[BatchRepository] deleteBatch → $batchId deleted from farm $farmId.',
      );
    } on UnauthenticatedException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(
        '[BatchRepository] deleteBatch failed',
        error: e,
        stackTrace: st,
      );
      throw RepositoryException('Failed to delete batch.', cause: e);
    }
  }
}

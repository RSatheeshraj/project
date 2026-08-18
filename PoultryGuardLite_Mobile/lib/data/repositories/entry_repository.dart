import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/services/logger_service.dart';
import '../../features/flock/models/entry_model.dart';
import 'base_repository.dart';

// ── Provider ───────────────────────────────────────────────────────────────────

final entryRepositoryProvider = Provider<EntryRepository>((ref) {
  return EntryRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

// ── Repository ─────────────────────────────────────────────────────────────────

/// Manages all Firestore operations for the `weekly_entries` sub-collection.
///
/// ### Firestore Path
/// ```
/// /farms/{farmId}/batches/{batchId}/weekly_entries/{entryId}
/// ```
///
/// ### Query Strategy — Sub-Collection Ownership
/// The `weekly_entries` sub-collection is path-scoped at depth 3. A client
/// that reaches this collection has already resolved `farmId` and `batchId`,
/// both of which belong to the authenticated user. Ownership is structurally
/// guaranteed by the path hierarchy and enforced by Firestore Security Rules.
///
/// Therefore, [watchEntries] uses only `.orderBy('entryDate')` — a single-field
/// index that Firestore creates automatically. The previous `where('ownerId')`
/// filter is removed, eliminating the composite index requirement.
class EntryRepository extends BaseFirestoreRepository<EntryModel> {
  EntryRepository(super.firestore, super.auth);

  CollectionReference<Map<String, dynamic>> _entries(
    String farmId,
    String batchId,
  ) {
    return firestore
        .collection('farms')
        .doc(farmId)
        .collection('batches')
        .doc(batchId)
        .collection('weekly_entries');
  }

  // ── fromDocument ─────────────────────────────────────────────────────────

  @override
  EntryModel fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    return EntryModel.fromMap(doc.data()!, doc.id);
  }

  // ── Streams ───────────────────────────────────────────────────────────────

  /// Streams all weekly entries for a specific batch, ordered by [EntryModel.entryDate]
  /// descending (most recent first).
  Stream<List<EntryModel>> watchEntries(String farmId, String batchId) {
    final uid = currentUserId;
    if (uid == null) {
      AppLogger.w(
        '[EntryRepository] watchEntries called with no authenticated user.',
      );
      return Stream.value([]);
    }

    return safeCollectionStream(
      _entries(
        farmId,
        batchId,
      ).orderBy('entryDate', descending: true).snapshots(),
      'EntryRepository.watchEntries[$farmId/$batchId]',
    );
  }

  // ── Write Operations ──────────────────────────────────────────────────────

  /// Creates a new weekly entry under the given farm and batch.
  Future<void> addEntry(EntryModel entry) async {
    try {
      final user = requireCurrentUser();
      final data = withTimestamps(
        entry.copyWith(ownerId: user.uid).toMap(),
        isCreate: true,
      );
      await _entries(entry.farmId, entry.batchId).add(data);
      AppLogger.i(
        '[EntryRepository] addEntry → entry created in batch ${entry.batchId}.',
      );
    } on UnauthenticatedException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(
        '[EntryRepository] addEntry failed',
        error: e,
        stackTrace: st,
      );
      throw RepositoryException('Failed to create entry.', cause: e);
    }
  }

  /// Updates an existing weekly entry.
  Future<void> updateEntry(EntryModel entry) async {
    try {
      requireOwnership(entry.ownerId);
      final data = withTimestamps(entry.toMap(), isCreate: false);
      await _entries(entry.farmId, entry.batchId).doc(entry.id).update(data);
      AppLogger.i('[EntryRepository] updateEntry → ${entry.id} updated.');
    } on UnauthenticatedException {
      rethrow;
    } on UnauthorizedException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(
        '[EntryRepository] updateEntry failed',
        error: e,
        stackTrace: st,
      );
      throw RepositoryException('Failed to update entry.', cause: e);
    }
  }

  /// Deletes a weekly entry by [entryId].
  Future<void> deleteEntry(
    String farmId,
    String batchId,
    String entryId,
  ) async {
    try {
      requireCurrentUser();
      await _entries(farmId, batchId).doc(entryId).delete();
      AppLogger.i('[EntryRepository] deleteEntry → $entryId deleted.');
    } on UnauthenticatedException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(
        '[EntryRepository] deleteEntry failed',
        error: e,
        stackTrace: st,
      );
      throw RepositoryException('Failed to delete entry.', cause: e);
    }
  }
}

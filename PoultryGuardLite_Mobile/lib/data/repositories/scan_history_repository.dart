
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/services/logger_service.dart';
import '../../features/scan/models/scan_history_model.dart';
import 'base_repository.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

// ── Provider ───────────────────────────────────────────────────────────────────

final scanHistoryRepositoryProvider = Provider<ScanHistoryRepository>((ref) {
  return ScanHistoryRepository(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
    FirebaseStorage.instance,
  );
});

// ── Repository ─────────────────────────────────────────────────────────────────

/// Manages Firestore and Firebase Storage operations for AI scan history.
///
/// ### Firestore Path
/// ```
/// /scan_history/{scanId}
/// ```
///
/// ### Query Strategy
/// Unlike sub-collections, `scan_history` is a top-level collection with no
/// path-level ownership guarantee. The `where('ownerId').orderBy('createdAt')`
/// query is therefore necessary and requires a **composite index** in Firebase Console:
/// - Collection: `scan_history`
/// - Fields: `ownerId (Ascending)`, `createdAt (Descending)`
/// - Scope: Collection
class ScanHistoryRepository extends BaseFirestoreRepository<ScanHistoryModel> {
  ScanHistoryRepository(super.firestore, super.auth, this.storage);

  final FirebaseStorage storage;

  CollectionReference<Map<String, dynamic>> get _scanHistory =>
      firestore.collection('scan_history');

  // ── fromDocument ─────────────────────────────────────────────────────────

  @override
  ScanHistoryModel fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ScanHistoryModel.fromMap(doc.data()!, doc.id);
  }

  // ── Streams ───────────────────────────────────────────────────────────────

  /// Streams all scan history records for the current user across all farms,
  /// ordered by [ScanHistoryModel.createdAt] descending (most recent first).
  Stream<List<ScanHistoryModel>> watchScanHistory() {
    final uid = currentUserId;

    if (uid == null) {
      AppLogger.w(
        '[ScanHistoryRepository] watchScanHistory called with no authenticated user.',
      );
      return Stream.value([]);
    }

    return safeCollectionStream(
      _scanHistory
          .where('ownerId', isEqualTo: uid)
          .snapshots(),
      'ScanHistoryRepository.watchScanHistory',
    ).map((scans) {
      return scans..sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return -1;
        if (bDate == null) return 1;
        return bDate.compareTo(aDate);
      });
    });
  }

  /// Streams scan history for a specific batch
  Stream<List<ScanHistoryModel>> watchBatchScanHistory(String farmId, String batchId) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);
    
    return safeCollectionStream(
      _scanHistory
          .where('ownerId', isEqualTo: uid)
          .where('farmId', isEqualTo: farmId)
          .where('batchId', isEqualTo: batchId)
          .snapshots(),
      'ScanHistoryRepository.watchBatchScanHistory',
    ).map((scans) {
      return scans..sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return -1;
        if (bDate == null) return 1;
        return bDate.compareTo(aDate);
      });
    });
  }

  // ── Write Operations ──────────────────────────────────────────────────────

  /// Generates a new Firestore document ID for a scan.
  String generateScanId(String farmId, String batchId) {
    return _scanHistory.doc().id;
  }

  /// Uploads a scan image to Firebase Storage and returns the download URL.
  Future<String> uploadScanImage(String scanId, File imageFile) async {
    try {
      final uid = requireCurrentUser().uid;
      final ref = storage.ref().child('scan_images/$uid/$scanId.jpg');
      
      final snapshot = await ref.putFile(
        imageFile, 
        SettableMetadata(contentType: 'image/jpeg')
      );
      
      return await snapshot.ref.getDownloadURL();
    } catch (e, st) {
      AppLogger.e('Failed to upload scan image', error: e, stackTrace: st);
      throw RepositoryException('Failed to upload scan image.', cause: e);
    }
  }

  /// Saves a new [ScanHistoryModel] to Firestore.
  Future<void> addScanHistory(ScanHistoryModel scan) async {
    try {
      final user = requireCurrentUser();
      final rawData = scan.copyWith(ownerId: user.uid).toMap();
      final data = withTimestamps(rawData, isCreate: true);
      
      final docRef = scan.id.isEmpty 
          ? _scanHistory.doc()
          : _scanHistory.doc(scan.id);
          
      await docRef.set(data);
      AppLogger.i(
        '[ScanHistoryRepository] addScanHistory → scan record saved.',
      );
    } on UnauthenticatedException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(
        '[ScanHistoryRepository] addScanHistory failed',
        error: e,
        stackTrace: st,
      );
      throw RepositoryException('Failed to save scan history.', cause: e);
    }
  }

  /// Deletes a scan history record by [scanId].
  Future<void> deleteScanHistory(String farmId, String batchId, String scanId) async {
    try {
      requireCurrentUser();
      await _scanHistory.doc(scanId).delete();
      AppLogger.i(
        '[ScanHistoryRepository] deleteScanHistory → deleted scan $scanId.',
      );
    } on UnauthenticatedException {
      rethrow;
    } catch (e, st) {
      AppLogger.e(
        '[ScanHistoryRepository] deleteScanHistory failed',
        error: e,
        stackTrace: st,
      );
      throw RepositoryException('Failed to delete scan history record.', cause: e);
    }
  }
}

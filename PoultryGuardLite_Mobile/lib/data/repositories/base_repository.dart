import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/services/logger_service.dart';

/// Generic base class for all Firestore repositories in PoultryGuardLite.
///
/// ### Responsibilities
/// - Enforces authentication before every operation via [requireCurrentUser].
/// - Enforces document ownership via [requireOwnership].
/// - Stamps `createdAt` and `updatedAt` server timestamps via [withTimestamps].
/// - Wraps streams with structured error logging via [safeStream].
/// - Maps [DocumentSnapshot] to domain models via the abstract [fromDocument].
///
/// ### Usage
/// ```dart
/// class FarmRepository extends BaseFirestoreRepository<FarmModel> {
///   FarmRepository(super.firestore, super.auth);
///
///   @override
///   FarmModel fromDocument(DocumentSnapshot doc) =>
///       FarmModel.fromMap(doc.data()! as Map<String, dynamic>, doc.id);
/// }
/// ```
abstract class BaseFirestoreRepository<T> {
  const BaseFirestoreRepository(this.firestore, this.auth);

  /// The Firestore instance injected by the provider.
  final FirebaseFirestore firestore;

  /// The FirebaseAuth instance injected by the provider.
  final FirebaseAuth auth;

  // ── Abstract contract ──────────────────────────────────────────────────────

  /// Maps a Firestore [DocumentSnapshot] to the domain model [T].
  ///
  /// Subclasses must implement this to provide type-safe document mapping.
  T fromDocument(DocumentSnapshot<Map<String, dynamic>> doc);

  // ── Auth guards ────────────────────────────────────────────────────────────

  /// Returns the currently signed-in [User].
  ///
  /// Throws [UnauthenticatedException] if no user is signed in.
  /// Call this at the start of every write operation.
  User requireCurrentUser() {
    final user = auth.currentUser;
    if (user == null) {
      throw const UnauthenticatedException();
    }
    return user;
  }

  /// Returns the current user's UID, or `null` if not signed in.
  ///
  /// Use this in [Stream] builders — returning an empty stream is preferred
  /// over throwing inside a stream callback.
  String? get currentUserId => auth.currentUser?.uid;

  /// Verifies that [ownerId] matches the current user's UID.
  ///
  /// Throws [UnauthorizedException] if there is a mismatch.
  /// Call before any update or delete that operates on a specific document.
  void requireOwnership(String ownerId) {
    final user = requireCurrentUser();
    if (ownerId != user.uid) {
      throw const UnauthorizedException();
    }
  }

  // ── Timestamp helpers ──────────────────────────────────────────────────────

  /// Returns [data] merged with server-side timestamp fields.
  ///
  /// - On create ([isCreate] = true): sets both `createdAt` and `updatedAt`.
  /// - On update ([isCreate] = false): sets only `updatedAt`.
  ///
  /// The caller's [data] map is never mutated — a new map is returned.
  Map<String, dynamic> withTimestamps(
    Map<String, dynamic> data, {
    required bool isCreate,
  }) {
    return {
      ...data,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ── Stream safety ──────────────────────────────────────────────────────────

  /// Wraps a raw Firestore [QuerySnapshot] stream with structured error logging.
  ///
  /// Errors are logged at [AppLogger.e] level and re-emitted so the UI can
  /// display them via Riverpod's `AsyncError` state.
  Stream<List<T>> safeCollectionStream(
    Stream<QuerySnapshot<Map<String, dynamic>>> rawStream,
    String context,
  ) {
    return rawStream
        .handleError((Object error, StackTrace stackTrace) {
          AppLogger.e(
            '[$context] Firestore stream error',
            error: error,
            stackTrace: stackTrace,
          );
          // Re-throw so Riverpod's StreamProvider surfaces it as AsyncError.
          throw RepositoryException('Failed to load data.', cause: error);
        })
        .map(
          (snapshot) => snapshot.docs.map((doc) => fromDocument(doc)).toList(),
        );
  }
}

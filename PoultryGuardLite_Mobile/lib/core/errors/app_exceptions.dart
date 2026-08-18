// Typed domain exceptions for PoultryGuardLite.
//
// Repositories throw these instead of raw [Exception] objects so the UI
// layer can catch specific failure categories without string-matching.

// ── Authentication ─────────────────────────────────────────────────────────────

/// Thrown by [AuthRepository] on Firebase Authentication failures.
/// Maps raw [FirebaseAuthException] codes to user-friendly messages.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

// ── Repository ─────────────────────────────────────────────────────────────────

/// Thrown by any Firestore repository when a read or write operation fails.
///
/// Wraps the underlying [cause] so callers can inspect the original error
/// while still catching a clean typed exception at the UI boundary.
class RepositoryException implements Exception {
  const RepositoryException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => cause != null ? '$message ($cause)' : message;
}

// ── Authorization ──────────────────────────────────────────────────────────────

/// Thrown when the current user attempts to mutate a document they do not own.
///
/// Repositories call [BaseFirestoreRepository.requireOwnership] which throws
/// this if the document's [ownerId] does not match [FirebaseAuth.currentUser.uid].
class UnauthorizedException implements Exception {
  const UnauthorizedException([
    this.message = 'You are not authorized to perform this action.',
  ]);
  final String message;

  @override
  String toString() => message;
}

// ── Unauthenticated ────────────────────────────────────────────────────────────

/// Thrown when a repository method is called while no user is signed in.
///
/// Repositories call [BaseFirestoreRepository.requireCurrentUser] which throws
/// this when [FirebaseAuth.currentUser] is null.
class UnauthenticatedException implements Exception {
  const UnauthenticatedException([
    this.message = 'You must be signed in to perform this action.',
  ]);
  final String message;

  @override
  String toString() => message;
}

// ── AI Scan ─────────────────────────────────────────────────────────────────────

/// Thrown by [AiScanRepository] when Gemini AI analysis fails.
///
/// [message] is a user-friendly description of the failure.
/// [cause] preserves the original exception for logging and debugging.
class AiScanException implements Exception {
  const AiScanException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => cause != null ? '$message ($cause)' : message;
}

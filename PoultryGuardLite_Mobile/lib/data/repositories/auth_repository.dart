import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../../core/errors/app_exceptions.dart';

/// Wraps [FirebaseAuth] with clean, typed methods.
///
/// Session persistence is handled automatically by Firebase on Android —
/// the user stays logged in across app restarts with no extra configuration.
class AuthRepository {
  const AuthRepository(this._auth);
  final FirebaseAuth _auth;

  // ── Streams ───────────────────────────────────────────────────────────────

  /// Emits the current [User] whenever auth state changes; null = signed out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in [User], or null.
  User? get currentUser => _auth.currentUser;

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Signs in with [email] and [password].
  /// Throws [AuthException] with a user-friendly message on failure.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  /// Creates a new account and sets the display [name].
  /// Throws [AuthException] with a user-friendly message on failure.
  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(name.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  /// Updates the current user's profile information.
  Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      if (user.displayName != name.trim()) {
        await user.updateDisplayName(name.trim());
      }
      if (user.email != email.trim()) {
        await user.verifyBeforeUpdateEmail(email.trim());
      }
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  /// Changes the user's password securely by re-authenticating first.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  /// Sends a password reset email to the given [email].
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  /// Signs in with Google OAuth.
  Future<void> signInWithGoogle() async {
    try {
      // Import google_sign_in at the top of the file
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in flow
        return;
      }
      
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    } catch (e) {
      debugPrint('[AuthRepository] Google Sign-In Error: $e');
      throw AuthException('Failed to sign in with Google. Please try again.');
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    return _auth.signOut();
  }

  // ── Error mapping ─────────────────────────────────────────────────────────

  AuthException _mapError(FirebaseAuthException e) {
    debugPrint(
      '[AuthRepository] FirebaseAuthException → code: ${e.code} | message: ${e.message}',
    );
    final message = switch (e.code) {
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Incorrect email or password.',
      'email-already-in-use' => 'An account with this email already exists.',
      'weak-password' => 'Password must be at least 6 characters.',
      'invalid-email' => 'Please enter a valid email address.',
      'user-disabled' => 'This account has been disabled.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      _ => e.message ?? 'Authentication failed.',
    };
    return AuthException(message);
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/auth_repository.dart';

// ── Repository provider ───────────────────────────────────────────────────────

/// Provides the [AuthRepository] singleton backed by [FirebaseAuth.instance].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance);
});

// ── Auth state stream ─────────────────────────────────────────────────────────

/// Streams the current Firebase [User].
/// - `AsyncData(user)` → signed in
/// - `AsyncData(null)`  → signed out
/// - `AsyncLoading()`   → initial check in progress
///
/// The router listens to this to enforce the auth guard.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

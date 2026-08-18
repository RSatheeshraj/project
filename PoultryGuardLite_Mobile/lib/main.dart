import 'dart:developer' as developer;

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Initialize Firebase ────────────────────────────────────────────────
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }  

  // ── 2. Initialize Firebase App Check ─────────────────────────────────────
  // App Check is activated for release builds using Play Integrity.
  // In debug mode, activation is skipped unless configured in Firebase Console
  // to prevent 'App attestation failed (403)' errors on developer phones.
  if (!kDebugMode) {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
      );
    } catch (e) {
      developer.log(
        'App Check initialization warning (non-fatal): $e',
        name: 'AppCheck',
      );
    }
  }

  // Configure Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  // ── 3. Print the debug token when running in debug mode ───────────────────
  // The Android SDK logs the token to Logcat automatically. We surface it here
  // as well so it is visible directly in the Flutter "flutter run" console.
  if (kDebugMode) {
    FirebaseAppCheck.instance.onTokenChange.listen((token) {
      if (token != null) {
        developer.log(
          '╔══════════════════════════════════════════════════════════════╗\n'
          '║  Firebase App Check — DEBUG TOKEN                           ║\n'
          '║  Register this in Firebase Console → App Check              ║\n'
          '║  → Manage debug tokens for your Android app                 ║\n'
          '║                                                              ║\n'
          '║  $token\n'
          '║                                                              ║\n'
          '╚══════════════════════════════════════════════════════════════╝',
          name: 'AppCheck',
        );
      }
    });

  }

  runApp(const ProviderScope(child: App()));
}

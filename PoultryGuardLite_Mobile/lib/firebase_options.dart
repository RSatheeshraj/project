// Hand-authored from Firebase Console — supports Android + Web.
// To regenerate via CLI: dart pub global activate flutterfire_cli && flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example usage:
/// ```dart
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'PoultryGuard Lite targets Android only. '
          'Configure an iOS app in the Firebase Console if needed.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  // ── Android ─────────────────────────────────────────────────────────────────
  // Source: android/app/google-services.json

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCAv3VoRXAxnI6HAgbpYhYmECtHJA0MjLk',
    appId: '1:1050344579652:web:4f86bd6b3d9e00a9661211',
    messagingSenderId: '1050344579652',
    projectId: 'poultryguardlite-435d9',
    storageBucket: 'poultryguardlite-435d9.firebasestorage.app',
    authDomain: 'poultryguardlite-435d9.firebaseapp.com',
  );

  // ── Web ──────────────────────────────────────────────────────────────────────
  // Source: Firebase Console → Project Settings → Web app

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCAv3VoRXAxnI6HAgbpYhYmECtHJA0MjLk',
    authDomain: 'poultryguardlite-435d9.firebaseapp.com',
    appId: '1:1050344579652:web:4f86bd6b3d9e00a9661211',
    messagingSenderId: '1050344579652',
    projectId: 'poultryguardlite-435d9',
    storageBucket: 'poultryguardlite-435d9.firebasestorage.app',
    measurementId: 'G-85CB46ZV2K',
  );
}

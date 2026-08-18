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
    apiKey: 'AIzaSyBAOZrRQRWMCBOX6nHPerrgp-HKFzZH5ko',
    appId: '1:1013031899395:android:aa8e6c62706c7428ca1936',
    messagingSenderId: '1013031899395',
    projectId: 'poultryguardlite',
    storageBucket: 'poultryguardlite.appspot.com',
  );

  // ── Web ──────────────────────────────────────────────────────────────────────
  // Source: Firebase Console → Project Settings → Web app

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCUsKqEa2xlGlfCHY0MQVAGca58y7mAsSU',
    authDomain: 'poultryguardlite.firebaseapp.com',
    appId: '1:1013031899395:web:4eb9d406fa42f6f9ca1936',
    messagingSenderId: '1013031899395',
    projectId: 'poultryguardlite',
    storageBucket: 'poultryguardlite.appspot.com',
    measurementId: 'G-M84WJKKCHG',
  );
}

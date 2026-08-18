/**
 * Firebase Client SDK singleton.
 *
 * Mirrors the configuration from Flutter's firebase_options.dart (web config).
 * All env vars are NEXT_PUBLIC_ so they are safely embedded in the browser bundle.
 * Firebase's own security rules and auth guards protect the data layer.
 */

import { initializeApp, getApps, getApp, type FirebaseApp } from 'firebase/app';

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY || 'AIzaSyCUsKqEa2xlGlfCHY0MQVAGca58y7mAsSU',
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || 'poultryguardlite.firebaseapp.com',
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || 'poultryguardlite',
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET || 'poultryguardlite.firebasestorage.app',
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || '1013031899395',
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || '1:1013031899395:web:4eb9d406fa42f6f9ca1936',
  measurementId: process.env.NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID || 'G-M84WJKKCHG',
};

// Prevent duplicate initialization during Next.js hot-reloads.
const firebaseApp: FirebaseApp =
  getApps().length === 0 ? initializeApp(firebaseConfig) : getApp();

export default firebaseApp;

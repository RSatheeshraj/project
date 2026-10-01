/**
 * Firebase Client SDK singleton.
 *
 * Mirrors the configuration from Flutter's firebase_options.dart (web config).
 * All env vars are NEXT_PUBLIC_ so they are safely embedded in the browser bundle.
 * Firebase's own security rules and auth guards protect the data layer.
 */

import { initializeApp, getApps, getApp, type FirebaseApp } from 'firebase/app';

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY || 'AIzaSyCAv3VoRXAxnI6HAgbpYhYmECtHJA0MjLk',
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || 'poultryguardlite-435d9.firebaseapp.com',
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || 'poultryguardlite-435d9',
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET || 'poultryguardlite-435d9.firebasestorage.app',
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || '1050344579652',
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || '1:1050344579652:web:4f86bd6b3d9e00a9661211',
  measurementId: process.env.NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID || 'G-85CB46ZV2K',
};

// Prevent duplicate initialization during Next.js hot-reloads.
const firebaseApp: FirebaseApp =
  getApps().length === 0 ? initializeApp(firebaseConfig) : getApp();

export default firebaseApp;

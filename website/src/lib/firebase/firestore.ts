/**
 * Firebase Firestore singleton + collection path helpers.
 *
 * Collection paths mirror the Flutter repository layer exactly:
 *   /farms/{farmId}
 *   /farms/{farmId}/batches/{batchId}
 *   /farms/{farmId}/batches/{batchId}/weekly_entries/{entryId}
 *   /scan_history/{scanId}
 *
 * NOTE: We use untyped CollectionReference for write operations because
 * Firestore's typed API requires the id field in writes, but id is a document
 * path — not a document field. Typed reads are handled by the to*() helpers
 * in each repository.
 */

import { getFirestore, collection } from 'firebase/firestore';
import firebaseApp from './client';

const db = getFirestore(firebaseApp);

export default db;

// ── Collection path helpers ──────────────────────────────────────────────────

/** /farms — top-level collection */
export const farmsCol = () => collection(db, 'farms');

/** /farms/{farmId}/batches */
export const batchesCol = (farmId: string) =>
  collection(db, `farms/${farmId}/batches`);

/** /farms/{farmId}/batches/{batchId}/weekly_entries */
export const weeklyEntriesCol = (farmId: string, batchId: string) =>
  collection(db, `farms/${farmId}/batches/${batchId}/weekly_entries`);

/** /scan_history — top-level collection */
export const scanHistoryCol = () => collection(db, 'scan_history');

/** /sales — top-level collection */
export const salesCol = () => collection(db, 'sales');

/** /veterinarians — top-level collection */
export const veterinariansCol = () => collection(db, 'veterinarians');

/** /reminders — top-level collection */
export const remindersCol = () => collection(db, 'reminders');

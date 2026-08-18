/**
 * EntryRepository — web equivalent of Flutter's EntryRepository.
 *
 * Firestore path: /farms/{farmId}/batches/{batchId}/weekly_entries/{entryId}
 * Ownership guaranteed by path depth (same as Flutter).
 * orderBy('entryDate') — single-field, no composite index.
 */

import {
  addDoc,
  updateDoc,
  deleteDoc,
  doc,
  getDocs,
  query,
  orderBy,
  serverTimestamp,
  onSnapshot,
  Timestamp,
  type Unsubscribe,
} from 'firebase/firestore';
import db, { weeklyEntriesCol } from '@/lib/firebase/firestore';
import auth from '@/lib/firebase/auth';
import type { WeeklyEntry, WeeklyEntryInput } from '@/types/models';
import { RepositoryError } from './farm.repository';

// ── Helper ────────────────────────────────────────────────────────────────────

function requireUid(): string {
  const uid = auth.currentUser?.uid;
  if (!uid) throw new RepositoryError('You must be signed in.');
  return uid;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function toEntry(id: string, data: Record<string, any>): WeeklyEntry {
  return {
    id,
    batchId: data.batchId ?? '',
    farmId: data.farmId ?? '',
    ownerId: data.ownerId ?? '',
    entryDate: data.entryDate?.toDate(),
    feedConsumedKg: data.feedConsumedKg ?? 0,
    waterConsumedLitres: data.waterConsumedLitres ?? 0,
    mortalityCount: data.mortalityCount ?? 0,
    averageWeightKg: data.averageWeightKg ?? 0,
    temperature: data.temperature ?? 0,
    humidity: data.humidity ?? 0,
    vaccination: data.vaccination ?? '',
    medicine: data.medicine ?? '',
    notes: data.notes ?? '',
    createdAt: data.createdAt?.toDate(),
    updatedAt: data.updatedAt?.toDate(),
  };
}

// ── Repository ────────────────────────────────────────────────────────────────

export const EntryRepository = {
  /** Returns all weekly entries for a batch, newest-first. */
  async getEntries(farmId: string, batchId: string): Promise<WeeklyEntry[]> {
    requireUid();
    const q = query(weeklyEntriesCol(farmId, batchId), orderBy('entryDate', 'desc'));
    const snap = await getDocs(q);
    return snap.docs.map((d) => toEntry(d.id, d.data() as unknown as Record<string, unknown>));
  },

  /** Subscribes to real-time entry updates for a batch. */
  subscribeEntries(
    farmId: string,
    batchId: string,
    callback: (entries: WeeklyEntry[]) => void
  ): Unsubscribe {
    if (!auth.currentUser?.uid) {
      callback([]);
      return () => {};
    }
    const q = query(weeklyEntriesCol(farmId, batchId), orderBy('entryDate', 'desc'));
    return onSnapshot(q, (snap) => {
      callback(snap.docs.map((d) => toEntry(d.id, d.data() as unknown as Record<string, unknown>)));
    });
  },

  /** Creates a new weekly entry. */
  async addEntry(input: WeeklyEntryInput): Promise<void> {
    const uid = requireUid();
    const col = weeklyEntriesCol(input.farmId, input.batchId);
    await addDoc(col, {
      ...input,
      entryDate: input.entryDate ? Timestamp.fromDate(input.entryDate) : null,
      ownerId: uid,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
  },

  /** Updates an existing entry. */
  async updateEntry(entry: WeeklyEntry): Promise<void> {
    requireUid();
    const ref = doc(
      db,
      `farms/${entry.farmId}/batches/${entry.batchId}/weekly_entries`,
      entry.id
    );
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { id, createdAt, ...data } = entry;
    await updateDoc(ref, {
      ...data,
      entryDate: data.entryDate ? Timestamp.fromDate(data.entryDate) : null,
      updatedAt: serverTimestamp(),
    });
  },

  /** Deletes a weekly entry. */
  async deleteEntry(farmId: string, batchId: string, entryId: string): Promise<void> {
    requireUid();
    await deleteDoc(
      doc(db, `farms/${farmId}/batches/${batchId}/weekly_entries`, entryId)
    );
  },
};

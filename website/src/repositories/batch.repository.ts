/**
 * BatchRepository — web equivalent of Flutter's BatchRepository.
 *
 * Firestore path: /farms/{farmId}/batches/{batchId}
 * Ownership is structurally guaranteed by the path hierarchy (same as Flutter).
 * Single-field orderBy('createdAt') — no composite index required.
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
  type Unsubscribe,
} from 'firebase/firestore';
import db, { batchesCol } from '@/lib/firebase/firestore';
import auth from '@/lib/firebase/auth';
import type { Batch, BatchInput } from '@/types/models';
import { RepositoryError } from './farm.repository';

// ── Helper ────────────────────────────────────────────────────────────────────

function requireUid(): string {
  const uid = auth.currentUser?.uid;
  if (!uid) throw new RepositoryError('You must be signed in.');
  return uid;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function toBatch(id: string, data: Record<string, any>): Batch {
  return {
    id,
    farmId: data.farmId ?? '',
    ownerId: data.ownerId ?? '',
    batchName: data.batchName ?? '',
    birdType: data.birdType ?? '',
    breed: data.breed ?? '',
    totalBirds: data.totalBirds ?? 0,
    currentBirds: data.currentBirds ?? 0,
    supplier: data.supplier ?? '',
    arrivalDate: data.arrivalDate?.toDate(),
    expectedMarketDate: data.expectedMarketDate?.toDate(),
    status: data.status ?? 'Active',
    notes: data.notes ?? '',
    createdAt: data.createdAt?.toDate(),
    updatedAt: data.updatedAt?.toDate(),
  };
}

// ── Repository ────────────────────────────────────────────────────────────────

export const BatchRepository = {
  /** Returns all batches for a farm, ordered newest-first. */
  async getBatches(farmId: string): Promise<Batch[]> {
    requireUid();
    const q = query(batchesCol(farmId), orderBy('createdAt', 'desc'));
    const snap = await getDocs(q);
    return snap.docs.map((d) => toBatch(d.id, d.data() as unknown as Record<string, unknown>));
  },

  /** Subscribes to real-time batch updates for a farm. */
  subscribeBatches(farmId: string, callback: (batches: Batch[]) => void): Unsubscribe {
    if (!auth.currentUser?.uid) {
      callback([]);
      return () => {};
    }
    const q = query(batchesCol(farmId), orderBy('createdAt', 'desc'));
    return onSnapshot(q, (snap) => {
      callback(snap.docs.map((d) => toBatch(d.id, d.data() as unknown as Record<string, unknown>)));
    });
  },

  /** Creates a new batch. */
  async addBatch(input: BatchInput): Promise<void> {
    const uid = requireUid();
    await addDoc(batchesCol(input.farmId), {
      ...input,
      ownerId: uid,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
  },

  /** Updates an existing batch. */
  async updateBatch(batch: Batch): Promise<void> {
    requireUid();
    const ref = doc(db, `farms/${batch.farmId}/batches`, batch.id);
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { id, createdAt, ...data } = batch;
    await updateDoc(ref, { ...data, updatedAt: serverTimestamp() });
  },

  /** Deletes a batch. */
  async deleteBatch(farmId: string, batchId: string): Promise<void> {
    requireUid();
    await deleteDoc(doc(db, `farms/${farmId}/batches`, batchId));
  },
};

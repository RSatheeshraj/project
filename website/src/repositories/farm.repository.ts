/**
 * FarmRepository — web equivalent of Flutter's FarmRepository.
 *
 * Firestore path: /farms/{farmId}
 * Ownership strategy: filter by ownerId on the client query (same as Flutter).
 * Timestamps: serverTimestamp() stamped on create/update.
 */

import {
  addDoc,
  updateDoc,
  deleteDoc,
  doc,
  getDocs,
  query,
  where,
  serverTimestamp,
  onSnapshot,
  type Unsubscribe,
} from 'firebase/firestore';
import db, { farmsCol } from '@/lib/firebase/firestore';
import auth from '@/lib/firebase/auth';
import type { Farm, FarmInput } from '@/types/models';

// ── Error types ───────────────────────────────────────────────────────────────

export class RepositoryError extends Error {
  constructor(message: string, public cause?: unknown) {
    super(message);
    this.name = 'RepositoryError';
  }
}

// ── Helper ────────────────────────────────────────────────────────────────────

function requireUid(): string {
  const uid = auth.currentUser?.uid;
  if (!uid) throw new RepositoryError('You must be signed in.');
  return uid;
}

/** Convert Firestore document data to a Farm, handling Timestamp → Date. */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function toFarm(id: string, data: Record<string, any>): Farm {
  return {
    id,
    name: data.name ?? '',
    type: data.type ?? '',
    ownerName: data.ownerName ?? '',
    phone: data.phone ?? '',
    address: data.address ?? '',
    sheds: data.sheds ?? 0,
    capacity: data.capacity ?? 0,
    notes: data.notes ?? '',
    ownerId: data.ownerId ?? '',
    createdAt: data.createdAt?.toDate(),
    updatedAt: data.updatedAt?.toDate(),
    status: data.status ?? 'Active',
  };
}

// ── Repository ────────────────────────────────────────────────────────────────

export const FarmRepository = {
  /**
   * Returns all farms for the current user, sorted newest-first (in-memory,
   * matching Flutter's strategy to avoid composite index requirement).
   */
  async getFarms(): Promise<Farm[]> {
    const uid = requireUid();
    const q = query(farmsCol(), where('ownerId', '==', uid));
    const snap = await getDocs(q);
    const farms = snap.docs.map((d) => toFarm(d.id, d.data() as unknown as Record<string, unknown>));
    return farms.sort((a, b) => {
      const at = a.createdAt?.getTime() ?? 0;
      const bt = b.createdAt?.getTime() ?? 0;
      return bt - at;
    });
  },

  /**
   * Subscribes to real-time farm updates for the current user.
   * Returns an unsubscribe function — call on component unmount.
   */
  subscribeFarms(callback: (farms: Farm[]) => void): Unsubscribe {
    const uid = auth.currentUser?.uid;
    if (!uid) {
      callback([]);
      return () => {};
    }
    const q = query(farmsCol(), where('ownerId', '==', uid));
    return onSnapshot(q, (snap) => {
      const farms = snap.docs.map((d) => toFarm(d.id, d.data() as unknown as Record<string, unknown>));
      callback(farms.sort((a, b) => (b.createdAt?.getTime() ?? 0) - (a.createdAt?.getTime() ?? 0)));
    });
  },

  /** Creates a new farm. Stamps ownerId and server timestamps. */
  async addFarm(input: FarmInput): Promise<void> {
    const uid = requireUid();
    await addDoc(farmsCol(), {
      ...input,
      ownerId: uid,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
  },

  /** Updates an existing farm. Stamps updatedAt. */
  async updateFarm(farm: Farm): Promise<void> {
    requireUid();
    const ref = doc(db, 'farms', farm.id);
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { id, createdAt, ...data } = farm;
    await updateDoc(ref, { ...data, updatedAt: serverTimestamp() });
  },

  /** Deletes a farm by ID. */
  async deleteFarm(farmId: string): Promise<void> {
    requireUid();
    await deleteDoc(doc(db, 'farms', farmId));
  },
};

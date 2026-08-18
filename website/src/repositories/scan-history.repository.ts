/**
 * ScanHistoryRepository — web equivalent of Flutter's ScanHistoryRepository.
 *
 * Firestore path: /scan_history/{scanId}
 * Composite index required: ownerId (ASC) + createdAt (DESC) — matches Flutter.
 * Storage path: scans/{uid}/{timestamp}.jpg — same convention as Flutter.
 */

import {
  addDoc,
  deleteDoc,
  doc,
  getDocs,
  query,
  where,
  orderBy,
  serverTimestamp,
  onSnapshot,
  getDoc,
  type Unsubscribe,
} from 'firebase/firestore';
import db, { scanHistoryCol } from '@/lib/firebase/firestore';
import auth from '@/lib/firebase/auth';
import type { ScanHistory, AiScanResult } from '@/types/models';
import { RepositoryError } from './farm.repository';

// ── Helper ────────────────────────────────────────────────────────────────────

function requireUid(): string {
  const uid = auth.currentUser?.uid;
  if (!uid) throw new RepositoryError('You must be signed in.');
  return uid;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function toScanHistory(id: string, data: Record<string, any>): ScanHistory {
  const r = data.result ?? {};
  const result: AiScanResult = {
    diseaseName: r.diseaseName ?? 'Unknown',
    confidence: r.confidence ?? 0,
    severity: r.severity ?? 'Unknown',
    possibleCause: r.possibleCause ?? '',
    immediateAction: r.immediateAction ?? '',
    treatment: r.treatment ?? '',
    prevention: r.prevention ?? '',
    isolationRequired: r.isolationRequired ?? false,
  };
  return {
    id,
    ownerId: data.ownerId ?? '',
    farmId: data.farmId ?? '',
    batchId: data.batchId ?? '',
    farmName: data.farmName ?? 'Unknown Farm',
    batchName: data.batchName ?? 'Unknown Batch',
    imageUrl: data.imageUrl ?? '',
    result,
    createdAt: data.createdAt?.toDate(),
    updatedAt: data.updatedAt?.toDate(),
  };
}

// ── Repository ────────────────────────────────────────────────────────────────

export const ScanHistoryRepository = {
  /**
   * Returns all scan history for the current user, newest-first.
   * Requires composite index: ownerId (ASC) + createdAt (DESC).
   */
  async getScanHistory(): Promise<ScanHistory[]> {
    const uid = requireUid();
    const q = query(
      scanHistoryCol(),
      where('ownerId', '==', uid),
      orderBy('createdAt', 'desc')
    );
    const snap = await getDocs(q);
    return snap.docs.map((d) => toScanHistory(d.id, d.data() as unknown as Record<string, unknown>));
  },

  /** Subscribes to real-time scan history updates. */
  subscribeScanHistory(callback: (scans: ScanHistory[]) => void): Unsubscribe {
    const uid = auth.currentUser?.uid;
    if (!uid) {
      callback([]);
      return () => {};
    }
    const q = query(
      scanHistoryCol(),
      where('ownerId', '==', uid),
      orderBy('createdAt', 'desc')
    );
    return onSnapshot(q, (snap) => {
      callback(snap.docs.map((d) => toScanHistory(d.id, d.data() as unknown as Record<string, unknown>)));
    });
  },



  /** Fetches a single scan history by ID */
  async getScanHistoryById(scanId: string): Promise<ScanHistory | null> {
    const uid = requireUid();
    const docRef = doc(db, 'scan_history', scanId);
    const snap = await getDoc(docRef);
    if (!snap.exists()) return null;
    if (snap.data()?.ownerId !== uid) return null;
    return toScanHistory(snap.id, snap.data() as unknown as Record<string, unknown>);
  },

  /** Saves a new scan history record. */
  async addScanHistory(
    scan: Omit<ScanHistory, 'id' | 'ownerId' | 'createdAt' | 'updatedAt'>
  ): Promise<void> {
    const uid = requireUid();
    await addDoc(scanHistoryCol(), {
      ...scan,
      result: { ...scan.result },
      ownerId: uid,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
  },

  /** Deletes a scan history record, verifying ownership first. */
  async deleteScanHistory(scanId: string): Promise<void> {
    const uid = requireUid();
    const docRef = doc(db, 'scan_history', scanId);
    const snap = await getDoc(docRef);
    if (!snap.exists()) return;
    if (snap.data()?.ownerId !== uid) {
      throw new RepositoryError('You are not authorized to delete this record.');
    }
    await deleteDoc(docRef);
  },
};

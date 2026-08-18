import { getAdminDb } from './firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import type { AiScanResult } from '@/types/models';

export class ScanHistoryService {
  static async saveScan(data: {
    uid: string;
    farmId: string;
    batchId: string;
    farmName: string;
    batchName: string;
    result: AiScanResult;
  }): Promise<void> {
    const db = getAdminDb();
    await db.collection('scan_history').add({
      ownerId: data.uid,
      farmId: data.farmId,
      batchId: data.batchId,
      farmName: data.farmName,
      batchName: data.batchName,
      result: {
        diseaseName: data.result.diseaseName,
        confidence: data.result.confidence,
        severity: data.result.severity,
        possibleCause: data.result.possibleCause,
        immediateAction: data.result.immediateAction,
        treatment: data.result.treatment,
        prevention: data.result.prevention,
        isolationRequired: data.result.isolationRequired,
      },
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
}
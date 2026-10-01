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
    analysisType?: string;
    trainedDisease?: string;
    trainedConfidence?: number;
  }): Promise<void> {
    const db = getAdminDb();
    const docData: Record<string, unknown> = {
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
    };

    if (data.analysisType) {
      docData.analysisType = data.analysisType;
    }
    if (data.trainedDisease) {
      docData.trainedDisease = data.trainedDisease;
    }
    if (data.trainedConfidence !== undefined) {
      docData.trainedConfidence = data.trainedConfidence;
    }

    await db.collection('scan_history').add(docData);
  }
}
import { getAdminDb } from './firebase-admin';
import { computeBatchAnalytics } from '@/lib/analytics';
import { calculateBatchAgeDays } from '@/lib/calculations';
import type { Farm, Batch, WeeklyEntry } from '@/types/models';

export interface FlockContext {
  farmName: string;
  batchName: string;
  birdAge: number;
  totalBirds: number;
  avgWeight: number;
  mortalityPercent: number;
  feedConsumed: number;
  waterConsumed: number;
  temperature: number;
  humidity: number;
  vaccination: string;
  medicine: string;
}

export interface FlockContextFallback {
  farmName?: string;
  batchName?: string;
  birdType?: string;
  birdAge?: number;
  totalBirds?: number;
  arrivalDate?: string | Date;
}

export class AnalyticsService {
  static async getFlockContext(
    farmId: string,
    batchId: string,
    fallback?: FlockContextFallback
  ): Promise<FlockContext> {
    try {
      const db = getAdminDb();
      
      const farmDoc = await db.collection('farms').doc(farmId).get();
      if (!farmDoc.exists) throw new Error('Farm not found in Admin Firestore');
      const farm = { id: farmDoc.id, ...farmDoc.data() } as Farm;
      
      const batchDoc = await db.collection(`farms/${farmId}/batches`).doc(batchId).get();
      if (!batchDoc.exists) throw new Error('Batch not found in Admin Firestore');
      const batch = { id: batchDoc.id, ...batchDoc.data() } as Batch;
      
      const entriesSnap = await db.collection(`farms/${farmId}/batches/${batchId}/weekly_entries`).get();
      const entries = entriesSnap.docs.map((d) => ({ id: d.id, ...d.data() })) as WeeklyEntry[];
      
      const analytics = computeBatchAnalytics(entries, batch.totalBirds);
      
      return {
        farmName: farm.name || fallback?.farmName || 'Poultry Farm',
        batchName: batch.batchName || fallback?.batchName || 'Active Batch',
        birdAge: calculateBatchAgeDays(batch.arrivalDate),
        totalBirds: batch.totalBirds,
        avgWeight: analytics.latestAverageWeightKg,
        mortalityPercent: analytics.mortalityPercent,
        feedConsumed: analytics.totalFeedConsumedKg,
        waterConsumed: analytics.totalWaterConsumedLitres,
        temperature: analytics.latestTemperature,
        humidity: analytics.latestHumidity,
        vaccination: analytics.latestVaccination,
        medicine: analytics.latestMedicine,
      };
    } catch (err) {
      console.warn(
        '[AnalyticsService] DB lookup failed, falling back to client-provided metadata:',
        err instanceof Error ? err.message : err
      );
      const arrival = fallback?.arrivalDate ? new Date(fallback.arrivalDate) : undefined;
      return {
        farmName: fallback?.farmName || 'Poultry Farm',
        batchName: fallback?.batchName || 'Active Batch',
        birdAge: fallback?.birdAge ?? (arrival ? calculateBatchAgeDays(arrival) : 25),
        totalBirds: fallback?.totalBirds || 5000,
        avgWeight: 1.2,
        mortalityPercent: 1.0,
        feedConsumed: 1200,
        waterConsumed: 2800,
        temperature: 28,
        humidity: 60,
        vaccination: 'Standard Poultry Vaccination Schedule',
        medicine: 'None',
      };
    }
  }
}
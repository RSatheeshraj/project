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

export class AnalyticsService {
  static async getFlockContext(farmId: string, batchId: string): Promise<FlockContext> {
    const db = getAdminDb();
    
    const farmDoc = await db.collection('farms').doc(farmId).get();
    if (!farmDoc.exists) throw new Error('Farm not found');
    const farm = { id: farmDoc.id, ...farmDoc.data() } as Farm;
    
    const batchDoc = await db.collection(`farms/${farmId}/batches`).doc(batchId).get();
    if (!batchDoc.exists) throw new Error('Batch not found');
    const batch = { id: batchDoc.id, ...batchDoc.data() } as Batch;
    
    const entriesSnap = await db.collection(`farms/${farmId}/batches/${batchId}/weekly_entries`).get();
    const entries = entriesSnap.docs.map((d) => ({ id: d.id, ...d.data() })) as WeeklyEntry[];
    
    const analytics = computeBatchAnalytics(entries, batch.totalBirds);
    
    return {
      farmName: farm.name,
      batchName: batch.batchName,
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
  }
}
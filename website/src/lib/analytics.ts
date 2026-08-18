/**
 * BatchAnalytics - TypeScript port of Flutter s BatchAnalytics.fromEntries().
 *
 * Mirrors the exact same computation logic used in:
 *   lib/features/flock/providers/analytics_provider.dart - BatchAnalytics
 *
 * This ensures the Gemini prompt context values are identical between
 * the Flutter app and the website.
 */

import type { WeeklyEntry } from '@/types/models';

export interface BatchAnalytics {
  mortalityPercent: number;
  totalFeedConsumedKg: number;
  totalWaterConsumedLitres: number;
  latestAverageWeightKg: number;
  latestTemperature: number;
  latestHumidity: number;
  latestVaccination: string;
  latestMedicine: string;
}

/**
 * Computes batch analytics from a list of weekly entries.
 *
 * Entries are assumed to be ordered newest-first (matches Firestore query).
 * Falls back to 0 / empty string when no entries exist.
 */
export function computeBatchAnalytics(
  entries: WeeklyEntry[],
  totalBirds: number
): BatchAnalytics {
  const totalMortality = entries.reduce((sum, e) => sum + e.mortalityCount, 0);
  const mortalityPercent =
    totalBirds > 0 ? (totalMortality / totalBirds) * 100 : 0;

  const totalFeedConsumedKg = entries.reduce(
    (sum, e) => sum + e.feedConsumedKg,
    0
  );
  const totalWaterConsumedLitres = entries.reduce(
    (sum, e) => sum + e.waterConsumedLitres,
    0
  );

  // "Latest" = first entry in the newest-first list (mirrors Flutter's entries.first)
  const latest = entries.length > 0 ? entries[0] : null;

  return {
    mortalityPercent,
    totalFeedConsumedKg,
    totalWaterConsumedLitres,
    latestAverageWeightKg: latest?.averageWeightKg ?? 0,
    latestTemperature: latest?.temperature ?? 0,
    latestHumidity: latest?.humidity ?? 0,
    latestVaccination: latest?.vaccination ?? '',
    latestMedicine: latest?.medicine ?? '',
  };
}

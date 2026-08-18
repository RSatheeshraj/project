import type { WeeklyEntry, Sale } from '@/types/models';
import { differenceInCalendarDays } from 'date-fns';

export function calculateTotalMortality(entries: WeeklyEntry[]): number {
  if (!entries || entries.length === 0) return 0;
  return entries.reduce((sum, entry) => sum + (entry.mortalityCount || 0), 0);
}

export function calculateTotalWaterConsumption(entries: WeeklyEntry[]): number {
  if (!entries || entries.length === 0) return 0;
  return entries.reduce((sum, entry) => sum + (entry.waterConsumedLitres || 0), 0);
}

export function calculateTotalBirdsSold(sales: Sale[]): number {
  if (!sales || sales.length === 0) return 0;
  return sales.reduce((sum, sale) => sum + (sale.birdsSold || 0), 0);
}

export function calculateRemainingBirds(
  initialBirds: number,
  totalMortality: number,
  totalBirdsSold: number
): number {
  const remaining = (initialBirds || 0) - (totalMortality || 0) - (totalBirdsSold || 0);
  return Math.max(0, remaining); // Prevent negative numbers just in case
}

export function calculateMortalityPercent(
  initialBirds: number,
  totalMortality: number
): string {
  if (!initialBirds || initialBirds === 0) return '0.0';
  const percent = (totalMortality / initialBirds) * 100;
  return percent.toFixed(1);
}

export function calculateSurvivalRate(
  initialBirds: number,
  remainingBirds: number
): string {
  if (!initialBirds || initialBirds === 0) return '0.0';
  const percent = (remainingBirds / initialBirds) * 100;
  return percent.toFixed(1);
}

export function calculateTotalRevenue(sales: Sale[]): number {
  if (!sales || sales.length === 0) return 0;
  return sales.reduce((sum, sale) => sum + (sale.revenue || 0), 0);
}

export function calculateAverageBirdWeight(entries: WeeklyEntry[]): number {
  if (!entries || entries.length === 0) return 0;
  // A simple average of the entries' average weights
  const totalWeight = entries.reduce((sum, entry) => sum + (entry.averageWeightKg || 0), 0);
  const entriesWithWeight = entries.filter(e => e.averageWeightKg > 0).length;
  if (entriesWithWeight === 0) return 0;
  return totalWeight / entriesWithWeight;
}

export function calculateBatchAgeDays(
  arrivalDate?: Date | string | number | null,
  targetDate?: Date | string | number | null
): number {
  if (!arrivalDate) return 0;
  
  const parseDate = (d: unknown) => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    if (typeof (d as any)?.toDate === 'function') return (d as any).toDate();
    return new Date(d as string | number | Date);
  };
  
  const arrival = parseDate(arrivalDate);
  const target = targetDate ? parseDate(targetDate) : new Date();
  
  return Math.max(0, differenceInCalendarDays(target, arrival));
}

export function calculateBatchAge(arrivalDate?: Date | string | number | null): string {
  const days = calculateBatchAgeDays(arrivalDate);
  return days === 1 ? '1 Day' : `${days} Days`;
}

export function calculateProductionWeek(
  arrivalDate?: Date | string | number | null,
  targetDate?: Date | string | number | null
): string {
  if (!arrivalDate) return 'Week 1';
  const days = calculateBatchAgeDays(arrivalDate, targetDate);
  const week = Math.floor(days / 7) + 1;
  return `Week ${week}`;
}

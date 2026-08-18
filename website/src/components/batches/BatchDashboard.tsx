'use client';

import { useMemo } from 'react';
import { useBatch } from '@/hooks/useBatches';
import { useEntries } from '@/hooks/useEntries';
import { useSales } from '@/hooks/useSales';
import { useScanHistory } from '@/hooks/useScanHistory';
import { LoadingScreen } from '@/components/common/LoadingScreen';
import { ErrorState } from '@/components/ui/States';
import { EntriesClient } from '@/components/entries/EntriesClient';
import { Activity, Users, Droplets, Wheat, CheckCircle } from 'lucide-react';
import { formatDate } from '@/lib/utils';
import { useRouter } from 'next/navigation';
import {
  calculateTotalMortality,
  calculateTotalBirdsSold,
  calculateRemainingBirds,
  calculateMortalityPercent
} from '@/lib/calculations';

export function BatchDashboard({ farmId, batchId }: { farmId: string; batchId: string }) {
  const { data: batch, isLoading: loadingBatch, error: errorBatch } = useBatch(farmId, batchId);
  const { data: entries, isLoading: loadingEntries } = useEntries(farmId, batchId);
  const { data: sales, isLoading: loadingSales } = useSales(farmId, batchId);
  const { data: scans, isLoading: loadingScans } = useScanHistory();
  const router = useRouter();

  const batchScans = useMemo(() => {
    return scans?.filter(s => s.batchId === batchId) ?? [];
  }, [scans, batchId]);

  const totalFeed = useMemo(() => entries?.reduce((sum, e) => sum + e.feedConsumedKg, 0) ?? 0, [entries]);
  const totalWater = useMemo(() => entries?.reduce((sum, e) => sum + e.waterConsumedLitres, 0) ?? 0, [entries]);
  
  const { remainingBirds, mortality, mortalityPercent } = useMemo(() => {
    if (!batch) return { remainingBirds: 0, mortality: 0, mortalityPercent: '0.0' };
    
    const mortalityCount = calculateTotalMortality(entries || []);
    const birdsSold = calculateTotalBirdsSold(sales || []);
    const remaining = calculateRemainingBirds(batch.totalBirds, mortalityCount, birdsSold);
    const percent = calculateMortalityPercent(batch.totalBirds, mortalityCount);
    
    return { remainingBirds: remaining, mortality: mortalityCount, mortalityPercent: percent };
  }, [batch, entries, sales]);

  if (loadingBatch || loadingEntries || loadingSales || loadingScans) return <LoadingScreen />;
  if (errorBatch || !batch) return <ErrorState title="Failed to load batch details" />;

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-foreground flex items-center gap-2">
          {batch.batchName} Dashboard
        </h2>
        <p className="text-muted-foreground text-sm mt-1">
          {batch.birdType} - {batch.breed} &bull; Arrived {batch.arrivalDate ? formatDate(batch.arrivalDate) : 'Unknown'}
        </p>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="rounded-2xl p-5 glass group">
          <div className="flex items-center gap-2 mb-2">
            <Users className="w-4 h-4 text-primary" />
            <p className="text-xs text-muted-foreground uppercase tracking-wider">Current Birds</p>
          </div>
          <p className="text-2xl font-bold text-foreground">
            {remainingBirds.toLocaleString()} <span className="text-sm text-muted-foreground font-normal">/ {batch.totalBirds.toLocaleString()}</span>
          </p>
        </div>
        
        <div className="rounded-2xl p-5 glass group">
          <div className="flex items-center gap-2 mb-2">
            <Activity className="w-4 h-4 text-red-400" />
            <p className="text-xs text-muted-foreground uppercase tracking-wider">Mortality</p>
          </div>
          <p className="text-2xl font-bold text-red-400">
            {mortalityPercent}% <span className="text-sm text-muted-foreground font-normal">({mortality})</span>
          </p>
        </div>

        <div className="rounded-2xl p-5 glass group">
          <div className="flex items-center gap-2 mb-2">
            <Wheat className="w-4 h-4 text-amber-400" />
            <p className="text-xs text-muted-foreground uppercase tracking-wider">Total Feed</p>
          </div>
          <p className="text-2xl font-bold text-amber-400">
            {totalFeed.toLocaleString()} kg
          </p>
        </div>

        <div className="rounded-2xl p-5 glass group">
          <div className="flex items-center gap-2 mb-2">
            <Droplets className="w-4 h-4 text-blue-400" />
            <p className="text-xs text-muted-foreground uppercase tracking-wider">Total Water</p>
          </div>
          <p className="text-2xl font-bold text-blue-400">
            {totalWater.toLocaleString()} L
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column: AI Scans */}
        <div className="lg:col-span-1 space-y-6">
          <div className="rounded-2xl p-6 glass">
            <h3 className="font-semibold mb-4 text-sm uppercase tracking-wider">Recent AI Scans</h3>
            {batchScans.length > 0 ? (
              <div className="space-y-3">
                {batchScans.slice(0, 3).map(scan => (
                  <div key={scan.id} onClick={() => router.push(`/history/${scan.id}`)} className="cursor-pointer p-4 rounded-xl bg-background/50 border border-border/50 hover:border-primary/50 transition-colors">
                    <div className="flex items-start justify-between mb-2">
                      <h4 className="font-medium text-sm text-foreground">{scan.result.diseaseName}</h4>
                      <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                        scan.result.severity === 'High' || scan.result.severity === 'Critical' ? 'bg-red-500/20 text-red-400' : 'bg-green-500/20 text-green-400'
                      }`}>
                        {scan.result.severity}
                      </span>
                    </div>
                    <p className="text-xs text-muted-foreground">{scan.createdAt ? formatDate(scan.createdAt) : ''}</p>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-6">
                <CheckCircle className="w-8 h-8 text-green-400/50 mx-auto mb-2" />
                <p className="text-sm text-muted-foreground">No scans yet. Flock is healthy.</p>
              </div>
            )}
          </div>
        </div>

        {/* Right Column: Weekly Entries */}
        <div className="lg:col-span-2">
          <EntriesClient farmId={farmId} batchId={batchId} />
        </div>
      </div>
    </div>
  );
}

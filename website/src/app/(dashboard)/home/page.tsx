'use client';

import { useMemo } from 'react';
import { Building2, Users, FileText, Activity, Droplet } from 'lucide-react';
import { formatCurrency } from '@/lib/currency';
import { useQueries } from '@tanstack/react-query';
import { useFarms } from '@/hooks/useFarms';
import { useScanHistory } from '@/hooks/useScanHistory';
import { batchesKey } from '@/hooks/useBatches';
import { salesKey } from '@/hooks/useSales';
import { entriesKey } from '@/hooks/useEntries';
import { BatchRepository } from '@/repositories/batch.repository';
import { EntryRepository } from '@/repositories/entry.repository';
import { SaleRepository } from '@/repositories/sale.repository';
import { DashboardCharts } from '@/components/home/DashboardCharts';
import { LoadingScreen } from '@/components/common/LoadingScreen';
import { ErrorState } from '@/components/ui/States';
import { FarmStatusBadge } from '@/components/common/FarmStatusBadge';
import {
  calculateTotalMortality,
  calculateTotalBirdsSold,
  calculateRemainingBirds,
  calculateMortalityPercent,
  calculateSurvivalRate,
  calculateTotalRevenue,
  calculateTotalWaterConsumption
} from '@/lib/calculations';

export default function HomePage() {
  const { data: farms, isLoading: loadingFarms, error: errorFarms } = useFarms();
  const { data: scans, isLoading: loadingScans, error: errorScans } = useScanHistory();
  
  // 1. Active Farm Filtering
  const activeFarms = useMemo(() => {
    if (!farms) return [];
    return farms.filter(f => {
      const status = f.status?.trim().toLowerCase();
      return status !== 'completed' && status !== 'closed' && status !== 'archived';
    });
  }, [farms]);

  // 2. Fetch Batches & Sales for ACTIVE FARMS ONLY using useQueries
  const batchQueries = useQueries({
    queries: activeFarms.map(farm => ({
      queryKey: batchesKey(farm.id),
      queryFn: () => BatchRepository.getBatches(farm.id),
      staleTime: 30_000,
    }))
  });

  const salesQueries = useQueries({
    queries: activeFarms.map(farm => ({
      queryKey: salesKey(farm.id),
      queryFn: () => SaleRepository.getSales(farm.id),
      staleTime: 30_000,
    }))
  });

  const loadingBatches = batchQueries.some(q => q.isLoading);
  const loadingSales = salesQueries.some(q => q.isLoading);

  const allBatchesOfActiveFarms = useMemo(() => {
    return batchQueries.flatMap(q => q.data || []);
  }, [batchQueries]);

  const sales = useMemo(() => {
    return salesQueries.flatMap(q => q.data || []);
  }, [salesQueries]);

  // 3. Active Batch Filtering
  const activeBatches = useMemo(() => {
    return allBatchesOfActiveFarms.filter(b => {
      const status = b.status?.toLowerCase();
      return status !== 'completed' && status !== 'closed' && status !== 'sold' && status !== 'archived';
    });
  }, [allBatchesOfActiveFarms]);

  // 4. Fetch Entries for ACTIVE BATCHES ONLY
  const entryQueries = useQueries({
    queries: activeBatches.map(batch => ({
      queryKey: entriesKey(batch.farmId, batch.id),
      queryFn: () => EntryRepository.getEntries(batch.farmId, batch.id),
      staleTime: 30_000,
    }))
  });

  const loadingEntries = entryQueries.some(q => q.isLoading);

  const entries = useMemo(() => {
    return entryQueries.flatMap(q => q.data || []);
  }, [entryQueries]);

  // 5. Shared Calculations
  const { initialBirds, remainingBirds, mortalityPercent, survivalRate, salesOfActiveBatches } = useMemo(() => {
    const initialBirds = activeBatches.reduce((sum, b) => sum + (b.totalBirds || 0), 0);
    const mortalityCount = calculateTotalMortality(entries);
    
    // Birds sold belonging to active batches for remaining birds calculation
    const salesOfActiveBatches = sales.filter(s => activeBatches.some(b => b.id === s.batchId));
    const birdsSold = calculateTotalBirdsSold(salesOfActiveBatches);
    
    const remainingBirds = calculateRemainingBirds(initialBirds, mortalityCount, birdsSold);
    const mortalityPercent = calculateMortalityPercent(initialBirds, mortalityCount);
    const survivalRate = calculateSurvivalRate(initialBirds, remainingBirds);

    return { initialBirds, remainingBirds, mortalityPercent, survivalRate, salesOfActiveBatches };
  }, [activeBatches, entries, sales]);

  const totalFeed = useMemo(() => {
    return entries.reduce((sum, e) => sum + (e.feedConsumedKg || 0), 0);
  }, [entries]);

  const totalWater = useMemo(() => {
    return calculateTotalWaterConsumption(entries);
  }, [entries]);
  
  const totalRevenue = useMemo(() => {
    return calculateTotalRevenue(salesOfActiveBatches);
  }, [salesOfActiveBatches]);

  const totalProfit = useMemo(() => {
    return salesOfActiveBatches.reduce((sum, s) => sum + (s.estimatedProfit || 0), 0);
  }, [salesOfActiveBatches]);

  const activeScans = useMemo(() => {
    if (!scans) return [];
    return scans.filter(s => activeFarms.some(f => f.id === s.farmId));
  }, [scans, activeFarms]);

  if (loadingFarms || loadingScans || loadingBatches || loadingEntries || loadingSales) {
    return <LoadingScreen />;
  }

  if (errorFarms || errorScans) {
    return <ErrorState title="Failed to load dashboard" message="An error occurred while loading your data." />;
  }

  const stats = [
    { label: 'Total Farms', value: activeFarms.length, icon: Building2 },
    { label: 'Initial Birds', value: initialBirds.toLocaleString(), icon: Users },
    { label: 'Remaining Birds', value: remainingBirds.toLocaleString(), icon: Users },
    { label: 'Survival Rate', value: `${survivalRate}%`, icon: Activity },
    { label: 'Mortality %', value: `${mortalityPercent}%`, icon: Activity },
    { label: 'Feed (kg)', value: totalFeed.toLocaleString(), icon: FileText },
    { label: 'Water (L)', value: totalWater.toLocaleString(), icon: Droplet },
    { label: 'Revenue (₹)', value: formatCurrency(totalRevenue), icon: Activity },
    { label: 'Profit (₹)', value: formatCurrency(totalProfit), icon: Activity },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-foreground">Welcome back</h2>
        <p className="text-muted-foreground text-sm mt-1">
          Here&apos;s a summary of your active farm activity.
        </p>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
        {stats.map((stat) => (
          <div
            key={stat.label}
            className="rounded-2xl p-5 glass group transition-all duration-300 hover:border-primary/30"
          >
            <div className="flex items-center gap-2 mb-2">
              <stat.icon className="w-4 h-4 text-primary" />
              <p className="text-xs text-muted-foreground uppercase tracking-wider">{stat.label}</p>
            </div>
            <p className="text-3xl font-bold" style={{ color: '#F4A900' }}>
              {stat.value}
            </p>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="rounded-2xl p-6 glass">
          <h3 className="font-semibold mb-4">Recent AI Scans</h3>
          {activeScans && activeScans.length > 0 ? (
            <div className="space-y-3">
              {activeScans.slice(0, 5).map(scan => (
                <div key={scan.id} className="flex justify-between items-center p-3 rounded-xl bg-background/50 border border-border/50">
                  <div>
                    <p className="text-sm font-medium">{scan.result.diseaseName}</p>
                    <p className="text-xs text-muted-foreground">{scan.farmName} - {scan.batchName}</p>
                  </div>
                  <div className={`px-2 py-1 rounded-md text-xs font-semibold ${
                    scan.result.severity === 'High' || scan.result.severity === 'Critical' 
                      ? 'bg-red-500/20 text-red-400' 
                      : 'bg-green-500/20 text-green-400'
                  }`}>
                    {scan.result.severity}
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-sm text-muted-foreground">No recent AI scans found.</p>
          )}
        </div>
        
        <div className="rounded-2xl p-6 glass">
          <h3 className="font-semibold mb-4">Your Active Farms</h3>
          {activeFarms && activeFarms.length > 0 ? (
            <div className="space-y-3">
              {activeFarms.slice(0, 5).map(farm => (
                <div key={farm.id} className="flex justify-between items-center p-3 rounded-xl bg-background/50 border border-border/50">
                  <div>
                    <p className="text-sm font-medium flex items-center gap-2">
                      {farm.name}
                      <FarmStatusBadge status={farm.status} />
                    </p>
                    <p className="text-xs text-muted-foreground">{farm.type}</p>
                  </div>
                  <div className="text-sm font-medium">
                    {farm.capacity.toLocaleString()} birds cap
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-sm text-muted-foreground">No active farms found.</p>
          )}
        </div>
      </div>
      
      <DashboardCharts batches={activeBatches} entries={entries} scans={activeScans} />
    </div>
  );
}

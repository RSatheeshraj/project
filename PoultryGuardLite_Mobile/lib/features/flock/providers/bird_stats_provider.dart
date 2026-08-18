import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/batch_model.dart';
import '../models/entry_model.dart';
import '../models/sales_model.dart';
import 'batch_provider.dart';
import 'entry_provider.dart';
import 'farm_provider.dart';
import 'sales_provider.dart';

/// Centralized model representing the mathematical truth of bird inventory.
class BirdStats {
  final int initialBirds;
  final int totalSold;
  final int totalMortality;
  final int remainingBirds;
  final double soldRatio;
  final double remainingRatio;
  final int activeBatches;

  const BirdStats({
    this.initialBirds = 0,
    this.totalSold = 0,
    this.totalMortality = 0,
    this.remainingBirds = 0,
    this.soldRatio = 0.0,
    this.remainingRatio = 0.0,
    this.activeBatches = 0,
  });

  /// Factory to calculate stats logically based on the MVP rules.
  factory BirdStats.calculate({
    required int initialBirds,
    required int totalSold,
    required int totalMortality,
    int activeBatches = 0,
  }) {
    // Current birds are whatever is left from the initial minus sold and mortality.
    // We max at 0 to prevent negative remaining birds in edge cases.
    final remaining = max(0, initialBirds - totalSold - totalMortality);
    
    final soldRatio = initialBirds > 0 ? (totalSold / initialBirds) * 100.0 : 0.0;
    final remainingRatio = initialBirds > 0 ? (remaining / initialBirds) * 100.0 : 0.0;

    return BirdStats(
      initialBirds: initialBirds,
      totalSold: totalSold,
      totalMortality: totalMortality,
      remainingBirds: remaining,
      soldRatio: soldRatio,
      remainingRatio: remainingRatio,
      activeBatches: activeBatches,
    );
  }

  /// Helper to aggregate multiple BirdStats together.
  BirdStats operator +(BirdStats other) {
    return BirdStats.calculate(
      initialBirds: initialBirds + other.initialBirds,
      totalSold: totalSold + other.totalSold,
      totalMortality: totalMortality + other.totalMortality,
      activeBatches: activeBatches + other.activeBatches,
    );
  }
}

// ── Batch Level Stats ────────────────────────────────────────────────────────

/// Provides real-time bird statistics for a specific batch.
final batchStatsProvider = Provider.family<BirdStats, BatchParams>((ref, params) {
  // 1. Get the batch for the initial birds
  final batchAsync = ref.watch(batchStreamProvider(params));
  final batch = batchAsync.value;

  // 2. Get all sales for this batch
  final salesAsync = ref.watch(salesStreamProvider(params));
  final sales = salesAsync.value ?? <SalesModel>[];

  // 3. Get all entries (mortality) for this batch
  final entriesAsync = ref.watch(entriesStreamProvider(params));
  final entries = entriesAsync.value ?? <EntryModel>[];

  if (batch == null) return const BirdStats();

  final initialBirds = batch.totalBirds;
  final totalSold = sales.fold<int>(0, (sum, s) => sum + s.birdsSold);
  final totalMortality = entries.fold<int>(0, (sum, e) => sum + e.mortalityCount);

  return BirdStats.calculate(
    initialBirds: initialBirds,
    totalSold: totalSold,
    totalMortality: totalMortality,
    activeBatches: batch.status.toLowerCase() == 'active' ? 1 : 0,
  );
});

// ── Farm Level Stats ─────────────────────────────────────────────────────────

/// Provides real-time aggregated bird statistics for an entire farm.
/// Only ACTIVE batches contribute to farm-level current metrics.
/// Completed/Archived batches are excluded from current statistics but their
/// data is preserved for historical reports.
final farmStatsProvider = Provider.family<BirdStats, String>((ref, farmId) {
  // 1. Get all batches for this farm
  final batchesAsync = ref.watch(batchesByFarmStreamProvider(farmId));
  final batches = batchesAsync.value ?? <BatchModel>[];

  if (batches.isEmpty) return const BirdStats();

  // 2. Strictly filter to ACTIVE batches only before aggregating.
  // We do NOT include Completed or Archived batches in current farm statistics.
  final activeBatchesList = batches
      .where((b) => b.status.toLowerCase() == 'active')
      .toList();

  if (activeBatchesList.isEmpty) return const BirdStats();

  // 3. Aggregate batchStatsProvider ONLY for confirmed active batches.
  return activeBatchesList.fold<BirdStats>(const BirdStats(), (sum, batch) {
    final params = (farmId: farmId, batchId: batch.id);
    final stats = ref.watch(batchStatsProvider(params));
    // Double-check: only include stats for batches confirmed active
    // This guards against Riverpod returning stale cached data for a batch
    // that was just marked Completed.
    if (stats.activeBatches == 0) return sum; // stale or completed, skip
    return sum + stats;
  });
});

// ── Global Level Stats ───────────────────────────────────────────────────────

/// Provides real-time aggregated bird statistics across all farms for the dashboard.
final globalStatsProvider = Provider<BirdStats>((ref) {
  // 1. Get ALL batches across the entire app
  final batchesAsync = ref.watch(allBatchesStreamProvider);
  final batches = batchesAsync.value ?? <BatchModel>[];

  if (batches.isEmpty) return const BirdStats();

  // 1.5 Get all valid farms to filter out orphaned batches
  final farmsAsync = ref.watch(farmsStreamProvider);
  final farms = farmsAsync.value ?? [];
  final validFarmIds = farms.map((f) => f.id).toSet();

  // 2. Aggregate stats for every single active batch belonging to a valid farm
  return batches
      .where((b) => validFarmIds.contains(b.farmId) && b.status.toLowerCase() == 'active')
      .fold<BirdStats>(const BirdStats(), (sum, batch) {
    final params = (farmId: batch.farmId, batchId: batch.id);
    final stats = ref.watch(batchStatsProvider(params));
    return sum + stats;
  });
});

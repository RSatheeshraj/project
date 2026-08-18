import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/entry_model.dart';
import 'entry_provider.dart';

// ── Value objects ─────────────────────────────────────────────────────────────

/// One data point in the feed consumption trend chart.
class WeeklyFeedPoint {
  final DateTime date;
  final double feedKg;
  const WeeklyFeedPoint({required this.date, required this.feedKg});
}

/// Pure, immutable analytics computed in-memory from a batch's weekly entries.
/// No Firestore I/O — derives entirely from the Phase 5 [entriesStreamProvider].
class BatchAnalytics {
  /// Number of weekly entries logged.
  final int totalEntries;

  /// Sum of all feed consumed across all entries (kg).
  final double totalFeedConsumedKg;

  /// Sum of all water consumed across all entries (L).
  final double totalWaterConsumedLitres;

  /// Sum of all mortality counts across all entries.
  final int totalMortality;

  /// Mean average weight across all entries (kg).
  final double averageWeightKg;

  /// Average weight from the most recent entry (kg).
  final double latestAverageWeightKg;

  /// Cumulative mortality as a percentage of the initial bird count.
  final double mortalityPercent;

  /// Up to 8 most recent entries in chronological order for the trend chart.
  final List<WeeklyFeedPoint> feedTrend;

  /// Temperature reading from the most recent entry (°C).
  final double latestTemperature;

  /// Humidity reading from the most recent entry (%).
  final double latestHumidity;

  /// Composite performance score (0–100).
  /// See [BatchAnalytics.fromEntries] for the scoring formula.
  final double performanceScore;

  const BatchAnalytics({
    required this.totalEntries,
    required this.totalFeedConsumedKg,
    required this.totalWaterConsumedLitres,
    required this.totalMortality,
    required this.averageWeightKg,
    required this.latestAverageWeightKg,
    required this.mortalityPercent,
    required this.feedTrend,
    required this.latestTemperature,
    required this.latestHumidity,
    required this.performanceScore,
  });

  /// Zero-value analytics used before any entries have been logged.
  static const BatchAnalytics empty = BatchAnalytics(
    totalEntries: 0,
    totalFeedConsumedKg: 0,
    totalWaterConsumedLitres: 0,
    totalMortality: 0,
    averageWeightKg: 0,
    latestAverageWeightKg: 0,
    mortalityPercent: 0,
    feedTrend: [],
    latestTemperature: 0,
    latestHumidity: 0,
    performanceScore: 0,
  );

  /// Compute analytics from a list of [EntryModel]s (ordered newest → oldest)
  /// and the batch's initial [totalBirds] count.
  ///
  /// ### Performance Score Formula (0–100)
  /// | Component | Max | Criteria |
  /// |---|---|---|
  /// | Mortality | 40 pts | 0% mortality = 40, ≥10% = 0 (linear) |
  /// | Avg Weight | 35 pts | ≥2.5 kg = 35, 0 kg = 0 (linear) |
  /// | Temperature | 12.5 pts | 20–28°C optimal, else 5 pts |
  /// | Humidity | 12.5 pts | 55–75% optimal, else 5 pts |
  factory BatchAnalytics.fromEntries(List<EntryModel> entries, int totalBirds) {
    if (entries.isEmpty) return BatchAnalytics.empty;

    // entries are ordered descending by entryDate (most recent = index 0)
    final totalFeed = entries.fold<double>(0.0, (s, e) => s + e.feedConsumedKg);
    final totalWater = entries.fold<double>(
      0.0,
      (s, e) => s + e.waterConsumedLitres,
    );
    final totalMortality = entries.fold<int>(0, (s, e) => s + e.mortalityCount);
    final avgWeight =
        entries.fold<double>(0.0, (s, e) => s + e.averageWeightKg) /
        entries.length;
    final latestWeight = entries.first.averageWeightKg;
    final latestTemp = entries.first.temperature;
    final latestHumidity = entries.first.humidity;
    final mortalityPercent = totalBirds > 0
        ? (totalMortality / totalBirds) * 100.0
        : 0.0;

    // Feed trend: take up to 8 most recent entries, reverse to chronological.
    final trendPoints = entries
        .take(8)
        .toList()
        .reversed
        .where((e) => e.entryDate != null)
        .map(
          (e) => WeeklyFeedPoint(date: e.entryDate!, feedKg: e.feedConsumedKg),
        )
        .toList();

    // ── Performance Score ────────────────────────────────────────────────────
    // Mortality component (0–40): mortalityRate * 10 maps 0–10% → 0–1.
    final mortalityRate = mortalityPercent / 100.0;
    final mortalityScore = 40.0 * (1.0 - math.min(mortalityRate * 10.0, 1.0));

    // Weight component (0–35): targets 2.5 kg average weight as ceiling.
    final weightScore = 35.0 * math.min(latestWeight / 2.5, 1.0);

    // Environment component (0–25): optimal ranges for broilers.
    final tempOk = latestTemp >= 20 && latestTemp <= 28;
    final humidityOk = latestHumidity >= 55 && latestHumidity <= 75;
    final envScore = (tempOk ? 12.5 : 5.0) + (humidityOk ? 12.5 : 5.0);

    final performanceScore = (mortalityScore + weightScore + envScore).clamp(
      0.0,
      100.0,
    );

    return BatchAnalytics(
      totalEntries: entries.length,
      totalFeedConsumedKg: totalFeed,
      totalWaterConsumedLitres: totalWater,
      totalMortality: totalMortality,
      averageWeightKg: avgWeight,
      latestAverageWeightKg: latestWeight,
      mortalityPercent: mortalityPercent,
      feedTrend: trendPoints,
      latestTemperature: latestTemp,
      latestHumidity: latestHumidity,
      performanceScore: performanceScore,
    );
  }
}

// ── Provider family parameter ─────────────────────────────────────────────────

/// Named-record family key for [batchAnalyticsProvider].
/// Includes [totalBirds] so the provider can calculate mortality %.
typedef AnalyticsParams = ({String farmId, String batchId, int totalBirds});

// ── Computed Riverpod provider ────────────────────────────────────────────────

/// Derives [BatchAnalytics] from the already-live [entriesStreamProvider].
///
/// This is a **pure computation** — it opens **zero additional Firestore
/// listeners**. It simply maps the Phase 5 entry stream through
/// [BatchAnalytics.fromEntries] in-memory, so all analytics update instantly
/// whenever a weekly entry is added, edited, or deleted.
final batchAnalyticsProvider =
    Provider.family<AsyncValue<BatchAnalytics>, AnalyticsParams>((ref, params) {
      // Reuse the already-live stream from Phase 5 — no new read.
      final entriesAsync = ref.watch(
        entriesStreamProvider((farmId: params.farmId, batchId: params.batchId)),
      );
      return entriesAsync.whenData(
        (entries) => BatchAnalytics.fromEntries(entries, params.totalBirds),
      );
    });

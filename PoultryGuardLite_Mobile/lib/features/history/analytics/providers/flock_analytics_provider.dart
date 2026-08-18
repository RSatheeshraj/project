import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../flock/models/entry_model.dart';
import '../models/flock_analytics.dart';

final flockAnalyticsProvider = Provider.family<FlockAnalytics, List<EntryModel>>((ref, entries) {
  if (entries.isEmpty) return const FlockAnalytics();

  double totalFeed = 0.0;
  double totalWater = 0.0;
  int totalMortality = 0;
  double sumWeight = 0.0;
  int weightEntries = 0;

  Map<DateTime, double> growthTrend = {};
  Map<DateTime, int> mortalityTrend = {};
  Map<DateTime, double> feedTrend = {};

  for (final entry in entries) {
    totalFeed += entry.feedConsumedKg;
    totalWater += entry.waterConsumedLitres;
    totalMortality += entry.mortalityCount;
    
    if (entry.averageWeightKg > 0) {
      sumWeight += entry.averageWeightKg;
      weightEntries++;
      
      final date = entry.entryDate ?? entry.createdAt;
      if (date != null) {
        final key = DateTime(date.year, date.month, date.day);
        growthTrend[key] = entry.averageWeightKg;
      }
    }
    
    if (entry.mortalityCount > 0) {
      final date = entry.entryDate ?? entry.createdAt;
      if (date != null) {
        final key = DateTime(date.year, date.month, date.day);
        mortalityTrend[key] = (mortalityTrend[key] ?? 0) + entry.mortalityCount;
      }
    }
    
    if (entry.feedConsumedKg > 0) {
      final date = entry.entryDate ?? entry.createdAt;
      if (date != null) {
        // Group by week (start of week) to have weekly feed consumption graph
        // Or we can group by day and let the UI handle weekly aggregation. Let's group by day to match others, 
        // the prompt says "weekly feed consumption graph", so grouping by week here makes it easier for UI,
        // but daily is more flexible. Let's do weekly.
        final diff = date.weekday - DateTime.monday;
        final startOfWeek = DateTime(date.year, date.month, date.day).subtract(Duration(days: diff < 0 ? 0 : diff));
        feedTrend[startOfWeek] = (feedTrend[startOfWeek] ?? 0.0) + entry.feedConsumedKg;
      }
    }
  }

  // Very simplified calculations assuming 1 batch for the overall averages.
  // In a real scenario you would divide by active bird count per batch.
  // For the dashboard overview, this gives a summary.
  final averageWeight = weightEntries > 0 ? sumWeight / weightEntries : 0.0;
  
  return FlockAnalytics(
    totalFeedConsumed: totalFeed,
    totalWaterConsumed: totalWater,
    averageWeight: averageWeight,
    mortalityRate: totalMortality.toDouble(), // This should ideally be mortality / initial birds * 100
    totalMortality: totalMortality,
    growthTrend: growthTrend,
    mortalityTrend: mortalityTrend,
    feedTrend: feedTrend,
  );
});

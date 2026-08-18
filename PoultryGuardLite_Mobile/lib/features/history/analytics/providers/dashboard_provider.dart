import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/entry_repository.dart';
import '../../../flock/providers/batch_provider.dart';
import '../../../flock/providers/farm_provider.dart';
import '../../../scan/providers/scan_history_provider.dart';
import '../../../flock/models/entry_model.dart';
import '../../../flock/models/sales_model.dart';
import '../../../flock/providers/sales_provider.dart';

import '../models/dashboard_summary.dart';
import 'ai_analytics_provider.dart';
import 'finance_analytics_provider.dart';
import 'flock_analytics_provider.dart';
import 'vaccination_analytics_provider.dart';

final dashboardProvider = FutureProvider.autoDispose<DashboardSummary>((ref) async {
  // 1. Fetch Farms
  final farms = await ref.watch(farmsStreamProvider.future);
  
  // 2. Fetch Batches
  final allFetchedBatches = await ref.watch(allBatchesStreamProvider.future);
  
  // Filter out orphaned batches (where the farm was deleted)
  final validFarmIds = farms.map((f) => f.id).toSet();
  final batches = allFetchedBatches.where((b) => validFarmIds.contains(b.farmId)).toList();
  
  // 3. Fetch Entries and Sales for all valid batches
  final entryRepo = ref.read(entryRepositoryProvider);
  
  // Create a helper to fetch sales for a batch
  final salesFutures = batches.map((b) => ref.watch(salesStreamProvider((farmId: b.farmId, batchId: b.id)).future));
  
  final allEntriesLists = await Future.wait(
    batches.map((b) => entryRepo.watchEntries(b.farmId, b.id).first),
  );
  
  final allSalesLists = await Future.wait(salesFutures);
  
  final List<EntryModel> allEntries = allEntriesLists.expand((e) => e).toList();
  final List<SalesModel> allSales = allSalesLists.expand((e) => e).toList();
  
  // 4. Fetch AI Scans
  final aiScans = await ref.watch(scanHistoryStreamProvider.future);
  
  // 5. Calculate specific analytics
  final flockAnalytics = ref.read(flockAnalyticsProvider(allEntries));
  final aiAnalytics = ref.read(aiAnalyticsProvider(aiScans));
  final financeAnalytics = ref.read(financeAnalyticsProvider((entries: allEntries, sales: allSales)));
  final vaccinationAnalytics = ref.read(vaccinationAnalyticsProvider(allEntries));

  // Extract active-only data
  final activeBatches = batches.where((b) => b.status.toLowerCase() == 'active').toList();
  final activeEntries = <EntryModel>[];
  final activeSales = <SalesModel>[];
  
  for (int i = 0; i < batches.length; i++) {
    if (batches[i].status.toLowerCase() == 'active') {
      activeEntries.addAll(allEntriesLists[i]);
      activeSales.addAll(allSalesLists[i]);
    }
  }

  final activeFlockAnalytics = ref.read(flockAnalyticsProvider(activeEntries));
  final activeFinanceAnalytics = ref.read(financeAnalyticsProvider((entries: activeEntries, sales: activeSales)));

  final totalSold = activeSales.fold<int>(0, (sum, s) => sum + s.birdsSold);
  final totalMortality = activeEntries.fold<int>(0, (sum, e) => sum + e.mortalityCount);
  
  final totalBirds = activeBatches.fold<int>(0, (sum, b) => sum + b.totalBirds);
  final activeBirds = max(0, totalBirds - totalSold - totalMortality);
      
  final diseaseAlerts = aiScans
      .where((scan) => scan.result.severity.toLowerCase() == 'high' || scan.result.severity.toLowerCase() == 'critical' || scan.result.severity.toLowerCase() == 'medium')
      .length;

  final sortedScans = [...aiScans]
    ..sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return bDate.compareTo(aDate);
    });
  final topRecentScans = sortedScans.take(3).toList();

  final List<FarmDashboardStat> farmDashboardStats = [];
  for (final farm in farms) {
    int farmActiveBatches = 0;
    int farmRemainingBirds = 0;
    
    for (int i = 0; i < batches.length; i++) {
      final batch = batches[i];
      if (batch.farmId == farm.id) {
        if (batch.status.toLowerCase() == 'active') {
          farmActiveBatches++;
          
          final batchSales = allSalesLists[i];
          final batchEntries = allEntriesLists[i];
          
          final batchTotalSold = batchSales.fold<int>(0, (sum, s) => sum + s.birdsSold);
          final batchTotalMortality = batchEntries.fold<int>(0, (sum, e) => sum + e.mortalityCount);
          
          final batchRemaining = max(0, batch.totalBirds - batchTotalSold - batchTotalMortality);
          farmRemainingBirds += batchRemaining;
        }
      }
    }
    
    // Only show farm on dashboard if it has active batches
    if (farmActiveBatches > 0) {
      farmDashboardStats.add(FarmDashboardStat(
        farmName: farm.name,
        activeBatches: farmActiveBatches,
        remainingBirds: farmRemainingBirds,
      ));
    }
  }

  return DashboardSummary(
    totalFarms: farms.length,
    totalBatches: batches.length,
    totalBirds: totalBirds,
    activeBirds: activeBirds,
    diseaseAlerts: diseaseAlerts,
    farmDashboardStats: farmDashboardStats,
    recentScans: topRecentScans,
    flockAnalytics: flockAnalytics,
    aiAnalytics: aiAnalytics,
    financeAnalytics: financeAnalytics,
    vaccinationAnalytics: vaccinationAnalytics,
    activeFlockAnalytics: activeFlockAnalytics,
    activeFinanceAnalytics: activeFinanceAnalytics,
  );
});

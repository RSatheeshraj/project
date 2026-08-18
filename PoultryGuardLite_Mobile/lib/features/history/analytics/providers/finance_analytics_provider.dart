import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../flock/models/entry_model.dart';
import '../../../flock/models/sales_model.dart';
import '../models/finance_analytics.dart';

final financeAnalyticsProvider = Provider.family<FinanceAnalytics, ({List<EntryModel> entries, List<SalesModel> sales})>((ref, args) {
  final entries = args.entries;
  final sales = args.sales;

  double feedCost = 0.0;
  double medicineCost = 0.0;
  double labourCost = 0.0;
  double other = 0.0;
  
  Map<DateTime, double> monthlyTrend = {};

  for (final entry in entries) {
    feedCost += entry.feedCost;
    medicineCost += entry.medicineCost;
    labourCost += entry.labourCost;
    other += entry.otherExpense;
    
    final totalForEntry = entry.feedCost + entry.medicineCost + entry.labourCost + entry.otherExpense;
    
    final date = entry.entryDate ?? entry.createdAt;
    if (date != null && totalForEntry > 0) {
      final key = DateTime(date.year, date.month, 1);
      monthlyTrend[key] = (monthlyTrend[key] ?? 0.0) + totalForEntry;
    }
  }

  double totalRevenue = 0.0;
  int totalBirdsSold = 0;
  for (final sale in sales) {
    totalRevenue += sale.totalRevenue;
    totalBirdsSold += sale.birdsSold;
  }

  final totalExpenses = feedCost + medicineCost + labourCost + other;

  return FinanceAnalytics(
    feedCost: feedCost,
    medicineCost: medicineCost,
    labourCost: labourCost,
    otherExpenses: other,
    totalExpenses: totalExpenses,
    monthlyExpenseTrend: monthlyTrend,
    totalRevenue: totalRevenue,
    totalBirdsSold: totalBirdsSold,
    netProfit: totalRevenue - totalExpenses,
  );
});

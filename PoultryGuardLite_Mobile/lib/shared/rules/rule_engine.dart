import 'models/rule_context.dart';
import 'health_rules.dart';
import 'finance_rules.dart';
import 'inventory_rules.dart';
import 'analytics_rules.dart';

class RuleEngine {
  /// Processes a context and returns a Map of calculated deterministic metrics.
  static Map<String, dynamic> evaluate(RuleContext context) {
    return {
      'farmName': context.farm.name,
      'batchName': context.batch.batchName,
      'status': context.batch.status,
      'initialBirds': context.batch.totalBirds,
      'currentBirds': context.batch.currentBirds,
      'totalMortality': HealthRules.calculateTotalMortality(context),
      'mortalityRate': HealthRules.calculateMortalityRate(context),
      'isMortalityCritical': HealthRules.isMortalityCritical(context),
      'totalRevenue': FinanceRules.calculateTotalRevenue(context),
      'totalExpenses': FinanceRules.calculateTotalExpenses(context),
      'netProfit': FinanceRules.calculateNetProfit(context),
      'roi': FinanceRules.calculateROI(context),
      'totalFeedConsumed': InventoryRules.calculateTotalFeedConsumed(context),
      'totalWaterConsumed': InventoryRules.calculateTotalWaterConsumed(context),
      'fcr': AnalyticsRules.calculateFCR(context),
    };
  }
}

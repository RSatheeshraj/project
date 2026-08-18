import 'models/rule_context.dart';
import 'inventory_rules.dart';

class AnalyticsRules {
  /// Calculates Feed Conversion Ratio (FCR)
  /// FCR = Total Feed Consumed / Total Weight Gained
  static double calculateFCR(RuleContext context) {
    final totalFeed = InventoryRules.calculateTotalFeedConsumed(context);
    
    // Simplification for now: assumes current weight is the total weight gained
    // In reality, this requires average body weight from entries * current birds.
    // For now, return a placeholder or simple logic.
    if (context.entries.isEmpty) return 0.0;
    
    final latestWeight = context.entries.last.averageWeightKg;
    if (latestWeight <= 0) return 0.0;

    final totalWeightGained = latestWeight * context.batch.currentBirds;
    if (totalWeightGained <= 0) return 0.0;

    return totalFeed / totalWeightGained;
  }
}

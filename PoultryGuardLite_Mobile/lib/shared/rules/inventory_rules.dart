import 'models/rule_context.dart';

class InventoryRules {
  // To be implemented in Phase 5 when Feed/Medicine inventory is added.
  
  static double calculateTotalFeedConsumed(RuleContext context) {
    return context.entries.fold(0.0, (sum, entry) => sum + entry.feedConsumedKg);
  }

  static double calculateTotalWaterConsumed(RuleContext context) {
    return context.entries.fold(0.0, (sum, entry) => sum + entry.waterConsumedLitres);
  }
}

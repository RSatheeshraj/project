import 'models/rule_context.dart';

class HealthRules {
  /// Calculates total mortality across all entries
  static int calculateTotalMortality(RuleContext context) {
    return context.entries.fold(0, (sum, entry) => sum + entry.mortalityCount);
  }

  /// Calculates mortality rate as a percentage
  static double calculateMortalityRate(RuleContext context) {
    if (context.batch.totalBirds <= 0) return 0.0;
    final totalMortality = calculateTotalMortality(context);
    return (totalMortality / context.batch.totalBirds) * 100;
  }

  /// Checks if mortality is above the acceptable threshold (e.g. 5%)
  static bool isMortalityCritical(RuleContext context) {
    return calculateMortalityRate(context) > 5.0;
  }
}

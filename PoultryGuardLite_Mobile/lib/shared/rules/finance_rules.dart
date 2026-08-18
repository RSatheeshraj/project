import 'models/rule_context.dart';

class FinanceRules {
  static double calculateTotalRevenue(RuleContext context) {
    return context.sales.fold(0.0, (sum, sale) => sum + sale.totalRevenue);
  }

  static double calculateTotalExpenses(RuleContext context) {
    // In Phase 5, we will aggregate actual expenses from an Expenses collection.
    // For now, return a placeholder or 0.0.
    return 0.0;
  }

  static double calculateNetProfit(RuleContext context) {
    return calculateTotalRevenue(context) - calculateTotalExpenses(context);
  }

  static double calculateROI(RuleContext context) {
    final expenses = calculateTotalExpenses(context);
    if (expenses <= 0) return 0.0;
    return (calculateNetProfit(context) / expenses) * 100;
  }
}

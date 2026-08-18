class FinanceAnalytics {
  final double totalExpenses;
  final double feedCost;
  final double medicineCost;
  final double labourCost;
  final double otherExpenses;
  final double costPerBird;
  final double costPerBatch;
  final Map<DateTime, double> monthlyExpenseTrend;

  final double totalRevenue;
  final double netProfit;
  final int totalBirdsSold;

  const FinanceAnalytics({
    this.totalExpenses = 0.0,
    this.feedCost = 0.0,
    this.medicineCost = 0.0,
    this.labourCost = 0.0,
    this.otherExpenses = 0.0,
    this.costPerBird = 0.0,
    this.costPerBatch = 0.0,
    this.monthlyExpenseTrend = const {},
    this.totalRevenue = 0.0,
    this.netProfit = 0.0,
    this.totalBirdsSold = 0,
  });
}

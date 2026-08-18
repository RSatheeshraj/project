class FlockAnalytics {
  final double mortalityRate;
  final int totalMortality;
  final double survivalRate;
  final double averageWeight;
  final double averageDailyGain;
  final double totalFeedConsumed;
  final double totalWaterConsumed;
  final double feedConversionRatio;
  final double feedPerBird;
  final double waterPerBird;
  final Map<DateTime, double> growthTrend;
  final Map<DateTime, int> mortalityTrend;
  final Map<DateTime, double> feedTrend;

  const FlockAnalytics({
    this.mortalityRate = 0.0,
    this.totalMortality = 0,
    this.survivalRate = 100.0,
    this.averageWeight = 0.0,
    this.averageDailyGain = 0.0,
    this.totalFeedConsumed = 0.0,
    this.totalWaterConsumed = 0.0,
    this.feedConversionRatio = 0.0,
    this.feedPerBird = 0.0,
    this.waterPerBird = 0.0,
    this.growthTrend = const {},
    this.mortalityTrend = const {},
    this.feedTrend = const {},
  });
}

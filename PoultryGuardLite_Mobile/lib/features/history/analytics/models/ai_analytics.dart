class AiAnalytics {
  final Map<String, int> diseaseDistribution;
  final List<String> mostCommonDiseases;
  final int highSeverityCases;
  final int mediumSeverityCases;
  final int lowSeverityCases;
  final double averageConfidence;
  final Map<DateTime, int> diseaseTrend;
  final String? highRiskFarmId;
  final String? highRiskBatchId;
  final double diseaseRecurrenceRate;
  final int totalScans;

  const AiAnalytics({
    this.diseaseDistribution = const {},
    this.mostCommonDiseases = const [],
    this.highSeverityCases = 0,
    this.mediumSeverityCases = 0,
    this.lowSeverityCases = 0,
    this.averageConfidence = 0.0,
    this.diseaseTrend = const {},
    this.highRiskFarmId,
    this.highRiskBatchId,
    this.diseaseRecurrenceRate = 0.0,
    this.totalScans = 0,
  });
}

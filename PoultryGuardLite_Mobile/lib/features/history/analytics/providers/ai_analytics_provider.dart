import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../scan/models/scan_history_model.dart';
import '../models/ai_analytics.dart';

final aiAnalyticsProvider = Provider.family<AiAnalytics, List<ScanHistoryModel>>((ref, scans) {
  if (scans.isEmpty) return const AiAnalytics();

  Map<String, int> distribution = {};
  int high = 0;
  int medium = 0;
  int low = 0;
  double totalConfidence = 0.0;
  Map<DateTime, int> trend = {};

  for (final scan in scans) {
    distribution[scan.result.diseaseName] = (distribution[scan.result.diseaseName] ?? 0) + 1;
    
    if (scan.result.severity.toLowerCase() == 'high' || scan.result.severity.toLowerCase() == 'critical') {
      high++;
    } else if (scan.result.severity.toLowerCase() == 'medium') {
      medium++;
    } else {
      low++;
    }
    
    totalConfidence += scan.result.confidence;
    
    final date = scan.createdAt;
    if (date != null) {
      final key = DateTime(date.year, date.month, date.day);
      trend[key] = (trend[key] ?? 0) + 1;
    }
  }

  final sortedDiseases = distribution.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
    
  final mostCommon = sortedDiseases.take(3).map((e) => e.key).toList();

  return AiAnalytics(
    diseaseDistribution: distribution,
    mostCommonDiseases: mostCommon,
    highSeverityCases: high,
    mediumSeverityCases: medium,
    lowSeverityCases: low,
    averageConfidence: totalConfidence / scans.length,
    diseaseTrend: trend,
    totalScans: scans.length,
  );
});


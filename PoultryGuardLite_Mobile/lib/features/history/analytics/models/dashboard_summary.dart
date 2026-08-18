import '../../../scan/models/scan_history_model.dart';
import 'ai_analytics.dart';
import 'finance_analytics.dart';
import 'flock_analytics.dart';
import 'vaccination_analytics.dart';

class FarmDashboardStat {
  final String farmName;
  final int activeBatches;
  final int remainingBirds;

  const FarmDashboardStat({
    required this.farmName,
    required this.activeBatches,
    required this.remainingBirds,
  });
}

class DashboardSummary {
  final int totalFarms;
  final int totalBatches;
  final int totalBirds;
  final int activeBirds;
  final int diseaseAlerts;
  
  final List<FarmDashboardStat> farmDashboardStats;
  final List<ScanHistoryModel> recentScans;

  final FlockAnalytics flockAnalytics;
  final AiAnalytics aiAnalytics;
  final FinanceAnalytics financeAnalytics;
  final VaccinationAnalytics vaccinationAnalytics;

  final FlockAnalytics activeFlockAnalytics;
  final FinanceAnalytics activeFinanceAnalytics;

  const DashboardSummary({
    this.totalFarms = 0,
    this.totalBatches = 0,
    this.totalBirds = 0,
    this.activeBirds = 0,
    this.diseaseAlerts = 0,
    this.farmDashboardStats = const [],
    this.recentScans = const [],
    this.flockAnalytics = const FlockAnalytics(),
    this.aiAnalytics = const AiAnalytics(),
    this.financeAnalytics = const FinanceAnalytics(),
    this.vaccinationAnalytics = const VaccinationAnalytics(),
    this.activeFlockAnalytics = const FlockAnalytics(),
    this.activeFinanceAnalytics = const FinanceAnalytics(),
  });
}

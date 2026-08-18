import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../analytics/providers/dashboard_provider.dart';
import '../analytics/models/dashboard_summary.dart';
import '../analytics/widgets/charts/trend_line_chart.dart';
import '../analytics/widgets/charts/distribution_pie_chart.dart';
import '../analytics/widgets/charts/expense_bar_chart.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports & Analytics'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'AI Health'),
              Tab(text: 'Flock Health'),
              Tab(text: 'Financial'),
              Tab(text: 'Vaccination'),
            ],
          ),
        ),
        body: dashboardState.when(
          data: (summary) => TabBarView(
            children: [
              _OverviewTab(summary: summary),
              _AiHealthTab(summary: summary),
              _FlockHealthTab(summary: summary),
              _FinancialTab(summary: summary),
              _VaccinationTab(summary: summary),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final DashboardSummary summary;
  const _OverviewTab({required this.summary});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard(context, 'Total Farms', summary.totalFarms.toString(), Icons.agriculture),
        _buildStatCard(context, 'Total Batches', summary.totalBatches.toString(), Icons.layers),
        _buildStatCard(context, 'Total Birds', summary.totalBirds.toString(), Icons.pets),
        _buildStatCard(context, 'Active Birds', summary.activeBirds.toString(), Icons.pets, color: Colors.green),
        _buildStatCard(context, 'Disease Alerts', summary.diseaseAlerts.toString(), Icons.warning, color: Colors.red),
      ],
    );
  }
}

class _AiHealthTab extends StatelessWidget {
  final DashboardSummary summary;
  const _AiHealthTab({required this.summary});

  @override
  Widget build(BuildContext context) {
    final ai = summary.aiAnalytics;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(context, 'Total Scans', ai.totalScans.toString(), Icons.camera_alt)),
            Expanded(child: _buildStatCard(context, 'High Severity', ai.highSeverityCases.toString(), Icons.warning, color: Colors.red)),
          ],
        ),
        const SizedBox(height: 24),
        if (ai.diseaseDistribution.isNotEmpty)
          SizedBox(
            height: 300,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: DistributionPieChart(
                  data: ai.diseaseDistribution,
                  title: 'Disease Distribution',
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FlockHealthTab extends StatelessWidget {
  final DashboardSummary summary;
  const _FlockHealthTab({required this.summary});

  @override
  Widget build(BuildContext context) {
    final flock = summary.flockAnalytics;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(context, 'Mortality Rate', '${flock.mortalityRate}%', Icons.trending_down)),
            Expanded(child: _buildStatCard(context, 'Avg Weight', '${flock.averageWeight.toStringAsFixed(2)}kg', Icons.monitor_weight)),
          ],
        ),
        const SizedBox(height: 24),
        if (flock.growthTrend.isNotEmpty)
          SizedBox(
            height: 300,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TrendLineChart(
                  data: flock.growthTrend,
                  color: Colors.green,
                  title: 'Growth Trend (Avg Weight)',
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FinancialTab extends StatelessWidget {
  final DashboardSummary summary;
  const _FinancialTab({required this.summary});

  @override
  Widget build(BuildContext context) {
    final fin = summary.financeAnalytics;
    final currency = NumberFormat.simpleCurrency();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard(context, 'Total Expenses', currency.format(fin.totalExpenses), Icons.account_balance_wallet, color: Colors.blue),
        Row(
          children: [
            Expanded(child: _buildStatCard(context, 'Feed Cost', currency.format(fin.feedCost), Icons.restaurant)),
            Expanded(child: _buildStatCard(context, 'Medicine', currency.format(fin.medicineCost), Icons.medical_services)),
          ],
        ),
        const SizedBox(height: 24),
        if (fin.monthlyExpenseTrend.isNotEmpty)
          SizedBox(
            height: 300,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ExpenseBarChart(
                  data: fin.monthlyExpenseTrend,
                  title: 'Monthly Expenses',
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VaccinationTab extends StatelessWidget {
  final DashboardSummary summary;
  const _VaccinationTab({required this.summary});

  @override
  Widget build(BuildContext context) {
    final vac = summary.vaccinationAnalytics;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(context, 'Completed', vac.completed.toString(), Icons.check_circle, color: Colors.green)),
            Expanded(child: _buildStatCard(context, 'Upcoming', vac.upcoming.toString(), Icons.schedule, color: Colors.blue)),
          ],
        ),
        Row(
          children: [
            Expanded(child: _buildStatCard(context, 'Due This Week', vac.dueThisWeek.toString(), Icons.warning_amber, color: Colors.orange)),
            Expanded(child: _buildStatCard(context, 'Overdue', vac.overdue.toString(), Icons.error, color: Colors.red)),
          ],
        ),
        _buildStatCard(context, 'Compliance', '${vac.compliancePercentage.toStringAsFixed(1)}%', Icons.analytics, color: Colors.purple),
      ],
    );
  }
}

Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, {Color? color}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 16, right: 8, left: 8),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (color ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.1),
            child: Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

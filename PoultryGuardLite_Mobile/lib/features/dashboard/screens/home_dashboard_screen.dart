import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/pg_stats_card.dart';
import '../../history/analytics/providers/dashboard_provider.dart';
import '../../../shared/utils/currency_formatter.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Top App Bar ───────────────────────────────────────────────────
            SliverAppBar(
              floating: true,
              pinned: true,
              title: Row(
                children: [
                  Image.asset(
                    'assets/branding/poultryguard_logo.png',
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Morning,',
                        style: tt.labelMedium?.copyWith(
                          color: tt.bodySmall?.color,
                        ),
                      ),
                      Text(
                        user?.displayName ?? 'Poultry Farmer',
                        style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    context.push(AppRoutes.notifications);
                  },
                ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Dashboard Metrics ──────────────────────────────────────────
                  ref.watch(dashboardProvider).when(
                        data: (summary) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSummaryGrid(context, summary),
                              const SizedBox(height: 32),
                              
                              if (summary.recentScans.isNotEmpty) ...[
                                _buildSectionTitle(context, 'Recent AI Scan'),
                                const SizedBox(height: 16),
                                _buildRecentScans(context, summary),
                                const SizedBox(height: 32),
                              ],

                              if (summary.farmDashboardStats.isNotEmpty) ...[
                                _buildSectionTitle(context, 'Farm Status'),
                                const SizedBox(height: 16),
                                _buildActiveFarms(context, summary),
                                const SizedBox(height: 32),
                              ],

                              _buildSectionTitle(context, 'Feed Consumption'),
                              const SizedBox(height: 16),
                              _buildFeedChart(context, summary),
                              const SizedBox(height: 32),

                              _buildSectionTitle(context, 'Mortality Trend'),
                              const SizedBox(height: 16),
                              _buildMortalityChart(context, summary),
                              const SizedBox(height: 32),

                              _buildSectionTitle(context, 'AI Disease Distribution'),
                              const SizedBox(height: 16),
                              _buildDiseasePieChart(context, summary),
                              const SizedBox(height: 48),
                            ],
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, st) => Center(child: Text('Error loading dashboard: $err')),
                      ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  Widget _buildSummaryGrid(BuildContext context, dynamic summary) {
    final activeBirds = summary.activeBirds;
    final totalBirds = summary.totalBirds;
    final survivalRate = totalBirds > 0 ? (activeBirds / totalBirds) * 100 : 0.0;
    final formatter = NumberFormat("#,##0", "en_IN");

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        if (constraints.maxWidth > 900) crossAxisCount = 4;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            PgStatsCard(
              title: 'Total Farms',
              value: summary.totalFarms.toString(),
              icon: Icons.home_work_outlined,
            ),
            PgStatsCard(
              title: 'Initial Birds',
              value: formatter.format(summary.totalBirds),
              icon: Icons.egg_outlined,
            ),
            PgStatsCard(
              title: 'Remaining Birds',
              value: formatter.format(summary.activeBirds),
              icon: Icons.pets_outlined,
              color: AppColors.primary,
            ),
            PgStatsCard(
              title: 'Survival Rate',
              value: '${survivalRate.toStringAsFixed(1)}%',
              icon: Icons.health_and_safety_outlined,
              color: survivalRate > 90 ? Colors.green : AppColors.warning,
            ),
            PgStatsCard(
              title: 'Mortality',
              value: formatter.format(summary.activeFlockAnalytics.totalMortality),
              icon: Icons.warning_amber_outlined,
              color: AppColors.error,
            ),
            PgStatsCard(
              title: 'Feed (kg)',
              value: formatter.format(summary.activeFlockAnalytics.totalFeedConsumed.toInt()),
              icon: Icons.scale_outlined,
              color: Colors.brown,
            ),
            PgStatsCard(
              title: 'Water (L)',
              value: formatter.format(summary.activeFlockAnalytics.totalWaterConsumed.toInt()),
              icon: Icons.water_drop_outlined,
              color: Colors.blue,
            ),
            PgStatsCard(
              title: 'Revenue',
              value: CurrencyFormatter.format(summary.activeFinanceAnalytics.totalRevenue),
              icon: Icons.account_balance_wallet_outlined,
              color: Colors.green,
            ),
            PgStatsCard(
              title: 'Profit',
              value: CurrencyFormatter.format(summary.activeFinanceAnalytics.netProfit),
              icon: Icons.trending_up_outlined,
              color: summary.activeFinanceAnalytics.netProfit >= 0 ? Colors.green : AppColors.error,
            ),
          ],
        );
      }
    );
  }

  Widget _buildRecentScans(BuildContext context, dynamic summary) {
    if (summary.recentScans.isEmpty) {
      return const Text('No AI scans yet');
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: summary.recentScans.length,
      itemBuilder: (context, index) {
        final scan = summary.recentScans[index];
        final diseaseName = scan.result.diseaseName.isNotEmpty ? scan.result.diseaseName : 'Unknown Condition';
        final confidence = scan.result.confidence;
        final date = scan.createdAt != null ? DateFormat('MMM d, h:mm a').format(scan.createdAt!) : 'Unknown Date';
        
        Color severityColor = Colors.grey;
        if (scan.result.severity.toLowerCase() == 'high' || scan.result.severity.toLowerCase() == 'critical') {
          severityColor = AppColors.error;
        } else if (scan.result.severity.toLowerCase() == 'medium') {
          severityColor = AppColors.warning;
        } else {
          severityColor = Colors.green;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            leading: Icon(Icons.document_scanner, color: severityColor),
            title: Text(diseaseName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$confidence% confidence • $date'),
            trailing: Chip(
              label: Text(scan.result.severity),
              backgroundColor: severityColor.withValues(alpha: 0.1),
              labelStyle: TextStyle(color: severityColor, fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveFarms(BuildContext context, dynamic summary) {
    if (summary.farmDashboardStats.isEmpty) {
      return const Text('No active farms');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: summary.farmDashboardStats.length,
      itemBuilder: (context, index) {
        final stat = summary.farmDashboardStats[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            leading: const Icon(Icons.location_on, color: AppColors.primary),
            title: Text(stat.farmName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${stat.activeBatches} active batches • ${NumberFormat("#,##0", "en_IN").format(stat.remainingBirds)} birds'),
          ),
        );
      },
    );
  }

  Widget _buildFeedChart(BuildContext context, dynamic summary) {
    final Map<DateTime, double> feedTrend = summary.activeFlockAnalytics.feedTrend;
    if (feedTrend.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Not enough feed data'),
      ));
    }

    final sortedEntries = feedTrend.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    // Keep last 8 data points to fit
    final chartData = sortedEntries.length > 8 ? sortedEntries.sublist(sortedEntries.length - 8) : sortedEntries;

    final spots = chartData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    return SizedBox(
      height: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < chartData.length) {
                      final date = chartData[index].key;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(DateFormat('MM/dd').format(date), style: const TextStyle(fontSize: 10)),
                      );
                    }
                    return const SizedBox();
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.brown,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.brown.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildMortalityChart(BuildContext context, dynamic summary) {
    final Map<DateTime, int> mortalityTrend = summary.activeFlockAnalytics.mortalityTrend;
    if (mortalityTrend.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Not enough mortality data'),
      ));
    }

    final sortedEntries = mortalityTrend.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final chartData = sortedEntries.length > 8 ? sortedEntries.sublist(sortedEntries.length - 8) : sortedEntries;

    final spots = chartData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value.toDouble());
    }).toList();

    return SizedBox(
      height: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < chartData.length) {
                      final date = chartData[index].key;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(DateFormat('MM/dd').format(date), style: const TextStyle(fontSize: 10)),
                      );
                    }
                    return const SizedBox();
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.error,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.error.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildDiseasePieChart(BuildContext context, dynamic summary) {
    final Map<String, int> distribution = summary.aiAnalytics.diseaseDistribution;
    if (distribution.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No disease data available'),
      ));
    }

    int total = distribution.values.fold(0, (sum, val) => sum + val);
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.error,
      AppColors.warning,
      Colors.purple,
      Colors.teal,
    ];
    
    int colorIndex = 0;
    final sections = distribution.entries.map((e) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      final percentage = (e.value / total) * 100;
      return PieChartSectionData(
        color: color,
        value: e.value.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: distribution.entries.map((e) {
              final color = colors[distribution.keys.toList().indexOf(e.key) % colors.length];
              final label = e.key.isNotEmpty ? e.key : 'Unknown';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, color: color),
                  const SizedBox(width: 4),
                  Text(label, style: const TextStyle(fontSize: 12)),
                ],
              );
            }).toList(),
          )
        ],
      ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../models/batch_model.dart';
import '../providers/analytics_provider.dart';
import 'performance_badge.dart';

/// Displays the full analytics dashboard for a single batch.
/// Receives a pre-computed [BatchAnalytics] object (derived in-memory from
/// the Phase 5 entry stream — no additional Firestore reads).
class BatchAnalyticsWidget extends StatelessWidget {
  const BatchAnalyticsWidget({
    super.key,
    required this.analytics,
    required this.batch,
  });

  final BatchAnalytics analytics;
  final BatchModel batch;

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _mortalityColor(double pct) {
    if (pct < 2) return AppColors.healthy;
    if (pct < 5) return AppColors.warning;
    return AppColors.critical;
  }

  Widget _card(
    BuildContext context, {
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16.0),
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // 1 · Performance badge
        _buildPerformanceCard(context),
        const SizedBox(height: 16),

        // 2 · Key metrics grid
        _buildKeyMetricsCard(context),
        const SizedBox(height: 16),

        // 3 · Feed consumption trend (bar chart)
        if (analytics.feedTrend.isNotEmpty) ...[
          _buildFeedTrendCard(context),
          const SizedBox(height: 16),
        ],

        // 4 · Environment readings
        _buildEnvironmentCard(context),
        const SizedBox(height: 16),

        // 5 · Score breakdown
        _buildScoreBreakdownCard(context),
        const SizedBox(height: 48),
      ],
    );
  }

  // ── Section 1: Performance badge ──────────────────────────────────────────

  Widget _buildPerformanceCard(BuildContext context) {
    return _card(
      context,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Center(child: PerformanceBadge(score: analytics.performanceScore)),
    );
  }

  // ── Section 2: Key metrics 2×3 grid ───────────────────────────────────────

  Widget _buildKeyMetricsCard(BuildContext context) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, 'Key Metrics', Icons.bar_chart_rounded),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _metricTile(
                context,
                label: 'Total Entries',
                value: analytics.totalEntries.toString(),
                icon: Icons.list_alt_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              _metricTile(
                context,
                label: 'Feed Consumed',
                value: '${analytics.totalFeedConsumedKg.toStringAsFixed(1)} kg',
                icon: Icons.restaurant_rounded,
                color: AppColors.secondary,
              ),
              _metricTile(
                context,
                label: 'Water Consumed',
                value:
                    '${analytics.totalWaterConsumedLitres.toStringAsFixed(1)} L',
                icon: Icons.water_drop_rounded,
                color: Colors.blueAccent,
              ),
              _metricTile(
                context,
                label: 'Total Mortality',
                value: analytics.totalMortality.toString(),
                icon: Icons.warning_amber_rounded,
                color: AppColors.critical,
              ),
              _metricTile(
                context,
                label: 'Avg Weight',
                value: '${analytics.averageWeightKg.toStringAsFixed(2)} kg',
                icon: Icons.monitor_weight_rounded,
                color: Colors.purpleAccent,
              ),
              _metricTile(
                context,
                label: 'Mortality %',
                value: '${analytics.mortalityPercent.toStringAsFixed(1)}%',
                icon: Icons.percent_rounded,
                color: _mortalityColor(analytics.mortalityPercent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: tt.labelSmall?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section 3: Feed Consumption Trend bar chart ───────────────────────────

  Widget _buildFeedTrendCard(BuildContext context) {
    final points = analytics.feedTrend;
    final maxFeed = points.map((p) => p.feedKg).reduce(math.max);
    final tt = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            context,
            'Feed Consumption Trend',
            Icons.trending_up_rounded,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: points.map((point) {
                final ratio = maxFeed > 0 ? point.feedKg / maxFeed : 0.0;
                final barH = (90.0 * ratio).clamp(4.0, 90.0);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Value label on top of bar
                        Text(
                          point.feedKg.toStringAsFixed(0),
                          style: tt.labelSmall?.copyWith(
                            color: Theme.of(context).disabledColor,
                            fontSize: 9,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        // Bar
                        Container(
                          height: barH,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                primary.withValues(alpha: 0.9),
                                primary.withValues(alpha: 0.4),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Date label
                        Text(
                          DateFormat('d/M').format(point.date),
                          style: tt.labelSmall?.copyWith(
                            fontSize: 9,
                            color: Theme.of(context).disabledColor,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'kg feed per entry (last ${points.length} weeks)',
              style: tt.labelSmall?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section 4: Latest Environment ─────────────────────────────────────────

  Widget _buildEnvironmentCard(BuildContext context) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            context,
            'Latest Environment',
            Icons.thermostat_rounded,
          ),
          const SizedBox(height: 16),
          _environmentRow(
            context,
            label: 'Temperature',
            displayValue: '${analytics.latestTemperature}°C',
            value: analytics.latestTemperature,
            icon: Icons.thermostat_rounded,
            minVal: 0,
            maxVal: 40,
            optimalMin: 20,
            optimalMax: 28,
          ),
          const SizedBox(height: 16),
          _environmentRow(
            context,
            label: 'Humidity',
            displayValue: '${analytics.latestHumidity}%',
            value: analytics.latestHumidity,
            icon: Icons.water_outlined,
            minVal: 0,
            maxVal: 100,
            optimalMin: 55,
            optimalMax: 75,
          ),
        ],
      ),
    );
  }

  Widget _environmentRow(
    BuildContext context, {
    required String label,
    required String displayValue,
    required double value,
    required IconData icon,
    required double minVal,
    required double maxVal,
    required double optimalMin,
    required double optimalMax,
  }) {
    final tt = Theme.of(context).textTheme;
    final isOptimal = value >= optimalMin && value <= optimalMax;
    final color = isOptimal ? AppColors.healthy : AppColors.warning;
    final progress = ((value - minVal) / (maxVal - minVal)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: tt.bodyMedium),
            const Spacer(),
            Text(
              displayValue,
              style: tt.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isOptimal ? 'Optimal' : 'Off-range',
                style: tt.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              minVal.toInt().toString(),
              style: tt.labelSmall?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
            Text(
              'Optimal: ${optimalMin.toInt()}–${optimalMax.toInt()}',
              style: tt.labelSmall?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
            Text(
              maxVal.toInt().toString(),
              style: tt.labelSmall?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Section 5: Score breakdown ─────────────────────────────────────────────

  Widget _buildScoreBreakdownCard(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    // Recompute components for display only (identical to factory formula)
    final mortalityRate = (analytics.mortalityPercent / 100.0).clamp(0.0, 1.0);
    final mortalityScore = 40.0 * (1.0 - math.min(mortalityRate * 10.0, 1.0));
    final weightScore =
        35.0 * math.min(analytics.latestAverageWeightKg / 2.5, 1.0);
    final tempOk =
        analytics.latestTemperature >= 20 && analytics.latestTemperature <= 28;
    final humidityOk =
        analytics.latestHumidity >= 55 && analytics.latestHumidity <= 75;
    final envScore = (tempOk ? 12.5 : 5.0) + (humidityOk ? 12.5 : 5.0);

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, 'Score Breakdown', Icons.insights_rounded),
          const SizedBox(height: 16),
          _scoreRow(context, 'Mortality Rate', mortalityScore, 40, tt),
          const SizedBox(height: 10),
          _scoreRow(context, 'Average Weight', weightScore, 35, tt),
          const SizedBox(height: 10),
          _scoreRow(context, 'Environment', envScore, 25, tt),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Score',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '${analytics.performanceScore.toInt()} / 100',
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreRow(
    BuildContext context,
    String label,
    double score,
    double maxScore,
    TextTheme tt,
  ) {
    final progress = maxScore > 0 ? (score / maxScore).clamp(0.0, 1.0) : 0.0;
    final color = progress >= 0.75
        ? AppColors.healthy
        : progress >= 0.5
        ? AppColors.warning
        : AppColors.critical;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: tt.bodySmall),
            Text(
              '${score.toInt()} / ${maxScore.toInt()}',
              style: tt.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

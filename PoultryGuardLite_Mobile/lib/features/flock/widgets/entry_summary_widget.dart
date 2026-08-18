import 'package:flutter/material.dart';
import '../models/entry_model.dart';
import '../../../app/theme/app_colors.dart';

/// A summary card shown at the top of the Entries tab when entries exist.
/// Displays aggregate metrics computed in-memory from the live entry list —
/// no additional Firestore listeners are opened.
class EntrySummaryWidget extends StatelessWidget {
  const EntrySummaryWidget({super.key, required this.entries});

  final List<EntryModel> entries;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // ── Computed aggregates ─────────────────────────────────────────────────
    final totalMortality = entries.fold<int>(
      0,
      (sum, e) => sum + e.mortalityCount,
    );
    final avgFeed = entries.isEmpty
        ? 0.0
        : entries.fold<double>(0.0, (sum, e) => sum + e.feedConsumedKg) /
              entries.length;
    // Entries are ordered descending by date, so first entry = most recent.
    final latestAvgWeight = entries.isNotEmpty
        ? entries.first.averageWeightKg
        : 0.0;
    final entryCount = entries.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: colorScheme.primaryContainer.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Batch Summary',
                  style: tt.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildStat(
                    context,
                    '$entryCount',
                    'Entries',
                    Icons.list_alt_rounded,
                    colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _buildStat(
                    context,
                    '$totalMortality',
                    'Total Mortality',
                    Icons.warning_amber_rounded,
                    AppColors.critical,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStat(
                    context,
                    '${avgFeed.toStringAsFixed(1)} kg',
                    'Avg Feed/Week',
                    Icons.restaurant_rounded,
                    AppColors.secondary,
                  ),
                ),
                Expanded(
                  child: _buildStat(
                    context,
                    '${latestAvgWeight.toStringAsFixed(2)} kg',
                    'Latest Avg Wt',
                    Icons.monitor_weight_rounded,
                    Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: tt.labelSmall?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

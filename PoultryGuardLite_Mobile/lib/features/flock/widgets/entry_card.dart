import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/entry_model.dart';
import '../../../app/theme/app_colors.dart';

/// A compact, tappable card displaying the key metrics of a single weekly entry.
/// Follows the same Material 3 card style as [BatchCard] and [FarmCard].
class EntryCard extends StatelessWidget {
  const EntryCard({super.key, required this.entry, required this.onTap});

  final EntryModel entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final dateStr = entry.entryDate != null
        ? DateFormat('EEE, MMM d, yyyy').format(entry.entryDate!)
        : 'Unknown Date';

    // Mortality severity colour
    final Color mortalityColor;
    if (entry.mortalityCount == 0) {
      mortalityColor = AppColors.healthy;
    } else if (entry.mortalityCount <= 5) {
      mortalityColor = AppColors.warning;
    } else {
      mortalityColor = AppColors.critical;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ─────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Mortality badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: mortalityColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: mortalityColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: mortalityColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${entry.mortalityCount} Mortality',
                                style: tt.labelSmall?.copyWith(
                                  color: mortalityColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Stats row ───────────────────────────────────────────────────
              Row(
                children: [
                  _buildStat(
                    context,
                    Icons.restaurant_rounded,
                    '${entry.feedConsumedKg} kg Feed',
                    AppColors.secondary,
                  ),
                  const SizedBox(width: 16),
                  _buildStat(
                    context,
                    Icons.water_drop_rounded,
                    '${entry.waterConsumedLitres} L Water',
                    Colors.blueAccent,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ── Footer row ──────────────────────────────────────────────────
              Row(
                children: [
                  Icon(
                    Icons.monitor_weight_rounded,
                    size: 14,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.averageWeightKg} kg avg',
                    style: tt.bodySmall?.copyWith(
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.thermostat_rounded,
                    size: 14,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.temperature}°C  •  ${entry.humidity}%',
                    style: tt.bodySmall?.copyWith(
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    IconData icon,
    String text,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

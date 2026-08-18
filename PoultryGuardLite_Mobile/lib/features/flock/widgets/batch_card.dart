import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/batch_model.dart';
import '../providers/bird_stats_provider.dart';
import '../../../app/theme/app_colors.dart';
import 'batch_status_badge.dart';

class BatchCard extends StatelessWidget {
  const BatchCard({super.key, required this.batch, required this.onTap});

  final BatchModel batch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    String arrivalStr = batch.arrivalDate != null
        ? DateFormat.yMMMd().format(batch.arrivalDate!)
        : 'Unknown';

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          batch.batchName,
                          style: tt.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                batch.birdType,
                                style: tt.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            BatchStatusBadge(statusText: batch.status),
                          ],
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
              Row(
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final params = (farmId: batch.farmId, batchId: batch.id);
                      final stats = ref.watch(batchStatsProvider(params));
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildStat(
                                context,
                                Icons.pets_rounded,
                                '${stats.remainingBirds} Birds',
                                AppColors.secondary,
                              ),
                              const SizedBox(width: 16),
                              _buildStat(
                                context,
                                Icons.calendar_today_rounded,
                                '${batch.ageInDays} Days Old',
                                Colors.blueAccent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'Initial: ${stats.initialBirds}',
                                style: tt.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Sold: ${stats.totalSold}',
                                style: tt.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Mortality: ${stats.totalMortality}',
                                style: tt.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.flight_land,
                    size: 14,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Arrived: $arrivalStr',
                    style: tt.bodySmall?.copyWith(
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    batch.breed,
                    style: tt.bodySmall?.copyWith(
                      color: Theme.of(context).disabledColor,
                      fontWeight: FontWeight.bold,
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

import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

/// Circular performance gauge displaying a 0–100 composite score.
///
/// Color tiers:
/// - **Excellent** (≥ 80): [AppColors.healthy] green
/// - **Good**      (≥ 60): [AppColors.warning] amber
/// - **Fair**      (≥ 40): orange
/// - **Poor**      (< 40): [AppColors.critical] red
class PerformanceBadge extends StatelessWidget {
  const PerformanceBadge({super.key, required this.score});

  final double score;

  Color _color() {
    if (score >= 80) return AppColors.healthy;
    if (score >= 60) return AppColors.warning;
    if (score >= 40) return Colors.orange;
    return AppColors.critical;
  }

  String _label() {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Poor';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final color = _color();
    final label = _label();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Circular gauge ────────────────────────────────────────────────────
        SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Track (full circle)
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 12,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              // Score arc
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: score / 100.0,
                  strokeWidth: 12,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              // Center content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    score.toInt().toString(),
                    style: tt.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'out of 100',
                    style: tt.labelSmall?.copyWith(
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Performance Score',
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        // Tier label pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            label,
            style: tt.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

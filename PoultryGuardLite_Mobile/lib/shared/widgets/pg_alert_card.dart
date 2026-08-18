import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

enum AlertSeverity {
  info(AppColors.secondary, Icons.info_outline_rounded),
  warning(AppColors.warning, Icons.warning_amber_rounded),
  critical(AppColors.critical, Icons.error_outline_rounded);

  const AlertSeverity(this.color, this.icon);
  final Color color;
  final IconData icon;
}

class PgAlertCard extends StatelessWidget {
  const PgAlertCard({
    super.key,
    required this.title,
    required this.message,
    required this.severity,
  });

  final String title;
  final String message;
  final AlertSeverity severity;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: severity.color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: severity.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(severity.icon, color: severity.color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: severity.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: tt.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

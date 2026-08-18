import 'package:flutter/material.dart';

enum BatchStatus { active, completed, archived }

extension BatchStatusExtension on BatchStatus {
  String get displayName {
    switch (this) {
      case BatchStatus.active:
        return 'Active';
      case BatchStatus.completed:
        return 'Completed';
      case BatchStatus.archived:
        return 'Archived';
    }
  }

  Color get color {
    switch (this) {
      case BatchStatus.active:
        return Colors.green;
      case BatchStatus.completed:
        return Colors.grey;
      case BatchStatus.archived:
        return Colors.red;
    }
  }

  static BatchStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return BatchStatus.active;
      case 'completed':
        return BatchStatus.completed;
      case 'archived':
        return BatchStatus.archived;
      default:
        return BatchStatus.active;
    }
  }
}

class BatchStatusBadge extends StatelessWidget {
  const BatchStatusBadge({
    super.key,
    required this.statusText,
    this.isCircular = false,
  });

  final String statusText;
  final bool isCircular;

  @override
  Widget build(BuildContext context) {
    final status = BatchStatusExtension.fromString(statusText);

    if (isCircular) {
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.displayName.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: status.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

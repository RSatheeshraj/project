import 'dart:io';
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/ai_scan_result_model.dart';
import 'ai_result_pdf_preview.dart';

class AiResultScreen extends StatelessWidget {
  const AiResultScreen({
    super.key,
    required this.result,
    this.imageFile,
    this.imageUrl,
    this.farmName = 'Unknown Farm',
    this.batchName = 'Unknown Batch',
  });

  final AiScanResultModel result;
  final File? imageFile;
  final String? imageUrl;
  final String farmName;
  final String batchName;

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
      case 'critical':
        return AppColors.critical;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.primary;

    return Card(
      elevation: 0,
      color: cardColor.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cardColor.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: cardColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cardColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(content, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severityColor = _severityColor(result.severity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Download Report',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AiResultPdfPreviewScreen(
                    result: result,
                    imageFile: imageFile,
                    imageUrl: imageUrl,
                    farmName: farmName,
                    batchName: batchName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview
            if (imageFile != null || (imageUrl != null && imageUrl!.isNotEmpty))
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageFile != null
                    ? Image.file(
                        imageFile!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        },
                      ),
              )
            else
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'Image unavailable',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Header: Disease Name and Badges
            Text(
              result.diseaseName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Severity Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: severityColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: severityColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${result.severity} Severity',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: severityColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Confidence Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.analytics_rounded,
                        size: 16,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${result.confidence}% Confidence',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Isolation Badge
            if (result.isolationRequired)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.critical.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.critical),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.masks_rounded, color: AppColors.critical),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Isolation Required! Separate affected birds immediately to prevent spread.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.critical,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Details Cards
            _buildCard(
              context,
              title: 'Possible Cause',
              content: result.possibleCause,
              icon: Icons.search_rounded,
              color: Colors.blueGrey,
            ),
            const SizedBox(height: 16),
            _buildCard(
              context,
              title: 'Immediate Action',
              content: result.immediateAction,
              icon: Icons.flash_on_rounded,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildCard(
              context,
              title: 'Treatment Plan',
              content: result.treatment,
              icon: Icons.medical_services_rounded,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildCard(
              context,
              title: 'Prevention',
              content: result.prevention,
              icon: Icons.shield_rounded,
              color: Colors.green,
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

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

  Widget _buildFieldRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color iconBgColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
    final trainedResult = result.trainedAiResult;

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // FINAL RESULT Banner Header (Matching AI SCAN.png)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'FINAL RESULT (SHOW TO FARMER)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Image Preview
            if (imageFile != null || (imageUrl != null && imageUrl!.isNotEmpty))
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageFile != null
                    ? Image.file(
                        imageFile!,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        imageUrl!,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 220,
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 220,
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
            const SizedBox(height: 16),

            // Trained AI Model Status Badge (if available)
            if (trainedResult != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: trainedResult.isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: trainedResult.isSuccess ? Colors.green.shade300 : Colors.red.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      trainedResult.isSuccess ? Icons.check_circle : Icons.warning_amber_rounded,
                      size: 16,
                      color: trainedResult.isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trainedResult.isSuccess
                            ? 'Trained AI Model: Identified ${trainedResult.diseaseName} (${trainedResult.confidence.toStringAsFixed(2)}%)'
                            : 'Trained AI Model: Low Confidence (Proceeded to Gemini)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: trainedResult.isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Disease Name & Severity / Confidence badges
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
            const SizedBox(height: 16),

            // Structured Result Fields (Matching AI SCAN.png bottom panel)
            _buildFieldRow(
              context,
              label: 'Disease / Condition',
              value: result.diseaseName,
              icon: Icons.coronavirus_rounded,
              iconBgColor: Colors.purple.shade600,
            ),
            _buildFieldRow(
              context,
              label: 'Confidence',
              value: '${result.confidence}% (${result.severity} Severity)',
              icon: Icons.speed_rounded,
              iconBgColor: Colors.orange.shade700,
            ),
            _buildFieldRow(
              context,
              label: 'Symptoms',
              value: result.symptoms.isNotEmpty
                  ? result.symptoms
                  : 'Observed clinical signs in affected birds',
              icon: Icons.medical_information_rounded,
              iconBgColor: Colors.green.shade600,
            ),
            _buildFieldRow(
              context,
              label: 'Prevention',
              value: result.prevention.isNotEmpty
                  ? result.prevention
                  : 'Maintain biosecurity, sanitation and proper flock management.',
              icon: Icons.shield_rounded,
              iconBgColor: Colors.blue.shade600,
            ),
            _buildFieldRow(
              context,
              label: 'Recommendation',
              value: result.recommendation.isNotEmpty
                  ? result.recommendation
                  : (result.immediateAction.isNotEmpty
                      ? result.immediateAction
                      : 'Consult local veterinarian for supportive treatment.'),
              icon: Icons.assignment_turned_in_rounded,
              iconBgColor: Colors.red.shade600,
            ),

            // Isolation Badge
            if (result.isolationRequired) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.critical.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
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
            ],

            const SizedBox(height: 24),

            // Detailed Cards
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
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

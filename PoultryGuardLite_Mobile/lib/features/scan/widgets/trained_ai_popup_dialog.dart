import 'package:flutter/material.dart';
import '../models/trained_ai_result.dart';

/// Popup dialog matching the "SUCCESS ✓" and "FAILED ✗" specs from AI SCAN.png reference diagram.
class TrainedAiPopupDialog extends StatelessWidget {
  const TrainedAiPopupDialog({
    super.key,
    required this.result,
    required this.onContinue,
  });

  final TrainedAiResult result;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final isSuccess = result.isSuccess;

    final primaryColor = isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final bgColor = isSuccess ? const Color(0xFFF1F8E9) : const Color(0xFFFFEBEE);
    final cardBorderColor = isSuccess ? const Color(0xFFA5D6A7) : const Color(0xFFEF9A9A);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cardBorderColor, width: 1.5),
      ),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top module indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeaderBadge('AI SCAN MODULE', Colors.blue.shade800, Colors.blue.shade50),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.0),
                  child: Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey),
                ),
                _buildHeaderBadge('TRAINED AI MODEL', Colors.purple.shade800, Colors.purple.shade50),
              ],
            ),
            const SizedBox(height: 16),

            // Identified Status Subtitle Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSuccess ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSuccess ? Colors.green.shade400 : Colors.red.shade400,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSuccess ? Icons.check_circle : Icons.cancel,
                    size: 18,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isSuccess
                          ? 'Dataset is available in AI trained model (${result.diseaseName} – ${result.confidence.toStringAsFixed(2)}%)'
                          : 'Image is not in AI trained model',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // POPUP MESSAGE Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorderColor, width: 1.5),
              ),
              child: Column(
                children: [
                  // Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSuccess ? Icons.check_rounded : Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header Title
                  Text(
                    isSuccess ? 'AI Model Worked!' : 'AI Model Could Not Identify',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Message Body
                  Text(
                    isSuccess
                        ? 'Dataset is available in AI trained model.\nThe trained AI model has analyzed the image successfully.\n\nProceeding with Gemini AI for detailed analysis...'
                        : 'Image is not in AI trained model.\nThe trained model could not confidently identify this image.\n\nProceeding with Gemini AI for further analysis...',
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildHeaderBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/logger_service.dart';
import '../ai_config.dart';

final visionRepositoryProvider = Provider<VisionRepository>((ref) {
  return VisionRepository();
});

/// Handles direct interactions with the Gemini API for vision tasks
/// (disease image analysis).
class VisionRepository {
  Future<String> analyzeImage({
    required String prompt,
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    try {
      AppLogger.d('[VisionRepository] Starting image analysis...');
      
      final model = FirebaseAI.googleAI().generativeModel(
        model: AiConfig.visionModel,
        generationConfig: GenerationConfig(
          temperature: AiConfig.visionTemperature,
          topP: AiConfig.defaultTopP,
          topK: AiConfig.defaultTopK,
          maxOutputTokens: AiConfig.maxOutputTokens,
          // If responseMimeType is supported in firebase_ai, set it here for JSON
          responseMimeType: 'application/json', 
        ),
      );

      final response = await model.generateContent(
        [
          Content.multi([
            TextPart(prompt),
            InlineDataPart(mimeType, imageBytes),
          ])
        ],
      ).timeout(AiConfig.visionTimeout);

      final text = response.text;
      if (text == null || text.isEmpty) {
        throw Exception('Vision API returned an empty response.');
      }

      AppLogger.d('[VisionRepository] Image analysis successful.');
      return text;
    } catch (e, st) {
      AppLogger.e('[VisionRepository] Error during image analysis', error: e, stackTrace: st);
      rethrow;
    }
  }
}

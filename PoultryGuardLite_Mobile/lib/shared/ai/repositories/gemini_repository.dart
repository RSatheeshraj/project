import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/logger_service.dart';
import '../ai_config.dart';

final geminiRepositoryProvider = Provider<GeminiRepository>((ref) {
  return GeminiRepository();
});

/// Handles direct interactions with the Gemini API for text-based tasks
/// (chat, reports, recommendations, predictions).
class GeminiRepository {
  Future<String> generateText({
    required String prompt,
    double temperature = AiConfig.chatTemperature,
  }) async {
    try {
      AppLogger.d('[GeminiRepository] Starting text generation...');
      
      // Initialize the model
      final model = FirebaseAI.googleAI().generativeModel(
        model: AiConfig.textModel,
        generationConfig: GenerationConfig(
          temperature: temperature,
          topP: AiConfig.defaultTopP,
          topK: AiConfig.defaultTopK,
          maxOutputTokens: AiConfig.maxOutputTokens,
        ),
      );

      final response = await model.generateContent(
        [Content.text(prompt)],
      ).timeout(AiConfig.defaultTimeout);

      final text = response.text;
      if (text == null || text.isEmpty) {
        throw Exception('Gemini returned an empty response.');
      }

      AppLogger.d('[GeminiRepository] Text generation successful.');
      return text;
    } catch (e, st) {
      AppLogger.e('[GeminiRepository] Error generating text', error: e, stackTrace: st);
      rethrow;
    }
  }
}

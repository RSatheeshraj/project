import 'dart:convert';
import '../../core/services/logger_service.dart';

class ResponseParser {
  /// Extracts JSON from a markdown code block if present,
  /// otherwise assumes the raw text is JSON and parses it.
  static Map<String, dynamic>? parseJson(String rawText) {
    if (rawText.isEmpty) return null;

    try {
      String jsonStr = rawText.trim();
      
      // Strip markdown code blocks if Gemini returned them
      if (jsonStr.startsWith('```')) {
        final firstNewline = jsonStr.indexOf('\n');
        final lastBackticks = jsonStr.lastIndexOf('```');
        if (firstNewline != -1 && lastBackticks != -1 && lastBackticks > firstNewline) {
          jsonStr = jsonStr.substring(firstNewline + 1, lastBackticks).trim();
        }
      }

      // If it doesn't look like an object or array, it might not be JSON
      if (!jsonStr.startsWith('{') && !jsonStr.startsWith('[')) {
        return null; // Pure text response
      }

      final parsed = json.decode(jsonStr);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }
      return {'data': parsed}; // Wrap arrays or primitives
    } catch (e) {
      AppLogger.w('[ResponseParser] Failed to parse JSON: $e');
      return null;
    }
  }
}

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exceptions.dart';
import '../../features/scan/models/ai_scan_result_model.dart';
import '../../features/scan/models/trained_ai_result.dart';
import '../../features/scan/services/ai_prompt_service.dart';

final aiScanRepositoryProvider = Provider<AiScanRepository>((ref) {
  return AiScanRepository();
});

/// Repository responsible for calling Gemini Vision AI via Firebase AI Logic.
class AiScanRepository {
  static const _modelName = 'gemini-3.6-flash';
  static const _tag = 'AiScanRepository';

  /// Calls Gemini Vision AI to analyze the image and flock context.
  Future<AiScanResultModel> analyzeImage({
    required File imageFile,
    required String farmName,
    required String batchName,
    required int birdAge,
    required int totalBirds,
    required double avgWeight,
    required double mortalityPercent,
    required double feedConsumed,
    required double waterConsumed,
    required double temperature,
    required double humidity,
    required String vaccination,
    required String medicine,
    TrainedAiResult? trainedAiResult,
  }) async {
    // ── 1. Build the generative model ────────────────────────────────────────
    final model = FirebaseAI.googleAI().generativeModel(
      model: _modelName,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    developer.log('[$_tag] Model initialised: $_modelName', name: _tag);

    // ── 2. Build the structured text prompt ──────────────────────────────────
    final prompt = AiPromptService.buildPrompt(
      farmName: farmName,
      batchName: batchName,
      birdAge: birdAge,
      totalBirds: totalBirds,
      avgWeight: avgWeight,
      mortalityPercent: mortalityPercent,
      feedConsumed: feedConsumed,
      waterConsumed: waterConsumed,
      temperature: temperature,
      humidity: humidity,
      vaccination: vaccination,
      medicine: medicine,
      trainedModelDisease: trainedAiResult?.isSuccess == true
          ? '${trainedAiResult!.diseaseName} (${trainedAiResult.confidence}%)'
          : null,
    );

    developer.log(
      '[$_tag] Prompt built — ${prompt.length} characters',
      name: _tag,
    );

    // ── 3. Read image bytes ──────────────────────────────────────────────────
    final Uint8List imageBytes;
    try {
      imageBytes = await imageFile.readAsBytes();
    } on FileSystemException catch (e, st) {
      developer.log(
        '[$_tag] Failed to read image file: $e',
        name: _tag,
        error: e,
        stackTrace: st,
      );
      throw AiScanException(
        'Could not read the selected image. Please try again.',
        cause: e,
      );
    }

    if (imageBytes.isEmpty) {
      throw const AiScanException('The selected image appears to be empty.');
    }

    final mimeType = _detectMimeType(imageBytes);

    developer.log(
      '[$_tag] Image loaded — ${imageBytes.lengthInBytes} bytes, mime: $mimeType',
      name: _tag,
    );

    // ── 4. Assemble multimodal content ───────────────────────────────────────
    final imagePart = InlineDataPart(mimeType, imageBytes);
    final content = [
      Content.multi([TextPart(prompt), imagePart]),
    ];

    // ── 5. Call Gemini ───────────────────────────────────────────────────────
    developer.log('[$_tag] Sending request to Gemini...', name: _tag);

    try {
      final response = await model.generateContent(content);

      final finishReason =
          response.candidates.firstOrNull?.finishReason?.name ?? 'unknown';
      developer.log(
        '[$_tag] Gemini responded — finish reason: $finishReason',
        name: _tag,
      );

      // ── 6. Validate response text ──────────────────────────────────────────
      final text = response.text;
      developer.log('[$_tag] Raw Gemini response: $text', name: _tag);

      if (text == null || text.trim().isEmpty) {
        developer.log(
          '[$_tag] Empty response — finishReason: $finishReason',
          name: _tag,
        );
        throw AiScanException(
          'The AI did not return a result (finish reason: $finishReason). '
          'The image may have been blocked by safety filters. '
          'Please try a different image.',
        );
      }

      // ── 7. Safe JSON parsing ───────────────────────────────────────────────
      final parsedResult = _parseResponse(text);
      
      // Attach the trained AI model result to the parsed Gemini result
      if (trainedAiResult != null) {
        return parsedResult.copyWith(trainedAiResult: trainedAiResult);
      }
      return parsedResult;

      // ── Error handling ─────────────────────────────────────────────────────
    } on AiScanException {
      rethrow;
    } on InvalidApiKey catch (e, st) {
      developer.log(
        '[$_tag] InvalidApiKey: ${e.message}',
        name: _tag,
        error: e,
        stackTrace: st,
      );
      throw AiScanException(
        'Invalid Gemini API key. Verify your Firebase project configuration '
        'and ensure the Gemini API is enabled in the Firebase console.',
        cause: e,
      );
    } on UnsupportedUserLocation catch (e, st) {
      developer.log(
        '[$_tag] UnsupportedUserLocation: ${e.message}',
        name: _tag,
        error: e,
        stackTrace: st,
      );
      throw AiScanException(
        'Gemini AI is not available in your region. '
        'Please check Firebase regional availability.',
        cause: e,
      );
    } on FirebaseAIException catch (e, st) {
      developer.log(
        '[$_tag] FirebaseAIException (${e.runtimeType}): ${e.message}',
        name: _tag,
        error: e,
        stackTrace: st,
      );
      throw AiScanException(_mapFirebaseAiMessage(e.message), cause: e);
    } on FirebaseAISdkException catch (e, st) {
      developer.log(
        '[$_tag] FirebaseAISdkException: ${e.message}',
        name: _tag,
        error: e,
        stackTrace: st,
      );
      throw AiScanException(
        'Internal SDK error — please update the app and try again.',
        cause: e,
      );
    } on SocketException catch (e, st) {
      developer.log(
        '[$_tag] SocketException (no network): $e',
        name: _tag,
        error: e,
        stackTrace: st,
      );
      throw AiScanException(
        'Network error — please check your internet connection and try again.',
        cause: e,
      );
    } catch (e, st) {
      developer.log(
        '[$_tag] Unexpected error during Gemini call.\n'
        'Type   : ${e.runtimeType}\n'
        'Message: $e',
        name: _tag,
        error: e,
        stackTrace: st,
      );
      throw AiScanException(
        'An unexpected error occurred while analysing the image. '
        '(${e.runtimeType}: $e)',
        cause: e,
      );
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  AiScanResultModel _parseResponse(String text) {
    try {
      final clean = text
          .replaceAll(RegExp(r'```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'```\s*', multiLine: true), '')
          .trim();

      final decoded = json.decode(clean);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object at the root level');
      }

      developer.log(
        '[$_tag] JSON parsed successfully — keys: ${decoded.keys.toList()}',
        name: _tag,
      );

      return AiScanResultModel.fromMap(decoded);
    } on FormatException catch (e, st) {
      developer.log(
        '[$_tag] JSON parse failed: $e\nRaw text: $text',
        name: _tag,
        error: e,
        stackTrace: st,
      );
      throw AiScanException(
        'The AI returned an unreadable response. Please try again.',
        cause: e,
      );
    }
  }

  String _mapFirebaseAiMessage(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('quota') || lower.contains('rate limit')) {
      return 'Gemini API quota exceeded. Please wait a few minutes and try '
          'again, or check your Firebase billing plan.';
    }
    if (lower.contains('permission denied') ||
        lower.contains('permission_denied')) {
      return 'Permission denied. Ensure the Gemini API is enabled in your '
          'Firebase project and that your project has the correct IAM roles.';
    }
    if (lower.contains('not found') ||
        lower.contains('not_found') ||
        lower.contains('model')) {
      return 'Gemini model "$_modelName" not found. Ensure your Firebase '
          'project has access to this model.';
    }
    if (lower.contains('service') && lower.contains('enabl')) {
      return 'The Gemini API is not enabled for your Firebase project. '
          'Please enable it in the Firebase console under "AI Logic".';
    }
    if (lower.contains('block') || lower.contains('safety')) {
      return 'The request was blocked by safety filters. '
          'Please try a different image.';
    }
    if (lower.contains('resource exhausted') ||
        lower.contains('resource_exhausted')) {
      return 'The Gemini service is temporarily overloaded. '
          'Please try again in a moment.';
    }
    return 'Gemini AI error: $message';
  }

  String _detectMimeType(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46) {
      return 'image/gif';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}

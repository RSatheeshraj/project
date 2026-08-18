import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exceptions.dart';
import '../../features/scan/models/ai_scan_result_model.dart';
import '../../features/scan/services/ai_prompt_service.dart';

final aiScanRepositoryProvider = Provider<AiScanRepository>((ref) {
  return AiScanRepository();
});

/// Repository responsible for calling Gemini Vision AI via Firebase AI Logic.
///
/// Uses [firebase_ai] — the official Firebase package that authenticates
/// securely via your Firebase project configuration. No client-side API key
/// is required or used.
///
/// Public exception types exposed by [firebase_ai] v2.x:
///   [InvalidApiKey]            — API key rejected by Google
///   [UnsupportedUserLocation]  — region not supported
///   [ServerException]          — generic server-side error (includes quota,
///                                service-disabled, permission-denied)
///   [FirebaseAIException]      — base class for all of the above
///   [FirebaseAISdkException]   — SDK/format parsing bug
///
/// All of these are caught and converted to the typed [AiScanException].
class AiScanRepository {
  // ── Model configuration ───────────────────────────────────────────────
  // gemini-3.6-flash: officially supported multimodal model for the latest Firebase AI Logic SDK.
  // Supports text + image input with fast inference and high accuracy.
  static const _modelName = 'gemini-3.6-flash';

  // ── Logging tag ──────────────────────────────────────────────────────────
  static const _tag = 'AiScanRepository';

  /// Calls Gemini Vision AI to analyze the image and flock context.
  ///
  /// Throws [AiScanException] for all expected failure modes. The original
  /// exception is preserved in [AiScanException.cause] for debugging.
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
  }) async {
    // ── 1. Build the generative model ────────────────────────────────────────
    // FirebaseAI.googleAI() targets the Gemini Developer API backend.
    // No API key needed client-side; Firebase uses your project config.
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

    // Detect MIME type from magic bytes (JPEG/PNG/GIF/WebP; fallback JPEG).
    final mimeType = _detectMimeType(imageBytes);

    developer.log(
      '[$_tag] Image loaded — ${imageBytes.lengthInBytes} bytes, '
      'mime: $mimeType',
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
      return _parseResponse(text);

      // ── Error handling ─────────────────────────────────────────────────────
    } on AiScanException {
      rethrow; // Already a domain exception — let it propagate as-is.

    } on InvalidApiKey catch (e, st) {
      // firebase_ai exports InvalidApiKey directly.
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
      // firebase_ai exports UnsupportedUserLocation directly.
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
      // Covers ServerException (which wraps quota/service-disabled/permission),
      // plus any other FirebaseAIException subclass not exported individually.
      developer.log(
        '[$_tag] FirebaseAIException (${e.runtimeType}): ${e.message}',
        name: _tag,
        error: e,
        stackTrace: st,
      );
      throw AiScanException(_mapFirebaseAiMessage(e.message), cause: e);

    } on FirebaseAISdkException catch (e, st) {
      // SDK-level parsing bug — indicates a version mismatch.
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
      // Catch-all: logs the REAL exception + stack trace to the console so the
      // developer can see it. This fixes the previous "\\$e" bug that hid
      // the actual error message.
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

  /// Safely parses the Gemini JSON response into [AiScanResultModel].
  ///
  /// Strips markdown code fences if present, validates the root type,
  /// and throws [AiScanException] (not raw [FormatException]) on failure.
  AiScanResultModel _parseResponse(String text) {
    try {
      // Strip markdown code fences that some model responses include even when
      // responseMimeType is set to application/json.
      final clean = text
          .replaceAll(RegExp(r'```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'```\s*', multiLine: true), '')
          .trim();

      final decoded = json.decode(clean);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'Expected a JSON object at the root level',
        );
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

  /// Maps a [FirebaseAIException.message] to a user-friendly description.
  ///
  /// [ServerException] wraps many HTTP errors (quota, permission, service
  /// disabled) without separate exported subclasses in v2.3.0. We do a
  /// best-effort match on the message string.
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
    // Fallback: expose the raw message for debugging.
    return 'Gemini AI error: $message';
  }

  /// Detects the image MIME type from magic bytes.
  ///
  /// Falls back to `image/jpeg` — the most common format from camera/gallery.
  String _detectMimeType(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 && // 'P'
        bytes[2] == 0x4E && // 'N'
        bytes[3] == 0x47) {
      // 'G'
      return 'image/png';
    }
    if (bytes.length >= 6 &&
        bytes[0] == 0x47 && // 'G'
        bytes[1] == 0x49 && // 'I'
        bytes[2] == 0x46) {
      // 'F'
      return 'image/gif';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && // 'R'
        bytes[1] == 0x49 && // 'I'
        bytes[2] == 0x46 && // 'F'
        bytes[3] == 0x46 && // 'F'
        bytes[8] == 0x57 && // 'W'
        bytes[9] == 0x45 && // 'E'
        bytes[10] == 0x42 && // 'B'
        bytes[11] == 0x50) {
      // 'P'
      return 'image/webp';
    }
    return 'image/jpeg'; // Safe default for camera/gallery output.
  }
}

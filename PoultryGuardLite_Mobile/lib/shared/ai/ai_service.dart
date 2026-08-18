import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_cache.dart';
import 'ai_usage_monitor.dart';
import 'function_registry.dart';
import 'repositories/gemini_repository.dart';
import 'repositories/vision_repository.dart';
import 'models/ai_request.dart';
import 'models/ai_response.dart';
import 'response_parser.dart';
import 'response_validator.dart';
import '../../core/services/logger_service.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService(
    geminiRepo: ref.watch(geminiRepositoryProvider),
    visionRepo: ref.watch(visionRepositoryProvider),
    cache: ref.watch(aiCacheProvider),
    usageMonitor: ref.watch(aiUsageMonitorProvider),
    registry: ref.watch(functionRegistryProvider),
  );
});

/// Orchestrates the full AI request pipeline:
/// Request -> Cache -> Repository -> Validator -> Parser -> Cache -> Response
class AiService {
  final GeminiRepository geminiRepo;
  final VisionRepository visionRepo;
  final AiCache cache;
  final AiUsageMonitor usageMonitor;
  final FunctionRegistry registry; // For tool calls (Phase 2+)

  AiService({
    required this.geminiRepo,
    required this.visionRepo,
    required this.cache,
    required this.usageMonitor,
    required this.registry,
  }) {
    // ignore: unused_local_variable
    final unused = registry;
  }

  Future<AiResponse> processRequest(
    AiRequest request, {
    List<String> requiredKeys = const [],
  }) async {
    final startTime = DateTime.now();
    final isVision = request.type == AiRequestType.vision;

    try {
      // 1. Check Cache
      if (!request.bypassCache) {
        final cached = await cache.get(request.cacheKey);
        if (cached != null) {
          _recordUsage(startTime, isVision, cached.rawText.length, true);
          return cached;
        }
      }

      // 2. Fetch from Repository
      String rawText;
      if (isVision) {
        if (request.imageBytes == null || request.imageMimeType == null) {
          throw Exception('Vision request missing image data.');
        }
        rawText = await visionRepo.analyzeImage(
          prompt: request.prompt,
          imageBytes: request.imageBytes!,
          mimeType: request.imageMimeType!,
        );
      } else {
        rawText = await geminiRepo.generateText(prompt: request.prompt);
      }

      // 3. Parse JSON
      final parsedJson = ResponseParser.parseJson(rawText);

      // 4. Validate Schema
      if (requiredKeys.isNotEmpty) {
        ResponseValidator.validate(parsedJson, requiredKeys);
      }

      // 5. Construct Response
      final response = AiResponse.success(
        rawText,
        json: parsedJson,
        cached: false,
      );

      // 6. Save to Cache
      if (!request.bypassCache) {
        await cache.save(request.cacheKey, response);
      }

      // 7. Record Usage
      _recordUsage(startTime, isVision, rawText.length, false);

      return response;
    } catch (e) {
      usageMonitor.recordError();
      AppLogger.e('[AiService] Error processing request', error: e);
      return AiResponse.error(e.toString());
    }
  }

  void _recordUsage(DateTime startTime, bool isVision, int responseLength, bool isCacheHit) {
    final latency = DateTime.now().difference(startTime);
    // Extremely rough token estimate (1 token ~ 4 chars)
    final estimatedTokens = responseLength ~/ 4;
    usageMonitor.recordRequest(
      isVision: isVision,
      latency: latency,
      estimatedTokens: estimatedTokens,
      isCacheHit: isCacheHit,
    );
  }
}

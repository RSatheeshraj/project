import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/logger_service.dart';
import 'models/ai_usage_stats.dart';

final aiUsageMonitorProvider = Provider<AiUsageMonitor>((ref) {
  return AiUsageMonitor();
});

/// Monitors AI usage, costs, performance, and cache hit rates.
/// In a production environment, this could periodically sync to Firestore or Analytics.
class AiUsageMonitor {
  AiUsageStats _stats = const AiUsageStats();

  AiUsageStats get stats => _stats;

  void recordRequest({
    required bool isVision,
    required Duration latency,
    required int estimatedTokens,
    required bool isCacheHit,
  }) {
    final updated = _stats.copyWith(
      totalRequests: _stats.totalRequests + 1,
      visionRequests: isVision ? _stats.visionRequests + 1 : _stats.visionRequests,
      chatRequests: !isVision ? _stats.chatRequests + 1 : _stats.chatRequests,
      totalLatencyMs: _stats.totalLatencyMs + latency.inMilliseconds,
      estimatedTokensUsed: _stats.estimatedTokensUsed + estimatedTokens,
      cacheHits: isCacheHit ? _stats.cacheHits + 1 : _stats.cacheHits,
      cacheMisses: !isCacheHit ? _stats.cacheMisses + 1 : _stats.cacheMisses,
    );
    _stats = updated;
    
    AppLogger.d(
      '[AiUsageMonitor] Request Recorded: '
      'Latency=${latency.inMilliseconds}ms | '
      'Tokens~$estimatedTokens | '
      'CacheHit=$isCacheHit',
    );
  }

  void recordError() {
    _stats = _stats.copyWith(errorCount: _stats.errorCount + 1);
    AppLogger.w('[AiUsageMonitor] Error Recorded. Total: ${_stats.errorCount}');
  }

  void recordRetry() {
    _stats = _stats.copyWith(retryCount: _stats.retryCount + 1);
    AppLogger.d('[AiUsageMonitor] Retry Recorded. Total: ${_stats.retryCount}');
  }

  void reset() {
    _stats = const AiUsageStats();
    AppLogger.i('[AiUsageMonitor] Stats Reset.');
  }
}

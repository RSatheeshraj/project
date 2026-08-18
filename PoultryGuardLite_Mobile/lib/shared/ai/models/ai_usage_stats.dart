class AiUsageStats {
  final int totalRequests;
  final int visionRequests;
  final int chatRequests;
  final int totalLatencyMs;
  final int estimatedTokensUsed;
  final int cacheHits;
  final int cacheMisses;
  final int errorCount;
  final int retryCount;

  const AiUsageStats({
    this.totalRequests = 0,
    this.visionRequests = 0,
    this.chatRequests = 0,
    this.totalLatencyMs = 0,
    this.estimatedTokensUsed = 0,
    this.cacheHits = 0,
    this.cacheMisses = 0,
    this.errorCount = 0,
    this.retryCount = 0,
  });

  double get averageLatencyMs =>
      totalRequests > 0 ? totalLatencyMs / totalRequests : 0;

  double get cacheHitRate =>
      totalRequests > 0 ? cacheHits / totalRequests : 0;

  AiUsageStats copyWith({
    int? totalRequests,
    int? visionRequests,
    int? chatRequests,
    int? totalLatencyMs,
    int? estimatedTokensUsed,
    int? cacheHits,
    int? cacheMisses,
    int? errorCount,
    int? retryCount,
  }) {
    return AiUsageStats(
      totalRequests: totalRequests ?? this.totalRequests,
      visionRequests: visionRequests ?? this.visionRequests,
      chatRequests: chatRequests ?? this.chatRequests,
      totalLatencyMs: totalLatencyMs ?? this.totalLatencyMs,
      estimatedTokensUsed: estimatedTokensUsed ?? this.estimatedTokensUsed,
      cacheHits: cacheHits ?? this.cacheHits,
      cacheMisses: cacheMisses ?? this.cacheMisses,
      errorCount: errorCount ?? this.errorCount,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

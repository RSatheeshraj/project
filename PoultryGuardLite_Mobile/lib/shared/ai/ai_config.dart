class AiConfig {
  /// The specific Gemini model used for text-only assistant operations.
  static const String textModel = 'gemini-1.5-flash';

  /// The specific Gemini model used for vision/multimodal operations.
  static const String visionModel = 'gemini-1.5-pro';

  /// Default timeout for AI requests to prevent hanging.
  static const Duration defaultTimeout = Duration(seconds: 15);

  /// Default timeout for vision requests which may take longer.
  static const Duration visionTimeout = Duration(seconds: 30);

  /// Number of retries for transient errors.
  static const int maxRetries = 2;

  // ── Generation Configs ───────────────────────────────────────────────────

  /// Temperature for chat/assistant (balance of creativity and consistency).
  static const double chatTemperature = 0.7;

  /// Temperature for analytics/predictions (needs high determinism).
  static const double analyticsTemperature = 0.2;

  /// Temperature for vision analysis.
  static const double visionTemperature = 0.4;

  static const double defaultTopP = 0.95;
  static const int defaultTopK = 40;
  static const int maxOutputTokens = 8192;
}

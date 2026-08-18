import 'dart:typed_data';

enum AiRequestType { chat, vision, report, prediction }

class AiRequest {
  final String prompt;
  final AiRequestType type;
  final Uint8List? imageBytes;
  final String? imageMimeType;
  final Map<String, dynamic>? contextData;
  final bool bypassCache;

  const AiRequest({
    required this.prompt,
    this.type = AiRequestType.chat,
    this.imageBytes,
    this.imageMimeType,
    this.contextData,
    this.bypassCache = false,
  });

  /// A unique hash for this request used for caching.
  String get cacheKey {
    final buffer = StringBuffer();
    buffer.write(prompt);
    buffer.write(type.name);
    if (contextData != null) {
      // Very simple hashing for structured data
      buffer.write(contextData.toString());
    }
    return buffer.toString().hashCode.toString();
  }
}

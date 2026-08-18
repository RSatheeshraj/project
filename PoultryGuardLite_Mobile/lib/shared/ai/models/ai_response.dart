import 'ai_tool_call.dart';

class AiResponse {
  final String rawText;
  final Map<String, dynamic>? parsedJson;
  final List<AiToolCall> toolCalls;
  final bool isCacheHit;
  final bool isError;
  final String? errorMessage;

  const AiResponse({
    required this.rawText,
    this.parsedJson,
    this.toolCalls = const [],
    this.isCacheHit = false,
    this.isError = false,
    this.errorMessage,
  });

  factory AiResponse.error(String message) {
    return AiResponse(
      rawText: '',
      isError: true,
      errorMessage: message,
    );
  }

  factory AiResponse.success(String text, {
    Map<String, dynamic>? json,
    List<AiToolCall> tools = const [],
    bool cached = false,
  }) {
    return AiResponse(
      rawText: text,
      parsedJson: json,
      toolCalls: tools,
      isCacheHit: cached,
    );
  }
}

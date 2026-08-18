import 'dart:convert';
import 'ai_response.dart';
import 'ai_tool_call.dart';

class AiCacheEntry {
  final String key;
  final AiResponse response;
  final DateTime expiresAt;

  const AiCacheEntry({
    required this.key,
    required this.response,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'expiresAt': expiresAt.toIso8601String(),
      'rawText': response.rawText,
      'parsedJson': response.parsedJson,
      'toolCalls': response.toolCalls.map((t) => t.toMap()).toList(),
    };
  }

  factory AiCacheEntry.fromMap(Map<String, dynamic> map) {
    return AiCacheEntry(
      key: map['key'] as String,
      expiresAt: DateTime.parse(map['expiresAt'] as String),
      response: AiResponse.success(
        map['rawText'] as String,
        json: map['parsedJson'] as Map<String, dynamic>?,
        tools: (map['toolCalls'] as List?)
                ?.map((t) => AiToolCall.fromMap(t as Map<String, dynamic>))
                .toList() ??
            [],
        cached: true,
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory AiCacheEntry.fromJson(String source) =>
      AiCacheEntry.fromMap(json.decode(source) as Map<String, dynamic>);
}

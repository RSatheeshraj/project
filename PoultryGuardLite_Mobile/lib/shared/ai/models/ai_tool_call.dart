class AiToolCall {
  final String name;
  final Map<String, dynamic> arguments;

  const AiToolCall({
    required this.name,
    required this.arguments,
  });

  factory AiToolCall.fromMap(Map<String, dynamic> map) {
    return AiToolCall(
      name: map['name'] as String,
      arguments: map['arguments'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'arguments': arguments,
    };
  }
}

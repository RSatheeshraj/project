import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/logger_service.dart';
import 'models/ai_tool_call.dart';

final functionRegistryProvider = Provider<FunctionRegistry>((ref) {
  return FunctionRegistry();
});

/// A registry mapping AI Tool Call names to Dart handler functions.
class FunctionRegistry {
  final Map<String, Future<dynamic> Function(Map<String, dynamic>)> _tools = {};

  /// Registers a tool by name and its async handler function.
  void register({
    required String name,
    required Future<dynamic> Function(Map<String, dynamic>) handler,
  }) {
    if (_tools.containsKey(name)) {
      AppLogger.w('[FunctionRegistry] Tool "$name" is already registered. Overwriting.');
    }
    _tools[name] = handler;
    AppLogger.d('[FunctionRegistry] Registered tool: $name');
  }

  /// Unregisters a tool by name.
  void unregister(String name) {
    _tools.remove(name);
  }

  /// Executes a tool call. Returns the result or throws if not found.
  Future<dynamic> execute(AiToolCall toolCall) async {
    final handler = _tools[toolCall.name];
    if (handler == null) {
      throw Exception('Tool "${toolCall.name}" not found in registry.');
    }

    try {
      AppLogger.d('[FunctionRegistry] Executing tool: ${toolCall.name}');
      final result = await handler(toolCall.arguments);
      return result;
    } catch (e, st) {
      AppLogger.e('[FunctionRegistry] Error executing tool: ${toolCall.name}', error: e, stackTrace: st);
      rethrow;
    }
  }
}

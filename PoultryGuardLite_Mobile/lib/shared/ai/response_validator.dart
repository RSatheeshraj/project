class ResponseValidator {
  /// Validates a parsed JSON response against a required schema structure.
  /// For now, this is simple keys validation. Can be expanded to JSON Schema.
  static void validate(Map<String, dynamic>? parsedJson, List<String> requiredKeys) {
    if (requiredKeys.isEmpty) return;
    
    if (parsedJson == null) {
      throw Exception('Validation failed: Expected JSON object but got null.');
    }

    for (final key in requiredKeys) {
      if (!parsedJson.containsKey(key)) {
        throw Exception('Validation failed: Missing required key "$key".');
      }
    }
  }
}

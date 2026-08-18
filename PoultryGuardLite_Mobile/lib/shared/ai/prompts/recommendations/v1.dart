class RecommendationPromptV1 {
  static String build({
    required Map<String, dynamic> contextData,
  }) {
    return '''
You are an expert Poultry Farm Consultant.
Review the following flock metrics and provide exactly 3 actionable recommendations.

FLOCK METRICS:
$contextData

INSTRUCTIONS:
1. Recommendations must be extremely practical for a broiler farmer.
2. Focus on areas where the data shows weakness (e.g., high mortality, poor FCR, low water intake).
3. Return ONLY a JSON array of strings. Do NOT return markdown or explanation.

Example Output:
[
  "Increase ventilation in the evening to reduce heat stress based on the recent mortality spike.",
  "Check water lines for blockages as water consumption has dropped by 15%.",
  "Introduce vitamin C supplements to improve immunity."
]
''';
  }
}

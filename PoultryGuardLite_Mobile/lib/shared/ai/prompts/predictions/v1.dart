class PredictionPromptV1 {
  static String build({
    required Map<String, dynamic> contextData,
  }) {
    return '''
You are a Predictive Modeling AI for PoultryGuard Lite.
Review the flock's historical growth and mortality trends, and project the outcome for the remainder of the batch.

FLOCK DATA & TRENDS:
$contextData

INSTRUCTIONS:
1. Provide a forecast for the final average body weight.
2. Provide a forecast for the final total mortality count.
3. Return ONLY valid JSON matching this schema exactly:

{
  "projectedFinalWeightKg": 2.5,
  "projectedTotalMortality": 120,
  "riskFactors": ["Heat stress next week", "Slight dip in feed intake"],
  "confidenceScore": 85
}

Do NOT output markdown blocks.
''';
  }
}

class AiPromptService {
  /// Builds the structured prompt for Gemini Vision AI based on flock context.
  static String buildPrompt({
    required String farmName,
    required String batchName,
    required int birdAge,
    required int totalBirds,
    required double avgWeight,
    required double mortalityPercent,
    required double feedConsumed,
    required double waterConsumed,
    required double temperature,
    required double humidity,
    required String vaccination,
    required String medicine,
  }) {
    return '''
You are an expert poultry veterinarian AI. Analyze the uploaded image of poultry droppings, affected areas, or birds.

Here is the current context of the flock to help with your diagnosis:
- Farm: $farmName
- Batch: $batchName
- Age: $birdAge days
- Total Birds: $totalBirds
- Avg Weight: ${avgWeight.toStringAsFixed(2)} kg
- Mortality: ${mortalityPercent.toStringAsFixed(1)}%
- Feed Consumed: ${feedConsumed.toStringAsFixed(1)} kg
- Water Consumed: ${waterConsumed.toStringAsFixed(1)} L
- Temperature: ${temperature.toStringAsFixed(1)}°C
- Humidity: ${humidity.toStringAsFixed(1)}%
- Vaccination History: ${vaccination.isEmpty ? 'None recorded' : vaccination}
- Current Medicine: ${medicine.isEmpty ? 'None recorded' : medicine}

Based on the image and the provided flock context, diagnose the potential disease or health issue.

Provide a raw JSON response (without markdown code blocks, just the JSON string) with the following exact keys:
{
  "diseaseName": "Name of the disease or issue",
  "confidence": 85, // Integer 0-100
  "severity": "High", // Must be one of: "Low", "Medium", "High", or "Critical"
  "possibleCause": "Description of the likely cause considering the environment and image",
  "immediateAction": "What the farmer should do right now",
  "treatment": "Recommended treatment protocol",
  "prevention": "How to prevent this in the future",
  "isolationRequired": true // boolean
}
''';
  }
}

import type { FlockContext } from './AnalyticsService';

export class AiPromptService {
  static buildPrompt(context: FlockContext): string {
    const {
      farmName,
      batchName,
      birdAge,
      totalBirds,
      avgWeight,
      mortalityPercent,
      feedConsumed,
      waterConsumed,
      temperature,
      humidity,
      vaccination,
      medicine,
    } = context;

    return `You are an expert poultry veterinarian AI. Analyze the uploaded image of poultry droppings, affected areas, or birds.

Here is the current context of the flock to help with your diagnosis:
- Farm: ${farmName}
- Batch: ${batchName}
- Age: ${birdAge} days
- Total Birds: ${totalBirds}
- Avg Weight: ${avgWeight.toFixed(2)} kg
- Mortality: ${mortalityPercent.toFixed(1)}%
- Feed Consumed: ${feedConsumed.toFixed(1)} kg
- Water Consumed: ${waterConsumed.toFixed(1)} L
- Temperature: ${temperature.toFixed(1)}°C
- Humidity: ${humidity.toFixed(1)}%
- Vaccination History: ${vaccination.trim() === '' ? 'None recorded' : vaccination}
- Current Medicine: ${medicine.trim() === '' ? 'None recorded' : medicine}

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
}`;
  }
}
import type { FlockContext } from './AnalyticsService';

export interface TrainedModelPromptInfo {
  trainedDisease?: string;
  trainedConfidence?: number;
}

export class AiPromptService {
  static buildPrompt(context: FlockContext, trainedInfo?: TrainedModelPromptInfo): string {
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

    const trainedContext = trainedInfo?.trainedDisease
      ? `\n- Trained AI Model Preliminary Identification: ${trainedInfo.trainedDisease}${
          trainedInfo.trainedConfidence !== undefined
            ? ` (Model Confidence: ${trainedInfo.trainedConfidence}%)`
            : ''
        }`
      : '';

    const trainedInstruction = trainedInfo?.trainedDisease
      ? `\nImportant: The custom-trained poultry disease model preliminarily identified "${trainedInfo.trainedDisease}". Please validate this finding against the visual symptoms and flock context, providing in-depth veterinary diagnosis, symptoms breakdown, cause, actionable treatment protocol, and preventative biosecurity measures.`
      : '';

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
- Current Medicine: ${medicine.trim() === '' ? 'None recorded' : medicine}${trainedContext}

Based on the image and the provided flock context, diagnose the potential disease or health issue.${trainedInstruction}

Provide a raw JSON response (without markdown code blocks, just the JSON string) with the following exact keys:
{
  "diseaseName": "Name of the disease or condition (e.g. Inclusion Body Hepatitis (IBH), Coccidiosis, Salmonella, or Healthy)",
  "confidence": 85, // Integer 0-100
  "severity": "High", // Must be one of: "Low", "Medium", "High", or "Critical"
  "possibleCause": "Description of the likely cause considering the environment, image, and pathogen",
  "immediateAction": "What the farmer should do right now",
  "treatment": "Recommended treatment protocol",
  "prevention": "How to prevent this in the future",
  "isolationRequired": true // boolean
}`;
  }
}
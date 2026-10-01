import { NextRequest, NextResponse } from 'next/server';
import { AnalyticsService } from '@/lib/server/AnalyticsService';
import { AiPromptService } from '@/lib/server/AiPromptService';
import { GeminiService } from '@/lib/server/GeminiService';
import { ScanHistoryService } from '@/lib/server/ScanHistoryService';

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData();
    
    const image = formData.get('image') as File | null;
    const farmId = formData.get('farmId') as string | null;
    const batchId = formData.get('batchId') as string | null;
    const uid = formData.get('uid') as string | null;
    const farmName = (formData.get('farmName') as string | null) || undefined;
    const batchName = (formData.get('batchName') as string | null) || undefined;
    const birdType = (formData.get('birdType') as string | null) || undefined;
    const rawTotalBirds = formData.get('totalBirds') as string | null;
    const totalBirds = rawTotalBirds ? parseInt(rawTotalBirds, 10) : undefined;
    const arrivalDate = (formData.get('arrivalDate') as string | null) || undefined;
    const analysisType = (formData.get('analysisType') as string | null) || undefined;
    const trainedDisease = (formData.get('trainedDisease') as string | null) || undefined;
    const rawConfidence = formData.get('trainedConfidence') as string | null;
    const trainedConfidence = rawConfidence ? parseFloat(rawConfidence) : undefined;

    if (!image || !farmId || !batchId || !uid) {
      return NextResponse.json({ error: 'Missing required fields in form data.' }, { status: 400 });
    }

    if (!image.type.startsWith('image/')) {
      return NextResponse.json({ error: 'Uploaded file is not an image.' }, { status: 400 });
    }

    // 1. Convert Image to Base64
    const arrayBuffer = await image.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);
    const base64 = buffer.toString('base64');

    // 2. Fetch context & compute analytics (with fallback support)
    const context = await AnalyticsService.getFlockContext(farmId, batchId, {
      farmName,
      batchName,
      birdType,
      totalBirds,
      arrivalDate,
    });

    // 3. Build Prompt (incorporates trained model preliminary result if provided)
    const prompt = AiPromptService.buildPrompt(context, {
      trainedDisease,
      trainedConfidence,
    });

    // 4. Call Gemini Vision
    let result;
    try {
      result = await GeminiService.analyzeImage(prompt, base64, image.type);
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'Unknown Gemini error';
      return NextResponse.json({ error: msg }, { status: 502 });
    }

    // 5. Save to Firestore
    try {
      await ScanHistoryService.saveScan({
        uid,
        farmId,
        batchId,
        farmName: context.farmName,
        batchName: context.batchName,
        result,
        analysisType,
        trainedDisease,
        trainedConfidence,
      });
    } catch (e) {
      console.warn('[ai-scan] Server-side history write skipped (handled by client):', e);
      return NextResponse.json({ result }, { status: 200 });
    }

    // 6. Return Result
    return NextResponse.json({ result }, { status: 200 });

  } catch (e) {
    console.error('[ai-scan] Unexpected error:', e);
    return NextResponse.json(
      { error: 'An unexpected error occurred. Please try again.' },
      { status: 500 }
    );
  }
}
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

    // 2. Fetch context & compute analytics
    let context;
    try {
      context = await AnalyticsService.getFlockContext(farmId, batchId);
    } catch (e) {
      console.error('[ai-scan] Error fetching flock context:', e);
      return NextResponse.json({ error: 'Could not load farm or batch data.' }, { status: 404 });
    }

    // 3. Build Prompt
    const prompt = AiPromptService.buildPrompt(context);

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
      });
    } catch (e) {
      console.error('[ai-scan] Firestore write error:', e);
      // Return result anyway - don't fail the whole scan for a save error
      return NextResponse.json({ result, warning: 'Scan completed but failed to save to history.' }, { status: 207 });
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
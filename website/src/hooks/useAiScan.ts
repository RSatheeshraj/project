'use client';

import { useMutation, useQueryClient } from '@tanstack/react-query';
import auth from '@/lib/firebase/auth';
import { SCAN_HISTORY_KEY } from '@/hooks/useScanHistory';
import type { AiScanResult } from '@/types/models';

export interface AiScanInput {
  file: File;
  farmId: string;
  batchId: string;
}

export interface AiScanOutput {
  result: AiScanResult;
}

async function runAiScan(input: AiScanInput): Promise<AiScanOutput> {
  const uid = auth.currentUser?.uid;
  if (!uid) {
    throw new Error('You must be signed in to run a scan.');
  }

  const formData = new FormData();
  formData.append('image', input.file);
  formData.append('farmId', input.farmId);
  formData.append('batchId', input.batchId);
  formData.append('uid', uid);

  console.log('[useAiScan] Sending POST to /api/ai-scan with FormData...');

  const response = await fetch('/api/ai-scan', {
    method: 'POST',
    body: formData,
  });

  interface ApiResponse {
    result?: AiScanResult;
    error?: string;
  }

  let data: ApiResponse;
  try {
    data = await response.json();
  } catch {
    throw new Error(`Server returned invalid response (HTTP ${response.status}).`);
  }

  if (!response.ok || data.error) {
    console.error('[useAiScan] API error:', data.error, 'HTTP:', response.status);
    throw new Error(
      data.error ?? `Server error (HTTP ${response.status}). Please try again.`
    );
  }

  if (!data.result) {
    throw new Error('No result returned from AI. Please try again.');
  }

  console.log('[useAiScan] Scan complete.');
  return { result: data.result };
}

export function useAiScan() {
  const qc = useQueryClient();

  return useMutation({
    mutationFn: runAiScan,
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: SCAN_HISTORY_KEY });
    },
  });
}
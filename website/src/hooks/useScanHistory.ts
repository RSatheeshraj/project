/**
 * TanStack Query hooks for scan history.
 */

'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { ScanHistoryRepository } from '@/repositories/scan-history.repository';
import type { ScanHistory } from '@/types/models';

export const SCAN_HISTORY_KEY = ['scan-history'] as const;

export function useScanHistory() {
  return useQuery({
    queryKey: SCAN_HISTORY_KEY,
    queryFn: () => ScanHistoryRepository.getScanHistory(),
    staleTime: 30_000,
  });
}

export function useScanHistoryById(scanId: string) {
  return useQuery({
    queryKey: [...SCAN_HISTORY_KEY, scanId],
    queryFn: () => ScanHistoryRepository.getScanHistoryById(scanId),
    enabled: !!scanId,
    staleTime: 30_000,
  });
}
export function useDeleteScanHistory() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (scanId: string) => ScanHistoryRepository.deleteScanHistory(scanId),
    onSuccess: () => qc.invalidateQueries({ queryKey: SCAN_HISTORY_KEY }),
  });
}

export function useAddScanHistory() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (
      scan: Omit<ScanHistory, 'id' | 'ownerId' | 'createdAt' | 'updatedAt'>
    ) => ScanHistoryRepository.addScanHistory(scan),
    onSuccess: () => qc.invalidateQueries({ queryKey: SCAN_HISTORY_KEY }),
  });
}

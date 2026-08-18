/**
 * TanStack Query hooks for batches.
 */

'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { BatchRepository } from '@/repositories/batch.repository';
import type { Batch, BatchInput } from '@/types/models';

export const batchesKey = (farmId: string) => ['batches', farmId] as const;

export function useBatches(farmId: string) {
  return useQuery({
    queryKey: batchesKey(farmId),
    queryFn: () => BatchRepository.getBatches(farmId),
    enabled: !!farmId,
    staleTime: 30_000,
  });
}

export function useBatch(farmId: string, batchId: string) {
  const { data, ...rest } = useBatches(farmId);
  const batch = data?.find(b => b.id === batchId);
  return { data: batch, ...rest };
}

export function useAddBatch() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: BatchInput) => BatchRepository.addBatch(input),
    onSuccess: (_, vars) => qc.invalidateQueries({ queryKey: batchesKey(vars.farmId) }),
  });
}

export function useUpdateBatch() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (batch: Batch) => BatchRepository.updateBatch(batch),
    onSuccess: (_, vars) => qc.invalidateQueries({ queryKey: batchesKey(vars.farmId) }),
  });
}

export function useDeleteBatch() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ farmId, batchId }: { farmId: string; batchId: string }) =>
      BatchRepository.deleteBatch(farmId, batchId),
    onSuccess: (_, vars) => qc.invalidateQueries({ queryKey: batchesKey(vars.farmId) }),
  });
}

/**
 * TanStack Query hooks for farms.
 * Queries mirror the FarmRepository methods.
 */

'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { FarmRepository } from '@/repositories/farm.repository';
import type { Farm, FarmInput } from '@/types/models';

export const FARMS_KEY = ['farms'] as const;

export function useFarms() {
  return useQuery({
    queryKey: FARMS_KEY,
    queryFn: () => FarmRepository.getFarms(),
    staleTime: 30_000,
  });
}

export function useAddFarm() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: FarmInput) => FarmRepository.addFarm(input),
    onSuccess: () => qc.invalidateQueries({ queryKey: FARMS_KEY }),
  });
}

export function useUpdateFarm() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (farm: Farm) => FarmRepository.updateFarm(farm),
    onSuccess: () => qc.invalidateQueries({ queryKey: FARMS_KEY }),
  });
}

export function useDeleteFarm() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (farmId: string) => FarmRepository.deleteFarm(farmId),
    onSuccess: () => qc.invalidateQueries({ queryKey: FARMS_KEY }),
  });
}

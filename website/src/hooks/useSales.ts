'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { SaleRepository } from '@/repositories/sale.repository';
import type { Sale, SaleInput } from '@/types/models';

export const salesKey = (farmId: string, batchId?: string) => 
  batchId ? (['sales', farmId, batchId] as const) : (['sales', farmId] as const);

export function useSales(farmId: string, batchId?: string) {
  return useQuery({
    queryKey: salesKey(farmId, batchId),
    queryFn: () => SaleRepository.getSales(farmId, batchId),
    enabled: !!farmId,
    staleTime: 30_000,
  });
}

export function useAddSale() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: SaleInput) => SaleRepository.addSale(input),
    onSuccess: (_, vars) => qc.invalidateQueries({ queryKey: salesKey(vars.farmId) }),
  });
}

export function useUpdateSale() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (sale: Sale) => SaleRepository.updateSale(sale),
    onSuccess: (_, vars) => qc.invalidateQueries({ queryKey: salesKey(vars.farmId) }),
  });
}

export function useDeleteSale() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ saleId }: { farmId: string; saleId: string }) =>
      SaleRepository.deleteSale(saleId),
    onSuccess: (_, vars) => qc.invalidateQueries({ queryKey: salesKey(vars.farmId) }),
  });
}

/**
 * TanStack Query hooks for weekly entries.
 */

'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { EntryRepository } from '@/repositories/entry.repository';
import type { WeeklyEntry, WeeklyEntryInput } from '@/types/models';

export const entriesKey = (farmId: string, batchId: string) =>
  ['entries', farmId, batchId] as const;

export function useEntries(farmId: string, batchId: string) {
  return useQuery({
    queryKey: entriesKey(farmId, batchId),
    queryFn: () => EntryRepository.getEntries(farmId, batchId),
    enabled: !!farmId && !!batchId,
    staleTime: 30_000,
  });
}

export function useAddEntry() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: WeeklyEntryInput) => EntryRepository.addEntry(input),
    onSuccess: (_, vars) =>
      qc.invalidateQueries({ queryKey: entriesKey(vars.farmId, vars.batchId) }),
  });
}

export function useUpdateEntry() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (entry: WeeklyEntry) => EntryRepository.updateEntry(entry),
    onSuccess: (_, vars) =>
      qc.invalidateQueries({ queryKey: entriesKey(vars.farmId, vars.batchId) }),
  });
}

export function useDeleteEntry() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      farmId,
      batchId,
      entryId,
    }: {
      farmId: string;
      batchId: string;
      entryId: string;
    }) => EntryRepository.deleteEntry(farmId, batchId, entryId),
    onSuccess: (_, vars) =>
      qc.invalidateQueries({ queryKey: entriesKey(vars.farmId, vars.batchId) }),
  });
}

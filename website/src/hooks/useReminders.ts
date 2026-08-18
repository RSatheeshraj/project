import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { ReminderRepository } from '@/repositories/reminder.repository';
import type { ReminderInput } from '@/types/models';

export function useReminders(farmId?: string) {
  const queryClient = useQueryClient();

  const query = useQuery({
    queryKey: ['reminders', farmId],
    queryFn: () => ReminderRepository.getReminders(farmId),
  });

  const addMutation = useMutation({
    mutationFn: (data: ReminderInput) => ReminderRepository.addReminder(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['reminders'] });
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<ReminderInput> }) =>
      ReminderRepository.updateReminder(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['reminders'] });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => ReminderRepository.deleteReminder(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['reminders'] });
    },
  });

  return {
    reminders: query.data || [],
    isLoading: query.isLoading,
    isError: query.isError,
    error: query.error,
    addReminder: addMutation.mutateAsync,
    updateReminder: updateMutation.mutateAsync,
    deleteReminder: deleteMutation.mutateAsync,
    isAdding: addMutation.isPending,
    isUpdating: updateMutation.isPending,
    isDeleting: deleteMutation.isPending,
  };
}

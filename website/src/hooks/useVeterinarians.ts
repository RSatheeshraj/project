import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { VeterinarianRepository } from '@/repositories/veterinarian.repository';
import type { VeterinarianInput } from '@/types/models';

export function useVeterinarians() {
  const queryClient = useQueryClient();

  const query = useQuery({
    queryKey: ['veterinarians'],
    queryFn: () => VeterinarianRepository.getVeterinarians(),
  });

  const addMutation = useMutation({
    mutationFn: (data: VeterinarianInput) => VeterinarianRepository.addVeterinarian(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['veterinarians'] });
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<VeterinarianInput> }) =>
      VeterinarianRepository.updateVeterinarian(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['veterinarians'] });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => VeterinarianRepository.deleteVeterinarian(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['veterinarians'] });
    },
  });

  return {
    veterinarians: query.data || [],
    isLoading: query.isLoading,
    isError: query.isError,
    error: query.error,
    addVeterinarian: addMutation.mutateAsync,
    updateVeterinarian: updateMutation.mutateAsync,
    deleteVeterinarian: deleteMutation.mutateAsync,
    isAdding: addMutation.isPending,
    isUpdating: updateMutation.isPending,
    isDeleting: deleteMutation.isPending,
  };
}

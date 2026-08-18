'use client';

import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Input, Textarea } from '@/components/ui/Input';
import { Select } from '@/components/ui/Select';
import { Button } from '@/components/ui/Button';
import type { Batch, BatchInput } from '@/types/models';

const BATCH_STATUS = [
  { value: 'Active', label: 'Active' },
  { value: 'Completed', label: 'Completed' },
  { value: 'Sold', label: 'Sold' },
];

const batchSchema = z.object({
  batchName: z.string().min(2, 'Batch name must be at least 2 characters').max(80),
  birdType: z.string().min(1, 'Bird type is required'),
  breed: z.string().min(1, 'Breed is required'),
  totalBirds: z.coerce.number().min(1, 'Total birds must be at least 1').max(10_000_000),
  supplier: z.string().min(1, 'Supplier is required').max(100),
  arrivalDate: z.string().min(1, 'Arrival date is required'),
  expectedMarketDate: z.string().min(1, 'Expected market date is required'),
  status: z.string().min(1, 'Status is required'),
  notes: z.string().max(500).optional().default(''),
});

type BatchFormValues = z.infer<typeof batchSchema>;

interface BatchFormProps {
  farmId: string;
  defaultValues?: Batch;
  onSubmit: (data: BatchInput) => Promise<void>;
  onCancel: () => void;
  loading?: boolean;
}

export function BatchForm({ farmId, defaultValues, onSubmit, onCancel, loading }: BatchFormProps) {
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm({
    resolver: zodResolver(batchSchema),
    defaultValues: defaultValues
      ? {
          batchName: defaultValues.batchName,
          birdType: defaultValues.birdType,
          breed: defaultValues.breed,
          totalBirds: defaultValues.totalBirds,
          supplier: defaultValues.supplier,
          arrivalDate: defaultValues.arrivalDate?.toISOString().split('T')[0] ?? '',
          expectedMarketDate: defaultValues.expectedMarketDate?.toISOString().split('T')[0] ?? '',
          status: defaultValues.status,
          notes: defaultValues.notes,
        }
      : { 
          totalBirds: 0, 
          status: 'Active', 
          notes: '',
          arrivalDate: new Date().toISOString().split('T')[0],
          expectedMarketDate: new Date().toISOString().split('T')[0],
        },
  });

  useEffect(() => {
    if (defaultValues) {
      reset({
        batchName: defaultValues.batchName,
        birdType: defaultValues.birdType,
        breed: defaultValues.breed,
        totalBirds: defaultValues.totalBirds,
        supplier: defaultValues.supplier,
        arrivalDate: defaultValues.arrivalDate?.toISOString().split('T')[0] ?? '',
        expectedMarketDate: defaultValues.expectedMarketDate?.toISOString().split('T')[0] ?? '',
        status: defaultValues.status,
        notes: defaultValues.notes,
      });
    }
  }, [defaultValues, reset]);

  const handleFormSubmit = async (values: BatchFormValues) => {
    await onSubmit({
      farmId,
      batchName: values.batchName,
      birdType: values.birdType,
      breed: values.breed,
      totalBirds: values.totalBirds,
      currentBirds: values.totalBirds, // Hardcoded, value ignored dynamically
      supplier: values.supplier,
      arrivalDate: new Date(values.arrivalDate),
      expectedMarketDate: new Date(values.expectedMarketDate),
      status: values.status,
      notes: values.notes ?? '',
    });
  };

  return (
    <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-4">
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <Input
          label="Batch Name"
          placeholder="e.g. Batch A"
          error={errors.batchName?.message}
          {...register('batchName')}
        />
        <Select
          label="Status"
          options={BATCH_STATUS}
          placeholder="Select status…"
          error={errors.status?.message}
          {...register('status')}
        />
        <Input
          label="Bird Type"
          placeholder="e.g. Broiler"
          error={errors.birdType?.message}
          {...register('birdType')}
        />
        <Input
          label="Breed"
          placeholder="e.g. Cobb 500"
          error={errors.breed?.message}
          {...register('breed')}
        />
        <Input
          label="Supplier"
          placeholder="Chick supplier"
          error={errors.supplier?.message}
          {...register('supplier')}
        />
        <div className="hidden sm:block"></div>
        <Input
          label="Total Birds (Initial)"
          type="number"
          min={1}
          error={errors.totalBirds?.message}
          {...register('totalBirds')}
        />
        <Input
          label="Arrival Date"
          type="date"
          error={errors.arrivalDate?.message}
          {...register('arrivalDate')}
        />
        <Input
          label="Expected Market Date"
          type="date"
          error={errors.expectedMarketDate?.message}
          {...register('expectedMarketDate')}
        />
      </div>
      <Textarea
        label="Notes (optional)"
        placeholder="Any additional information…"
        {...register('notes')}
      />
      <div className="flex gap-3 justify-end pt-2">
        <Button type="button" variant="outline" onClick={onCancel}>
          Cancel
        </Button>
        <Button type="submit" loading={loading}>
          {defaultValues ? 'Save Changes' : 'Add Batch'}
        </Button>
      </div>
    </form>
  );
}

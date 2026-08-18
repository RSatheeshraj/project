'use client';

import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Input, Textarea } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';
import type { WeeklyEntry, WeeklyEntryInput } from '@/types/models';

const entrySchema = z.object({
  entryDate: z.string().min(1, 'Date is required'),
  feedConsumedKg: z.coerce.number().min(0, 'Must be 0 or more'),
  waterConsumedLitres: z.coerce.number().min(0, 'Must be 0 or more'),
  mortalityCount: z.coerce.number().min(0, 'Must be 0 or more'),
  averageWeightKg: z.coerce.number().min(0, 'Must be 0 or more'),
  temperature: z.coerce.number(),
  humidity: z.coerce.number().min(0).max(100),
  vaccination: z.string().optional().default(''),
  medicine: z.string().optional().default(''),
  notes: z.string().optional().default(''),
});

type EntryFormValues = z.infer<typeof entrySchema>;

interface EntryFormProps {
  farmId: string;
  batchId: string;
  defaultValues?: WeeklyEntry;
  onSubmit: (data: WeeklyEntryInput) => Promise<void>;
  onCancel: () => void;
  loading?: boolean;
}

export function EntryForm({ farmId, batchId, defaultValues, onSubmit, onCancel, loading }: EntryFormProps) {
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm({
    resolver: zodResolver(entrySchema),
    defaultValues: defaultValues
      ? {
          entryDate: defaultValues.entryDate?.toISOString().split('T')[0] ?? '',
          feedConsumedKg: defaultValues.feedConsumedKg,
          waterConsumedLitres: defaultValues.waterConsumedLitres,
          mortalityCount: defaultValues.mortalityCount,
          averageWeightKg: defaultValues.averageWeightKg,
          temperature: defaultValues.temperature,
          humidity: defaultValues.humidity,
          vaccination: defaultValues.vaccination,
          medicine: defaultValues.medicine,
          notes: defaultValues.notes,
        }
      : { 
          entryDate: new Date().toISOString().split('T')[0],
          feedConsumedKg: 0,
          waterConsumedLitres: 0,
          mortalityCount: 0,
          averageWeightKg: 0,
          temperature: 25,
          humidity: 60,
          vaccination: '',
          medicine: '',
          notes: '',
        },
  });

  useEffect(() => {
    if (defaultValues) {
      reset({
        entryDate: defaultValues.entryDate?.toISOString().split('T')[0] ?? '',
        feedConsumedKg: defaultValues.feedConsumedKg,
        waterConsumedLitres: defaultValues.waterConsumedLitres,
        mortalityCount: defaultValues.mortalityCount,
        averageWeightKg: defaultValues.averageWeightKg,
        temperature: defaultValues.temperature,
        humidity: defaultValues.humidity,
        vaccination: defaultValues.vaccination,
        medicine: defaultValues.medicine,
        notes: defaultValues.notes,
      });
    }
  }, [defaultValues, reset]);

  const handleFormSubmit = async (values: EntryFormValues) => {
    await onSubmit({
      farmId,
      batchId,
      entryDate: new Date(values.entryDate),
      feedConsumedKg: values.feedConsumedKg,
      waterConsumedLitres: values.waterConsumedLitres,
      mortalityCount: values.mortalityCount,
      averageWeightKg: values.averageWeightKg,
      temperature: values.temperature,
      humidity: values.humidity,
      vaccination: values.vaccination ?? '',
      medicine: values.medicine ?? '',
      notes: values.notes ?? '',
    });
  };

  return (
    <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-4">
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <Input
          label="Entry Date"
          type="date"
          error={errors.entryDate?.message}
          {...register('entryDate')}
        />
        <Input
          label="Feed Consumed (Kg)"
          type="number"
          step="0.1"
          min={0}
          error={errors.feedConsumedKg?.message}
          {...register('feedConsumedKg')}
        />
        <Input
          label="Water Consumed (Litres)"
          type="number"
          step="0.1"
          min={0}
          error={errors.waterConsumedLitres?.message}
          {...register('waterConsumedLitres')}
        />
        <Input
          label="Mortality Count"
          type="number"
          min={0}
          error={errors.mortalityCount?.message}
          {...register('mortalityCount')}
        />
        <Input
          label="Average Weight (Kg)"
          type="number"
          step="0.01"
          min={0}
          error={errors.averageWeightKg?.message}
          {...register('averageWeightKg')}
        />
        <Input
          label="Temperature (°C)"
          type="number"
          step="0.1"
          error={errors.temperature?.message}
          {...register('temperature')}
        />
        <Input
          label="Humidity (%)"
          type="number"
          min={0}
          max={100}
          error={errors.humidity?.message}
          {...register('humidity')}
        />
        <div className="hidden sm:block"></div>
        <Input
          label="Vaccination"
          placeholder="e.g. ND, IB"
          error={errors.vaccination?.message}
          {...register('vaccination')}
        />
        <Input
          label="Medicine"
          placeholder="e.g. Antibiotics"
          error={errors.medicine?.message}
          {...register('medicine')}
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
          {defaultValues ? 'Save Changes' : 'Add Entry'}
        </Button>
      </div>
    </form>
  );
}

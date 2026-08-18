'use client';

import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Input, Textarea } from '@/components/ui/Input';
import { Select } from '@/components/ui/Select';
import { Button } from '@/components/ui/Button';
import type { Farm, FarmInput } from '@/types/models';

const FARM_TYPES = [
  { value: 'Broiler', label: 'Broiler' },
  { value: 'Layer', label: 'Layer' },
  { value: 'Breeder', label: 'Breeder' },
  { value: 'Turkey', label: 'Turkey' },
  { value: 'Duck', label: 'Duck' },
  { value: 'Other', label: 'Other' },
];

const farmSchema = z.object({
  name: z.string().min(2, 'Farm name must be at least 2 characters').max(80),
  type: z.string().min(1, 'Please select a farm type'),
  ownerName: z.string().min(2, 'Owner name is required').max(80),
  phone: z.string().min(6, 'Phone number is required').max(20),
  address: z.string().min(3, 'Address is required').max(200),
  sheds: z.coerce.number().min(0, 'Sheds must be 0 or more').max(1000),
  capacity: z.coerce.number().min(0, 'Capacity must be 0 or more').max(10_000_000),
  notes: z.string().max(500).optional().default(''),
  status: z.string().optional().default('Active'),
});

type FarmFormValues = z.infer<typeof farmSchema>;

interface FarmFormProps {
  defaultValues?: Farm;
  onSubmit: (data: FarmInput) => Promise<void>;
  onCancel: () => void;
  loading?: boolean;
}

export function FarmForm({ defaultValues, onSubmit, onCancel, loading }: FarmFormProps) {
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm({
    resolver: zodResolver(farmSchema),
    defaultValues: defaultValues
      ? {
          name: defaultValues.name,
          type: defaultValues.type,
          ownerName: defaultValues.ownerName,
          phone: defaultValues.phone,
          address: defaultValues.address,
          sheds: defaultValues.sheds,
          capacity: defaultValues.capacity,
          notes: defaultValues.notes,
          status: defaultValues.status || 'Active',
        }
      : { sheds: 0, capacity: 0, notes: '', status: 'Active' },
  });

  useEffect(() => {
    if (defaultValues) reset(defaultValues);
  }, [defaultValues, reset]);

  const handleFormSubmit = async (values: FarmFormValues) => {
    await onSubmit({
      name: values.name,
      type: values.type,
      ownerName: values.ownerName,
      phone: values.phone,
      address: values.address,
      sheds: values.sheds,
      capacity: values.capacity,
      notes: values.notes ?? '',
      status: values.status,
    });
  };

  const STATUS_OPTIONS = [
    { value: 'Active', label: 'Active' },
    { value: 'Completed', label: 'Completed' },
    { value: 'Closed', label: 'Closed' },
    { value: 'Archived', label: 'Archived' },
  ];

  return (
    <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-4">
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <Input
          label="Farm Name"
          placeholder="e.g. Green Valley Farm"
          error={errors.name?.message}
          {...register('name')}
        />
        <Select
          label="Farm Type"
          options={FARM_TYPES}
          placeholder="Select type…"
          error={errors.type?.message}
          {...register('type')}
        />
        <Select
          label="Status"
          options={STATUS_OPTIONS}
          placeholder="Select status…"
          error={errors.status?.message}
          {...register('status')}
        />
        <Input
          label="Owner Name"
          placeholder="Full name"
          error={errors.ownerName?.message}
          {...register('ownerName')}
        />
        <Input
          label="Phone"
          type="tel"
          placeholder="+91 9876543210"
          error={errors.phone?.message}
          {...register('phone')}
        />
        <Input
          label="Number of Sheds"
          type="number"
          min={0}
          error={errors.sheds?.message}
          {...register('sheds')}
        />
        <Input
          label="Total Capacity (Birds)"
          type="number"
          min={0}
          error={errors.capacity?.message}
          {...register('capacity')}
        />
      </div>
      <Textarea
        label="Address"
        placeholder="Full address"
        error={errors.address?.message}
        {...register('address')}
      />
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
          {defaultValues ? 'Save Changes' : 'Add Farm'}
        </Button>
      </div>
    </form>
  );
}

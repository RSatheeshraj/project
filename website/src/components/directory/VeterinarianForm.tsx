'use client';

import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Input, Textarea } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';
import type { Veterinarian, VeterinarianInput } from '@/types/models';

const vetSchema = z.object({
  doctorName: z.string().min(2, 'Name must be at least 2 characters').max(80),
  phoneNumber: z.string().min(1, 'Phone number is required').max(20),
  whatsappNumber: z.string().min(1, 'WhatsApp number is required').max(20),
  email: z.string().email('Invalid email address').max(100).or(z.literal('')),
  address: z.string().min(1, 'Clinic/Address is required').max(200),
  isEmergency: z.boolean(),
});

type VetFormValues = z.infer<typeof vetSchema>;

interface VeterinarianFormProps {
  defaultValues?: Veterinarian;
  onSubmit: (data: VeterinarianInput) => Promise<void>;
  onCancel: () => void;
  loading?: boolean;
}

export function VeterinarianForm({ defaultValues, onSubmit, onCancel, loading }: VeterinarianFormProps) {
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<VetFormValues>({
    resolver: zodResolver(vetSchema),
    defaultValues: defaultValues
      ? {
          doctorName: defaultValues.doctorName,
          phoneNumber: defaultValues.phoneNumber,
          whatsappNumber: defaultValues.whatsappNumber,
          email: defaultValues.email,
          address: defaultValues.address,
          isEmergency: defaultValues.isEmergency ?? false,
        }
      : {
          doctorName: '',
          phoneNumber: '',
          whatsappNumber: '',
          email: '',
          address: '',
          isEmergency: false,
        },
  });

  useEffect(() => {
    if (defaultValues) {
      reset({
        doctorName: defaultValues.doctorName,
        phoneNumber: defaultValues.phoneNumber,
        whatsappNumber: defaultValues.whatsappNumber,
        email: defaultValues.email,
        address: defaultValues.address,
        isEmergency: defaultValues.isEmergency ?? false,
      });
    }
  }, [defaultValues, reset]);

  const handleFormSubmit = async (data: VetFormValues) => {
    let cleanEmail = (data.email || '').trim();
    if (cleanEmail.toLowerCase().startsWith('mailto:')) {
      cleanEmail = cleanEmail.substring(7);
    }
    if (cleanEmail.toLowerCase().startsWith('https://')) {
      cleanEmail = cleanEmail.substring(8);
    }
    
    await onSubmit({
      doctorName: data.doctorName,
      phoneNumber: data.phoneNumber,
      whatsappNumber: data.whatsappNumber,
      email: cleanEmail,
      address: data.address,
      isEmergency: data.isEmergency,
    });
  };

  return (
    <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-4">
      <Input
        label="Doctor Name"
        {...register('doctorName')}
        error={errors.doctorName?.message}
        placeholder="e.g. Dr. Sarah Jenkins"
      />

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Input
          label="Phone Number"
          type="tel"
          {...register('phoneNumber')}
          error={errors.phoneNumber?.message}
          placeholder="+1234567890"
        />

        <Input
          label="WhatsApp Number"
          type="tel"
          {...register('whatsappNumber')}
          error={errors.whatsappNumber?.message}
          placeholder="+1234567890"
        />
      </div>

      <Input
        label="Email Address"
        type="email"
        {...register('email')}
        error={errors.email?.message}
        placeholder="vet@clinic.com"
      />

      <Textarea
        label="Clinic / Address"
        {...register('address')}
        error={errors.address?.message}
        placeholder="123 Vet Road, City"
        rows={2}
      />

      <div className="flex items-center gap-2">
        <input 
          type="checkbox" 
          id="isEmergency"
          {...register('isEmergency')}
          className="w-4 h-4 rounded border-border bg-background text-[#F4A900] focus:ring-[#F4A900] focus:ring-offset-background"
        />
        <label htmlFor="isEmergency" className="text-sm font-medium text-foreground">
          Available for Emergency
        </label>
      </div>

      <div className="flex justify-end gap-3 pt-4 border-t border-border/50">
        <Button type="button" variant="outline" onClick={onCancel} disabled={loading}>
          Cancel
        </Button>
        <Button type="submit" disabled={loading}>
          {loading ? 'Saving...' : 'Save Veterinarian'}
        </Button>
      </div>
    </form>
  );
}

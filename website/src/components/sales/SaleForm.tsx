'use client';

import { useForm, useWatch } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { Button } from '@/components/ui/Button';
import { useFarms } from '@/hooks/useFarms';
import { useBatches } from '@/hooks/useBatches';
import { useEntries } from '@/hooks/useEntries';
import { useSales } from '@/hooks/useSales';
import { calculateTotalMortality, calculateTotalBirdsSold, calculateRemainingBirds } from '@/lib/calculations';
import { useToast } from '@/components/ui/Toast';
import type { SaleInput, Sale } from '@/types/models';
import { useState } from 'react';

const schema = z.object({
  farmId: z.string().min(1, 'Farm is required'),
  batchId: z.string().min(1, 'Batch is required'),
  saleDate: z.string().min(1, 'Sale Date is required'),
  birdsSold: z.number().min(1, 'Must be at least 1'),
  averageWeight: z.number().min(0.1, 'Must be at least 0.1'),
  pricePerKg: z.number().min(1, 'Price per kg is required'),
  buyerName: z.string().min(1, 'Buyer Name is required'),
  buyerContact: z.string().min(1, 'Buyer Contact is required'),
  invoiceNumber: z.string(),
  notes: z.string(),
});

type FormValues = z.infer<typeof schema>;

export function SaleForm({
  defaultValues,
  onSubmit,
  onCancel,
  loading = false,
}: {
  defaultValues?: Sale;
  onSubmit: (data: SaleInput) => Promise<void>;
  onCancel: () => void;
  loading?: boolean;
}) {
  const { data: farms } = useFarms();
  const [selectedFarm, setSelectedFarm] = useState<string>(defaultValues?.farmId || (farms?.[0]?.id ?? ''));
  const { data: batches } = useBatches(selectedFarm);
  const { toast } = useToast();

  const { register, handleSubmit, control, formState: { errors } } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      farmId: defaultValues?.farmId || '',
      batchId: defaultValues?.batchId || '',
      saleDate: defaultValues?.saleDate ? defaultValues.saleDate.toISOString().substring(0, 10) : new Date().toISOString().substring(0, 10),
      birdsSold: defaultValues?.birdsSold || 0,
      averageWeight: defaultValues?.averageWeight || 0,
      pricePerKg: defaultValues?.pricePerKg || 0,
      buyerName: defaultValues?.buyerName || '',
      buyerContact: defaultValues?.buyerContact || '',
      invoiceNumber: defaultValues?.invoiceNumber || '',
      notes: defaultValues?.notes || '',
    },
  });

  const watchBatchId = useWatch({ control, name: 'batchId' });
  const { data: entries } = useEntries(selectedFarm, watchBatchId);
  const { data: sales } = useSales(selectedFarm, watchBatchId);

  const submitHandler = async (data: FormValues) => {
    const selectedBatch = batches?.find(b => b.id === data.batchId);
    if (selectedBatch) {
      const mortality = calculateTotalMortality(entries || []);
      const otherSales = (sales || []).filter(s => s.id !== defaultValues?.id);
      const prevBirdsSold = calculateTotalBirdsSold(otherSales);
      const remainingBirds = calculateRemainingBirds(selectedBatch.totalBirds, mortality, prevBirdsSold);
      
      if (data.birdsSold > remainingBirds) {
        toast(`Birds sold cannot exceed the remaining birds available in this batch (${remainingBirds}).`, 'error');
        return;
      }
    }

    await onSubmit({
      ...data,
      saleDate: new Date(data.saleDate),
    });
  };

  return (
    <form onSubmit={handleSubmit(submitHandler)} className="space-y-4">
      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Farm</label>
          <select
            {...register('farmId')}
            className="w-full h-10 px-3 rounded-lg border border-border bg-background text-sm"
            onChange={(e) => setSelectedFarm(e.target.value)}
          >
            <option value="">Select a farm</option>
            {farms?.map((f) => (
              <option key={f.id} value={f.id}>{f.name}</option>
            ))}
          </select>
          {errors.farmId && <p className="text-red-400 text-xs">{errors.farmId.message}</p>}
        </div>

        <div className="space-y-2">
          <label className="text-sm font-medium">Batch</label>
          <select
            {...register('batchId')}
            className="w-full h-10 px-3 rounded-lg border border-border bg-background text-sm"
          >
            <option value="">Select a batch</option>
            {batches?.map((b) => (
              <option key={b.id} value={b.id}>{b.batchName}</option>
            ))}
          </select>
          {errors.batchId && <p className="text-red-400 text-xs">{errors.batchId.message}</p>}
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Sale Date</label>
          <input
            type="date"
            {...register('saleDate')}
            className="w-full h-10 px-3 rounded-lg border border-border bg-background text-sm"
          />
          {errors.saleDate && <p className="text-red-400 text-xs">{errors.saleDate.message}</p>}
        </div>
        
        <div className="space-y-2">
          <label className="text-sm font-medium">Birds Sold</label>
          <input
            type="number"
            {...register('birdsSold', { valueAsNumber: true })}
            className="w-full h-10 px-3 rounded-lg border border-border bg-background text-sm"
          />
          {errors.birdsSold && <p className="text-red-400 text-xs">{errors.birdsSold.message}</p>}
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Avg Weight (kg)</label>
          <input
            type="number"
            step="0.01"
            {...register('averageWeight', { valueAsNumber: true })}
            className="w-full h-10 px-3 rounded-lg border border-border bg-background text-sm"
          />
          {errors.averageWeight && <p className="text-red-400 text-xs">{errors.averageWeight.message}</p>}
        </div>
        
        <div className="space-y-2">
          <label className="text-sm font-medium">Price per kg (₹)</label>
          <input
            type="number"
            step="0.01"
            {...register('pricePerKg', { valueAsNumber: true })}
            className="w-full h-10 px-3 rounded-lg border border-border bg-background text-sm"
          />
          {errors.pricePerKg && <p className="text-red-400 text-xs">{errors.pricePerKg.message}</p>}
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <label className="text-sm font-medium">Buyer Name</label>
          <input
            {...register('buyerName')}
            className="w-full h-10 px-3 rounded-lg border border-border bg-background text-sm"
          />
          {errors.buyerName && <p className="text-red-400 text-xs">{errors.buyerName.message}</p>}
        </div>
        
        <div className="space-y-2">
          <label className="text-sm font-medium">Buyer Contact</label>
          <input
            {...register('buyerContact')}
            className="w-full h-10 px-3 rounded-lg border border-border bg-background text-sm"
          />
          {errors.buyerContact && <p className="text-red-400 text-xs">{errors.buyerContact.message}</p>}
        </div>
      </div>

      <div className="space-y-2">
        <label className="text-sm font-medium">Invoice Number</label>
        <input
          {...register('invoiceNumber')}
          className="w-full h-10 px-3 rounded-lg border border-border bg-background text-sm"
        />
      </div>

      <div className="space-y-2">
        <label className="text-sm font-medium">Notes</label>
        <textarea
          {...register('notes')}
          className="w-full h-20 p-3 rounded-lg border border-border bg-background text-sm resize-none"
        />
      </div>

      <div className="flex gap-3 justify-end pt-4">
        <Button type="button" variant="ghost" onClick={onCancel}>
          Cancel
        </Button>
        <Button type="submit" disabled={loading} style={{ background: 'linear-gradient(135deg, #F4A900, #d4920a)', color: '#1A1200' }}>
          {loading ? 'Saving...' : 'Save Sale'}
        </Button>
      </div>
    </form>
  );
}

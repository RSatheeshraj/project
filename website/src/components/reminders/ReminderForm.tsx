import React, { useState } from 'react';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Select } from '@/components/ui/Select';
import { useFarms } from '@/hooks/useFarms';
import { useBatches } from '@/hooks/useBatches';
import type { Reminder, ReminderInput, Farm, Batch } from '@/types/models';

interface ReminderFormProps {
  defaultValues?: Reminder;
  onSubmit: (data: ReminderInput) => Promise<void>;
  onCancel: () => void;
  loading?: boolean;
}

const CATEGORIES = ['Vaccination', 'Feed', 'Medicine', 'Weekly Entry', 'AI Scan', 'Custom'];
const STATUSES = ['Pending', 'Completed'];

export function ReminderForm({ defaultValues, onSubmit, onCancel, loading }: ReminderFormProps) {
  const { data: farms = [] } = useFarms();
  const activeFarms = farms.filter((f: Farm) => !['completed', 'closed', 'archived'].includes((f.status || 'Active').trim().toLowerCase()));
  const [farmId, setFarmId] = useState(defaultValues?.farmId || (activeFarms.length > 0 ? activeFarms[0].id : ''));
  
  const { data: batches = [] } = useBatches(farmId);

  const [title, setTitle] = useState(defaultValues?.title || '');
  const [description, setDescription] = useState(defaultValues?.description || '');
  const [category, setCategory] = useState(defaultValues?.category || 'Custom');
  const [dueDate, setDueDate] = useState(
    defaultValues?.dueDate ? defaultValues.dueDate.toISOString().split('T')[0] : new Date().toISOString().split('T')[0]
  );
  const [status, setStatus] = useState<'Pending' | 'Completed'>(defaultValues?.status || 'Pending');
  const [batchId, setBatchId] = useState(defaultValues?.batchId || '');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!farmId || !title || !category || !dueDate || !status) return;

    await onSubmit({
      farmId,
      batchId: batchId || undefined,
      title,
      description,
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      category: category as any,
      dueDate: new Date(dueDate),
      status,
    });
  };

  const isEditing = !!defaultValues;
  const originalFarm = farms.find((f: Farm) => f.id === defaultValues?.farmId);
  const isOriginalFarmCompleted = isEditing && originalFarm && ['completed', 'closed', 'archived'].includes((originalFarm.status || 'Active').trim().toLowerCase());

  
  
  // If editing a completed farm, only show that farm (it will be disabled anyway)
  // Otherwise, show active farms. If editing an active farm, we can still show active farms.
  const farmOptions = isOriginalFarmCompleted
    ? (originalFarm ? [{ label: originalFarm.name, value: originalFarm.id }] : [])
    : activeFarms.map((farm: Farm) => ({ label: farm.name, value: farm.id }));

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <Select
        label="Farm"
        value={farmId}
        onChange={(e) => setFarmId(e.target.value)}
        required
        placeholder="Select a farm"
        options={farmOptions}
        disabled={isOriginalFarmCompleted}
      />

      <Select
        label="Batch (Optional)"
        value={batchId}
        onChange={(e) => setBatchId(e.target.value)}
        placeholder="Select a batch"
        options={batches.map((batch: Batch) => ({ label: batch.batchName, value: batch.id }))}
      />

      <Input
        label="Title"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        required
        placeholder="e.g. Newcastle Disease Vaccination"
      />

      <Select
        label="Category"
        value={category}
        onChange={(e) => setCategory(e.target.value as Reminder['category'])}
        required
        options={CATEGORIES.map(cat => ({ label: cat, value: cat }))}
      />

      <div className="space-y-1">
        <label className="block text-sm font-medium text-foreground">Description</label>
        <textarea
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          rows={3}
          className="w-full rounded-xl border border-border bg-background px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#F4A900]/50 transition-shadow"
          placeholder="Detailed description or notes..."
        />
      </div>

      <Input
        label="Due Date"
        type="date"
        value={dueDate}
        onChange={(e) => setDueDate(e.target.value)}
        required
      />

      <Select
        label="Status"
        value={status}
        onChange={(e) => setStatus(e.target.value as 'Pending' | 'Completed')}
        required
        options={STATUSES.map(s => ({ label: s, value: s }))}
      />

      <div className="flex justify-end gap-3 pt-4">
        <Button type="button" variant="outline" onClick={onCancel}>
          Cancel
        </Button>
        <Button type="submit" disabled={loading}>
          {loading ? 'Saving...' : 'Save Reminder'}
        </Button>
      </div>
    </form>
  );
}

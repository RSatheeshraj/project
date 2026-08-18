'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { FileText, Calendar, Edit2, Trash2, ChevronRight, Activity } from 'lucide-react';
import { useRouter } from 'next/navigation';
import type { Batch } from '@/types/models';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { ConfirmModal } from '@/components/ui/Modal';
import { useDeleteBatch } from '@/hooks/useBatches';
import { useToast } from '@/components/ui/Toast';
import { formatDate } from '@/lib/utils';
import { calculateBatchAge } from '@/lib/calculations';

interface BatchCardProps {
  batch: Batch;
  remainingBirds: number;
  onEdit?: (batch: Batch) => void;
  isFarmCompleted?: boolean;
}

export function BatchCard({ batch, remainingBirds, onEdit, isFarmCompleted }: BatchCardProps) {
  const router = useRouter();
  const { toast } = useToast();
  const deleteMutation = useDeleteBatch();
  const [confirmDelete, setConfirmDelete] = useState(false);

  const handleDelete = async () => {
    try {
      await deleteMutation.mutateAsync({ farmId: batch.farmId, batchId: batch.id });
      toast('Batch deleted successfully', 'success');
      setConfirmDelete(false);
    } catch {
      toast('Failed to delete batch', 'error');
    }
  };

  const getStatusColor = (status: string) => {
    switch(status.toLowerCase()) {
      case 'active': return 'default';
      case 'completed': return 'success';
      case 'sold': return 'outline';
      default: return 'default';
    }
  };

  return (
    <>
      <motion.div
        className="rounded-2xl border border-border bg-card p-5 hover:border-primary/30 transition-all group"
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        whileHover={{ y: -2 }}
        transition={{ type: 'spring', stiffness: 350, damping: 30 }}
      >
        {/* Header */}
        <div className="flex items-start justify-between mb-4">
          <div className="flex items-center gap-3">
            <div
              className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0"
              style={{ background: 'rgba(244,169,0,0.12)', border: '1px solid rgba(244,169,0,0.2)' }}
            >
              <FileText className="w-5 h-5" style={{ color: '#F4A900' }} />
            </div>
            <div>
              <h3 className="font-semibold text-foreground leading-tight">{batch.batchName}</h3>
              <p className="text-xs text-muted-foreground mt-0.5">{batch.birdType} - {batch.breed}</p>
            </div>
          </div>
          <Badge variant={getStatusColor(batch.status) as "default" | "success" | "outline" | "destructive" | "secondary"}>{batch.status}</Badge>
        </div>

        {/* Details */}
        <div className="space-y-2 mb-4">
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <Activity className="w-3.5 h-3.5 shrink-0" />
            <span>Age: {calculateBatchAge(batch.arrivalDate)}</span>
          </div>
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <Calendar className="w-3.5 h-3.5 shrink-0" />
            <span>Arrival: {batch.arrivalDate ? formatDate(batch.arrivalDate) : 'N/A'}</span>
          </div>
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <span className="w-3.5 h-3.5 shrink-0 inline-flex items-center justify-center font-bold text-[10px]">#</span>
            <span>Birds: {remainingBirds.toLocaleString()} / {batch.totalBirds.toLocaleString()}</span>
          </div>
        </div>

        {/* Actions */}
        <div className="flex items-center gap-2 pt-3 border-t border-border">
          <Button
            size="sm"
            variant="ghost"
            onClick={() => router.push(`/farms/${batch.farmId}/batches/${batch.id}`)}
            className="flex-1 justify-between"
          >
            Weekly Entries <ChevronRight className="w-3.5 h-3.5" />
          </Button>
          <div title={isFarmCompleted ? "This farm has been completed." : ""}>
            <Button
              size="icon"
              variant="ghost"
              onClick={() => onEdit?.(batch)}
              aria-label="Edit batch"
              disabled={isFarmCompleted || !onEdit}
            >
              <Edit2 className="w-3.5 h-3.5" />
            </Button>
          </div>
          <div title={isFarmCompleted ? "This farm has been completed." : ""}>
            <Button
              size="icon"
              variant="ghost"
              onClick={() => setConfirmDelete(true)}
              aria-label="Delete batch"
              className="text-muted-foreground hover:text-red-400 hover:bg-red-500/10"
              disabled={isFarmCompleted}
            >
              <Trash2 className="w-3.5 h-3.5" />
            </Button>
          </div>
        </div>
      </motion.div>

      <ConfirmModal
        open={confirmDelete}
        onClose={() => setConfirmDelete(false)}
        onConfirm={handleDelete}
        title="Delete Batch"
        description={`Are you sure you want to delete "${batch.batchName}"? This action cannot be undone.`}
        confirmLabel="Delete"
        loading={deleteMutation.isPending}
        destructive
      />
    </>
  );
}

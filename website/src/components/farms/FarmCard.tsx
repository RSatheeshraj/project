'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { Building2, Users, Package, MapPin, Edit2, Trash2, ChevronRight } from 'lucide-react';
import { useRouter } from 'next/navigation';
import type { Farm } from '@/types/models';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { ConfirmModal } from '@/components/ui/Modal';
import { useDeleteFarm } from '@/hooks/useFarms';
import { useToast } from '@/components/ui/Toast';
import { formatDate } from '@/lib/utils';

interface FarmCardProps {
  farm: Farm;
  onEdit: (farm: Farm) => void;
}

import { FarmStatusBadge } from '@/components/common/FarmStatusBadge';

export function FarmCard({ farm, onEdit }: FarmCardProps) {
  const router = useRouter();
  const { toast } = useToast();
  const deleteMutation = useDeleteFarm();
  const [confirmDelete, setConfirmDelete] = useState(false);

  const normalizedStatus = (farm.status || 'Active').trim().toLowerCase();
  const isCompleted = ['completed', 'closed', 'archived'].includes(normalizedStatus);

  const handleDelete = async () => {
    try {
      await deleteMutation.mutateAsync(farm.id);
      toast('Farm deleted successfully', 'success');
      setConfirmDelete(false);
    } catch {
      toast('Failed to delete farm', 'error');
    }
  };

  return (
    <>
      <motion.div
        className="rounded-2xl border border-border bg-card p-5 hover:border-primary/30 transition-all group relative overflow-hidden"
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        whileHover={{ y: -2 }}
        transition={{ type: 'spring', stiffness: 350, damping: 30 }}
      >
        {isCompleted && (
          <div className="absolute top-0 right-0 w-16 h-16 pointer-events-none opacity-5">
            <div className="w-full h-full bg-green-500 rounded-bl-[100px]" />
          </div>
        )}

        {/* Header */}
        <div className="flex items-start justify-between mb-4 relative z-10">
          <div className="flex items-center gap-3">
            <div
              className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0"
              style={{ background: 'rgba(244,169,0,0.12)', border: '1px solid rgba(244,169,0,0.2)' }}
            >
              <Building2 className="w-5 h-5" style={{ color: '#F4A900' }} />
            </div>
            <div>
              <h3 className="font-semibold text-foreground leading-tight">{farm.name}</h3>
              <p className="text-xs text-muted-foreground mt-0.5">{formatDate(farm.createdAt)}</p>
            </div>
          </div>
          <div className="flex flex-col items-end gap-1">
            <FarmStatusBadge status={farm.status} />
            <Badge variant="default" className="text-[10px] py-0">{farm.type}</Badge>
          </div>
        </div>

        {/* Details */}
        <div className="space-y-2 mb-4 relative z-10">
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <Users className="w-3.5 h-3.5 shrink-0" />
            <span className="truncate">{farm.ownerName}</span>
          </div>
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <MapPin className="w-3.5 h-3.5 shrink-0" />
            <span className="truncate">{farm.address || '—'}</span>
          </div>
          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <Package className="w-3.5 h-3.5 shrink-0" />
            <span>
              {farm.sheds} shed{farm.sheds !== 1 ? 's' : ''} · {farm.capacity.toLocaleString()} birds capacity
            </span>
          </div>
        </div>

        {/* Actions */}
        <div className="flex items-center gap-2 pt-3 border-t border-border relative z-10">
          <Button
            size="sm"
            variant="ghost"
            onClick={() => router.push(`/farms/${farm.id}`)}
            className="flex-1 justify-between"
          >
            View Details <ChevronRight className="w-3.5 h-3.5" />
          </Button>
          <div title={isCompleted ? "This farm has been completed." : ""}>
            <Button
              size="icon"
              variant="ghost"
              onClick={() => onEdit(farm)}
              aria-label="Edit farm"
              disabled={isCompleted}
            >
              <Edit2 className="w-3.5 h-3.5" />
            </Button>
          </div>
          <div title={isCompleted ? "This farm has been completed." : ""}>
            <Button
              size="icon"
              variant="ghost"
              onClick={() => setConfirmDelete(true)}
              aria-label="Delete farm"
              className="text-muted-foreground hover:text-red-400 hover:bg-red-500/10"
              disabled={isCompleted}
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
        title="Delete Farm"
        description={`Are you sure you want to delete "${farm.name}"? This action cannot be undone.`}
        confirmLabel="Delete"
        loading={deleteMutation.isPending}
        destructive
      />
    </>
  );
}

'use client';

import { useState } from 'react';
import { useEntries, useAddEntry, useUpdateEntry, useDeleteEntry } from '@/hooks/useEntries';
import { EntryForm } from '@/components/entries/EntryForm';
import { EntriesChart } from '@/components/entries/EntriesChart';
import { Modal, ConfirmModal } from '@/components/ui/Modal';
import { LoadingScreen } from '@/components/common/LoadingScreen';
import { ErrorState } from '@/components/ui/States';
import { Button } from '@/components/ui/Button';
import type { WeeklyEntry, WeeklyEntryInput } from '@/types/models';
import { useToast } from '@/components/ui/Toast';
import { ArrowLeft, Edit2, Trash2, Droplet, Wheat, Thermometer, Wind } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { useFarms } from '@/hooks/useFarms';
import { useBatch } from '@/hooks/useBatches';
import { useScanHistory } from '@/hooks/useScanHistory';
import { generateWeeklyReportPdf } from '@/lib/pdf';
import { Download, Printer } from 'lucide-react';
import { formatDate } from '@/lib/utils';
import { calculateProductionWeek } from '@/lib/calculations';
import { useAuth } from '@/contexts/AuthContext';
import { FarmStatusBanner } from '@/components/common/FarmStatusBanner';

export function EntriesClient({ farmId, batchId }: { farmId: string; batchId: string }) {
  const { userProfile } = useAuth();
  const router = useRouter();
  const { data: entries, isLoading, error } = useEntries(farmId, batchId);
  const addEntry = useAddEntry();
  const updateEntry = useUpdateEntry();
  const deleteMutation = useDeleteEntry();
  const { toast } = useToast();

  const { data: farms } = useFarms();
  const farm = farms?.find(f => f.id === farmId);
  const normalizedStatus = (farm?.status || 'Active').trim().toLowerCase();
  const isFarmCompleted = ['completed', 'closed', 'archived'].includes(normalizedStatus);

  const { data: batch } = useBatch(farmId, batchId);
  const { data: allScans } = useScanHistory();

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingEntry, setEditingEntry] = useState<WeeklyEntry | undefined>();
  
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [entryToDelete, setEntryToDelete] = useState<WeeklyEntry | undefined>();

  if (isLoading) return <LoadingScreen />;
  if (error) return <ErrorState title="Failed to load entries" />;

  const handleOpenModal = (entry?: WeeklyEntry) => {
    setEditingEntry(entry);
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setEditingEntry(undefined);
  };

  const handleSubmit = async (data: WeeklyEntryInput) => {
    try {
      if (editingEntry) {
        await updateEntry.mutateAsync({ ...editingEntry, ...data });
        toast('Entry updated successfully', 'success');
      } else {
        await addEntry.mutateAsync(data);
        toast('Entry added successfully', 'success');
      }
      handleCloseModal();
    } catch {
      toast('Failed to save entry', 'error');
    }
  };
  
  const handleDelete = async () => {
    if (!entryToDelete) return;
    try {
      await deleteMutation.mutateAsync({ farmId, batchId, entryId: entryToDelete.id });
      toast('Entry deleted successfully', 'success');
      setConfirmDelete(false);
      setEntryToDelete(undefined);
    } catch {
      toast('Failed to delete entry', 'error');
    }
  };

  const handleGeneratePdf = async (entry: WeeklyEntry, action: 'download' | 'print') => {
    if (!farm || !batch) {
      toast('Missing farm or batch data.', 'error');
      return;
    }
    try {
      // Get scans for that week (simple approach: scans created in the 7 days prior to entryDate)

      const entryTime = entry.entryDate?.getTime() || new Date().getTime();
      const weekBefore = entryTime - 7 * 24 * 60 * 60 * 1000;
      
      const scansForWeek = (allScans || []).filter(scan => {
        if (!scan.createdAt) return false;
        const scanTime = scan.createdAt.getTime();
        return scan.batchId === batchId && scanTime >= weekBefore && scanTime <= entryTime;
      });

      const doc = await generateWeeklyReportPdf(farm, batch, [entry], scansForWeek, userProfile);
      
      if (action === 'download') {
        doc.save(`Weekly_Report_${batch.batchName}_${formatDate(new Date())}.pdf`);
        toast('PDF generated successfully', 'success');
      } else {
        doc.autoPrint();
        const blobUrl = doc.output('bloburl');
        window.open(blobUrl, '_blank');
      }
    } catch (err) {
      console.error(err);
      toast('Failed to generate PDF', 'error');
    }
  };

  return (
    <div className="space-y-6">
      <FarmStatusBanner status={farm?.status} />
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" onClick={() => router.push(`/farms/${farmId}`)}>
          <ArrowLeft className="w-5 h-5" />
        </Button>
        <div>
          <h2 className="text-2xl font-bold text-foreground">Weekly Entries</h2>
          <p className="text-muted-foreground text-sm mt-1">Track metrics for this batch.</p>
        </div>
        <div className="flex-1" />
        <div title={isFarmCompleted ? "This farm has been completed." : ""}>
          <Button 
            onClick={() => handleOpenModal()} 
            style={{ background: 'linear-gradient(135deg, #F4A900, #d4920a)', color: '#1A1200' }}
            disabled={isFarmCompleted}
          >
            + Add Entry
          </Button>
        </div>
      </div>

      {entries && entries.length > 0 ? (
        <>
          <div className="rounded-2xl p-6 glass mb-6">
            <h3 className="font-semibold mb-2">Growth & Health Trends</h3>
            <p className="text-sm text-muted-foreground mb-4">Track mortality and average weight over time.</p>
            <EntriesChart entries={entries} />
          </div>
          
          <div className="space-y-4">
            {entries.map((entry) => (
            <div key={entry.id} className="rounded-2xl border border-border bg-card p-5 glass group transition-all">
              <div className="flex justify-between items-start mb-4">
                <div>
                  <div className="flex items-center gap-2">
                    <h3 className="font-bold text-lg">{calculateProductionWeek(batch?.arrivalDate, entry.entryDate)}</h3>
                    <span className="text-sm text-muted-foreground">({entry.entryDate ? formatDate(entry.entryDate) : 'Unknown Date'})</span>
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">Mortality: <span className="text-red-400 font-semibold">{entry.mortalityCount} birds</span></p>
                </div>
                <div className="flex gap-2">
                  <Button size="icon" variant="ghost" title="Download PDF" onClick={() => handleGeneratePdf(entry, 'download')}>
                    <Download className="w-4 h-4 text-blue-500" />
                  </Button>
                  <Button size="icon" variant="ghost" title="Print" onClick={() => handleGeneratePdf(entry, 'print')}>
                    <Printer className="w-4 h-4 text-emerald-500" />
                  </Button>
                  <div title={isFarmCompleted ? "This farm has been completed." : ""}>
                    <Button size="icon" variant="ghost" onClick={() => handleOpenModal(entry)} disabled={isFarmCompleted}>
                      <Edit2 className="w-4 h-4" />
                    </Button>
                  </div>
                  <div title={isFarmCompleted ? "This farm has been completed." : ""}>
                    <Button size="icon" variant="ghost" className="text-muted-foreground hover:text-red-400 hover:bg-red-500/10" onClick={() => {
                      setEntryToDelete(entry);
                      setConfirmDelete(true);
                    }} disabled={isFarmCompleted}>
                      <Trash2 className="w-4 h-4" />
                    </Button>
                  </div>
                </div>
              </div>
              
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div className="flex items-center gap-2 text-sm">
                  <Wheat className="w-4 h-4 text-amber-500" />
                  <span>{entry.feedConsumedKg} kg Feed</span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <Droplet className="w-4 h-4 text-blue-500" />
                  <span>{entry.waterConsumedLitres} L Water</span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <Thermometer className="w-4 h-4 text-orange-500" />
                  <span>{entry.temperature}°C</span>
                </div>
                <div className="flex items-center gap-2 text-sm">
                  <Wind className="w-4 h-4 text-cyan-500" />
                  <span>{entry.humidity}% Hum</span>
                </div>
              </div>
              
              {(entry.vaccination || entry.medicine || entry.notes) && (
                <div className="mt-4 pt-4 border-t border-border/50 text-sm space-y-2">
                  {entry.vaccination && (
                    <div className="flex gap-2">
                      <span className="font-semibold text-muted-foreground min-w-[80px]">Vaccine:</span>
                      <span>{entry.vaccination}</span>
                    </div>
                  )}
                  {entry.medicine && (
                    <div className="flex gap-2">
                      <span className="font-semibold text-muted-foreground min-w-[80px]">Medicine:</span>
                      <span>{entry.medicine}</span>
                    </div>
                  )}
                  {entry.notes && (
                    <div className="flex gap-2">
                      <span className="font-semibold text-muted-foreground min-w-[80px]">Notes:</span>
                      <span>{entry.notes}</span>
                    </div>
                  )}
                </div>
              )}
            </div>
          ))}
          </div>
        </>
      ) : (
        <div className="rounded-2xl p-8 text-center glass">
          <p className="text-muted-foreground text-sm">
            No entries found. Add your first weekly entry for this batch.
          </p>
        </div>
      )}

      <Modal
        open={isModalOpen}
        onClose={handleCloseModal}
        title={editingEntry ? 'Edit Entry' : 'Add Entry'}
      >
        <EntryForm
          farmId={farmId}
          batchId={batchId}
          defaultValues={editingEntry}
          onSubmit={handleSubmit}
          onCancel={handleCloseModal}
          loading={addEntry.isPending || updateEntry.isPending}
        />
      </Modal>
      
      <ConfirmModal
        open={confirmDelete}
        onClose={() => {
          setConfirmDelete(false);
          setEntryToDelete(undefined);
        }}
        onConfirm={handleDelete}
        title="Delete Entry"
        description="Are you sure you want to delete this entry? This action cannot be undone."
        confirmLabel="Delete"
        loading={deleteMutation.isPending}
        destructive
      />
    </div>
  );
}

'use client';

import { useBatches, useAddBatch, useUpdateBatch } from '@/hooks/useBatches';
import { useFarms } from '@/hooks/useFarms';
import { EntryRepository } from '@/repositories/entry.repository';
import { SaleRepository } from '@/repositories/sale.repository';
import { calculateTotalMortality, calculateTotalBirdsSold, calculateRemainingBirds } from '@/lib/calculations';
import type { WeeklyEntry, Sale } from '@/types/models';
import { useState, useEffect } from 'react';
import { BatchCard } from '@/components/batches/BatchCard';
import { BatchForm } from '@/components/batches/BatchForm';
import { Modal } from '@/components/ui/Modal';
import { LoadingScreen } from '@/components/common/LoadingScreen';
import { ErrorState } from '@/components/ui/States';
import { Button } from '@/components/ui/Button';
import type { Batch, BatchInput } from '@/types/models';
import { useToast } from '@/components/ui/Toast';
import { ArrowLeft, Download } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { createBrandedPDF } from '@/lib/pdf';
import autoTable from 'jspdf-autotable';
import { formatDate } from '@/lib/utils';
import { useAuth } from '@/contexts/AuthContext';
import { FarmStatusBanner } from '@/components/common/FarmStatusBanner';

export function BatchesClient({ farmId }: { farmId: string }) {
  const { userProfile } = useAuth();
  const router = useRouter();
  const { data: farms } = useFarms();
  const { data: batches, isLoading, error } = useBatches(farmId);
  const addBatch = useAddBatch();
  const updateBatch = useUpdateBatch();
  const { toast } = useToast();

  const farm = farms?.find((f) => f.id === farmId);
  const normalizedStatus = (farm?.status || 'Active').trim().toLowerCase();
  const isCompleted = ['completed', 'closed', 'archived'].includes(normalizedStatus);

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingBatch, setEditingBatch] = useState<Batch | undefined>();
  const [entries, setEntries] = useState<WeeklyEntry[]>([]);
  const [sales, setSales] = useState<Sale[]>([]);
  const [loadingStats, setLoadingStats] = useState(false);

  useEffect(() => {
    let isMounted = true;
    const fetchStats = async () => {
      if (!batches || batches.length === 0) {
        if (isMounted) {
          setEntries([]);
          setSales([]);
        }
        return;
      }
      setLoadingStats(true);
      try {
        const entryPromises = batches.map(b => EntryRepository.getEntries(b.farmId, b.id));
        const salesPromises = batches.map(b => SaleRepository.getSales(b.farmId, b.id));
        const entryResults = await Promise.all(entryPromises);
        const salesResults = await Promise.all(salesPromises);
        
        if (isMounted) {
          setEntries(entryResults.flat());
          setSales(salesResults.flat());
        }
      } catch (err) {
        console.error("Failed to fetch stats", err);
      } finally {
        if (isMounted) setLoadingStats(false);
      }
    };
    
    fetchStats();
    
    return () => {
      isMounted = false;
    };
  }, [batches]);

  if (isLoading || loadingStats) return <LoadingScreen />;
  if (error) return <ErrorState title="Failed to load batches" />;

  const handleOpenModal = (batch?: Batch) => {
    setEditingBatch(batch);
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setEditingBatch(undefined);
  };

  const handleSubmit = async (data: BatchInput) => {
    try {
      if (editingBatch) {
        await updateBatch.mutateAsync({ ...editingBatch, ...data });
        toast('Batch updated successfully', 'success');
      } else {
        await addBatch.mutateAsync(data);
        toast('Batch added successfully', 'success');
      }
      handleCloseModal();
    } catch {
      toast('Failed to save batch', 'error');
    }
  };

  const exportToPDF = async () => {
    if (!batches || batches.length === 0) {
      toast('No data to export', 'error');
      return;
    }
    
    const { doc, startY, addFooter } = await createBrandedPDF('PoultryGuardLite Batch Report', userProfile);
    
    const tableData = batches.map(b => {
      const batchEntries = entries.filter(e => e.batchId === b.id);
      const batchSales = sales.filter(s => s.batchId === b.id);
      
      const mortality = calculateTotalMortality(batchEntries);
      const birdsSold = calculateTotalBirdsSold(batchSales);
      const remainingBirds = calculateRemainingBirds(b.totalBirds, mortality, birdsSold);
      
      return [
        b.batchName,
        b.birdType,
        b.breed,
        b.status,
        remainingBirds.toLocaleString(),
        b.arrivalDate ? formatDate(b.arrivalDate) : 'Unknown'
      ];
    });

    autoTable(doc, {
      startY,
      head: [['Batch Name', 'Type', 'Breed', 'Status', 'Birds', 'Arrival Date']],
      body: tableData,
      styles: { font: 'Roboto' }
    });
    
    addFooter();
    doc.save('PoultryGuard_Batch_Report.pdf');
  };

  return (
    <div className="space-y-6">
      <FarmStatusBanner status={farm?.status} />
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" onClick={() => router.push('/farms')}>
          <ArrowLeft className="w-5 h-5" />
        </Button>
        <div>
          <h2 className="text-2xl font-bold text-foreground">Batches</h2>
          <p className="text-muted-foreground text-sm mt-1">Manage flocks for this farm.</p>
        </div>
        <div className="flex-1" />
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => window.print()}>
            <Download className="w-4 h-4 mr-2" />
            Print
          </Button>
          <Button variant="outline" onClick={exportToPDF}>
            <Download className="w-4 h-4 mr-2" />
            PDF
          </Button>
          <div title={isCompleted ? "This farm has been completed." : ""}>
            <Button 
              onClick={() => handleOpenModal()} 
              style={{ background: 'linear-gradient(135deg, #F4A900, #d4920a)', color: '#1A1200' }}
              disabled={isCompleted}
            >
              + Add Batch
            </Button>
          </div>
        </div>
      </div>

      {batches && batches.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {batches.map((batch) => {
            const batchEntries = entries.filter(e => e.batchId === batch.id);
            const batchSales = sales.filter(s => s.batchId === batch.id);
            const mortality = calculateTotalMortality(batchEntries);
            const birdsSold = calculateTotalBirdsSold(batchSales);
            const remainingBirds = calculateRemainingBirds(batch.totalBirds, mortality, birdsSold);
            
            return (
              <BatchCard 
                key={batch.id} 
                batch={batch} 
                remainingBirds={remainingBirds} 
                onEdit={isCompleted ? undefined : handleOpenModal} 
                isFarmCompleted={isCompleted}
              />
            );
          })}
        </div>
      ) : (
        <div className="rounded-2xl p-8 text-center glass">
          <p className="text-muted-foreground text-sm">
            No batches found. Add your first batch to get started!
          </p>
        </div>
      )}

      <Modal
        open={isModalOpen}
        onClose={handleCloseModal}
        title={editingBatch ? 'Edit Batch' : 'Add Batch'}
      >
        <BatchForm
          farmId={farmId}
          defaultValues={editingBatch}
          onSubmit={handleSubmit}
          onCancel={handleCloseModal}
          loading={addBatch.isPending || updateBatch.isPending}
        />
      </Modal>
    </div>
  );
}

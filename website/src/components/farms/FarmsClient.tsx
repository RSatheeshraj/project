'use client';

import { useState } from 'react';
import { useFarms, useAddFarm, useUpdateFarm } from '@/hooks/useFarms';
import { FarmCard } from '@/components/farms/FarmCard';
import { FarmForm } from '@/components/farms/FarmForm';
import { Modal } from '@/components/ui/Modal';
import { LoadingScreen } from '@/components/common/LoadingScreen';
import { ErrorState } from '@/components/ui/States';
import { Button } from '@/components/ui/Button';
import type { Farm, FarmInput } from '@/types/models';
import { useToast } from '@/components/ui/Toast';
import { Download } from 'lucide-react';
import { createBrandedPDF } from '@/lib/pdf';
import autoTable from 'jspdf-autotable';
import { formatDate } from '@/lib/utils';
import { useAuth } from '@/contexts/AuthContext';

export function FarmsClient() {
  const { userProfile } = useAuth();
  const { data: farms, isLoading, error } = useFarms();
  const addFarm = useAddFarm();
  const updateFarm = useUpdateFarm();
  const { toast } = useToast();

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingFarm, setEditingFarm] = useState<Farm | undefined>();

  if (isLoading) return <LoadingScreen />;
  if (error) return <ErrorState title="Failed to load farms" />;

  const handleOpenModal = (farm?: Farm) => {
    setEditingFarm(farm);
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setEditingFarm(undefined);
  };

  const handleSubmit = async (data: FarmInput) => {
    try {
      if (editingFarm) {
        await updateFarm.mutateAsync({ ...editingFarm, ...data });
        toast('Farm updated successfully', 'success');
      } else {
        await addFarm.mutateAsync(data);
        toast('Farm added successfully', 'success');
      }
      handleCloseModal();
    } catch {
      toast('Failed to save farm', 'error');
    }
  };

  const exportToPDF = async () => {
    if (!farms || farms.length === 0) {
      toast('No data to export', 'error');
      return;
    }
    
    const { doc, startY, addFooter } = await createBrandedPDF('PoultryGuardLite Farm Summary Report', userProfile);
    
    const tableData = farms.map(f => [
      f.name,
      f.type,
      f.capacity.toLocaleString(),
      f.sheds.toString(),
      f.ownerName,
      f.createdAt ? formatDate(f.createdAt) : 'Unknown'
    ]);

    autoTable(doc, {
      startY,
      head: [['Farm Name', 'Type', 'Capacity', 'Sheds', 'Owner', 'Created Date']],
      body: tableData,
      styles: { font: 'Roboto' }
    });
    
    addFooter();
    doc.save('PoultryGuard_Farm_Summary.pdf');
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-foreground">Farms</h2>
          <p className="text-muted-foreground text-sm mt-1">Manage your farms and flocks.</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => window.print()}>
            <Download className="w-4 h-4 mr-2" />
            Print
          </Button>
          <Button variant="outline" onClick={exportToPDF}>
            <Download className="w-4 h-4 mr-2" />
            PDF
          </Button>
          <Button onClick={() => handleOpenModal()} style={{ background: 'linear-gradient(135deg, #F4A900, #d4920a)', color: '#1A1200' }}>
            + Add Farm
          </Button>
        </div>
      </div>

      {farms && farms.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {farms.map((farm) => (
            <FarmCard key={farm.id} farm={farm} onEdit={handleOpenModal} />
          ))}
        </div>
      ) : (
        <div className="rounded-2xl p-8 text-center glass">
          <p className="text-muted-foreground text-sm">
            No farms found. Add your first farm to get started!
          </p>
        </div>
      )}

      <Modal
        open={isModalOpen}
        onClose={handleCloseModal}
        title={editingFarm ? 'Edit Farm' : 'Add Farm'}
      >
        <FarmForm
          defaultValues={editingFarm}
          onSubmit={handleSubmit}
          onCancel={handleCloseModal}
          loading={addFarm.isPending || updateFarm.isPending}
        />
      </Modal>
    </div>
  );
}

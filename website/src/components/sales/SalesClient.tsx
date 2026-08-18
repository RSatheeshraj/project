'use client';

import { useState } from 'react';
import { useFarms } from '@/hooks/useFarms';
import { useSales, useAddSale, useUpdateSale, useDeleteSale } from '@/hooks/useSales';
import { useBatches } from '@/hooks/useBatches';
import { SaleForm } from './SaleForm';
import { Modal, ConfirmModal } from '@/components/ui/Modal';
import { LoadingScreen } from '@/components/common/LoadingScreen';
import { ErrorState } from '@/components/ui/States';
import { Button } from '@/components/ui/Button';
import type { Sale, SaleInput } from '@/types/models';
import { useToast } from '@/components/ui/Toast';
import { formatCurrency } from '@/lib/currency';
import { Edit2, Trash2, DollarSign, Activity, TrendingUp, Users, Download, Printer } from 'lucide-react';
import { formatDate } from '@/lib/utils';
import { generateSalesReportPdf } from '@/lib/pdf';
import { calculateTotalRevenue, calculateTotalBirdsSold } from '@/lib/calculations';
import { useAuth } from '@/contexts/AuthContext';
import { FarmStatusBanner } from '@/components/common/FarmStatusBanner';

export function SalesClient() {
  const { userProfile } = useAuth();
  const { data: farms, isLoading: loadingFarms } = useFarms();
  const [selectedFarmId, setSelectedFarmId] = useState<string | null>(null);
  const activeFarmId = selectedFarmId || farms?.[0]?.id || '';
  const activeFarm = farms?.find((f) => f.id === activeFarmId);
  const normalizedStatus = (activeFarm?.status || 'Active').trim().toLowerCase();
  const isFarmCompleted = ['completed', 'closed', 'archived'].includes(normalizedStatus);
  
  const { data: sales, isLoading: loadingSales, error } = useSales(activeFarmId);
  const { data: batches } = useBatches(activeFarmId);
  const addSale = useAddSale();
  const updateSale = useUpdateSale();
  const deleteMutation = useDeleteSale();
  const { toast } = useToast();

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingSale, setEditingSale] = useState<Sale | undefined>();
  
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [saleToDelete, setSaleToDelete] = useState<Sale | undefined>();

  if (loadingFarms || (activeFarmId && loadingSales)) return <LoadingScreen />;
  if (error) return <ErrorState title="Failed to load sales" />;

  const handleDownloadPdf = async () => {
    if (!activeFarm) return;
    try {
      const doc = await generateSalesReportPdf(activeFarm, sales || [], batches || [], userProfile);
      doc.save(`Sales_Report_${activeFarm.name.replace(/\s+/g, '_')}.pdf`);
      toast('Report downloaded successfully', 'success');
    } catch (err) {
      console.error(err);
      toast('Failed to generate PDF', 'error');
    }
  };

  const handlePrintPdf = async () => {
    if (!activeFarm) return;
    try {
      const doc = await generateSalesReportPdf(activeFarm, sales || [], batches || [], userProfile);
      doc.autoPrint();
      window.open(doc.output('bloburl'), '_blank');
    } catch (err) {
      console.error(err);
      toast('Failed to generate PDF', 'error');
    }
  };

  const handleOpenModal = (sale?: Sale) => {
    setEditingSale(sale);
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setEditingSale(undefined);
  };

  const handleSubmit = async (data: SaleInput) => {
    try {
      if (editingSale) {
        await updateSale.mutateAsync({ ...editingSale, ...data });
        toast('Sale updated successfully', 'success');
      } else {
        await addSale.mutateAsync(data);
        toast('Sale added successfully', 'success');
      }
      handleCloseModal();
    } catch {
      toast('Failed to save sale', 'error');
    }
  };
  
  const handleDelete = async () => {
    if (!saleToDelete) return;
    try {
      await deleteMutation.mutateAsync({ farmId: activeFarmId, saleId: saleToDelete.id });
      toast('Sale deleted successfully', 'success');
      setConfirmDelete(false);
      setSaleToDelete(undefined);
    } catch {
      toast('Failed to delete sale', 'error');
    }
  };


  const totalRevenue = calculateTotalRevenue(sales || []);
  const totalBirdsSold = calculateTotalBirdsSold(sales || []);
  const totalProfit = sales?.reduce((acc, sale) => acc + (sale.estimatedProfit || 0), 0) || 0;
  const totalWeight = sales?.reduce((acc, sale) => acc + (sale.totalWeight || 0), 0) || 0;
  const averageSellingPrice = sales && totalWeight > 0 ? (totalRevenue / totalWeight) : 0;

  return (
    <div className="space-y-6">
      <FarmStatusBanner status={activeFarm?.status} />
      <div className="flex items-center gap-4 flex-wrap">
        <div>
          <h2 className="text-2xl font-bold text-foreground">Sales Dashboard</h2>
          <p className="text-muted-foreground text-sm mt-1">Manage and track your sales</p>
        </div>
        <div className="flex-1" />
        
        {farms && farms.length > 0 && (
          <select 
            value={activeFarmId}
            onChange={(e) => setSelectedFarmId(e.target.value)}
            className="h-10 px-3 rounded-lg border border-border bg-background text-sm"
          >
            {farms.map(f => (
              <option key={f.id} value={f.id}>{f.name}</option>
            ))}
          </select>
        )}

        <div className="flex items-center gap-2">
          <Button variant="outline" onClick={handleDownloadPdf} disabled={loadingSales} title="Download Report">
            <Download className="w-4 h-4 mr-2" /> Download
          </Button>
          <Button variant="outline" onClick={handlePrintPdf} disabled={loadingSales} title="Print Report">
            <Printer className="w-4 h-4 mr-2" /> Print
          </Button>
          <div title={isFarmCompleted ? "This farm has been completed." : ""}>
            <Button onClick={() => handleOpenModal()} style={{ background: 'linear-gradient(135deg, #F4A900, #d4920a)', color: '#1A1200' }} disabled={isFarmCompleted}>
              + Add Sale
            </Button>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="p-4 rounded-2xl glass border border-border">
          <div className="flex items-center gap-3 text-muted-foreground mb-2">
            <DollarSign className="w-5 h-5 text-emerald-500" />
            <span className="font-medium text-sm">Total Revenue</span>
          </div>
          <p className="text-2xl font-bold">{formatCurrency(totalRevenue)}</p>
        </div>
        <div className="p-4 rounded-2xl glass border border-border">
          <div className="flex items-center gap-3 text-muted-foreground mb-2">
            <Users className="w-5 h-5 text-blue-500" />
            <span className="font-medium text-sm">Birds Sold</span>
          </div>
          <p className="text-2xl font-bold">{totalBirdsSold.toLocaleString()}</p>
        </div>
        <div className="p-4 rounded-2xl glass border border-border">
          <div className="flex items-center gap-3 text-muted-foreground mb-2">
            <Activity className="w-5 h-5 text-orange-500" />
            <span className="font-medium text-sm">Avg Price/Kg</span>
          </div>
          <p className="text-2xl font-bold">{formatCurrency(averageSellingPrice)}</p>
        </div>
        <div className="p-4 rounded-2xl glass border border-border">
          <div className="flex items-center gap-3 text-muted-foreground mb-2">
            <TrendingUp className="w-5 h-5 text-[#F4A900]" />
            <span className="font-medium text-sm">Est. Profit</span>
          </div>
          <p className="text-2xl font-bold">{formatCurrency(totalProfit)}</p>
        </div>
      </div>

      {sales && sales.length > 0 ? (
        <div className="space-y-4">
          <h3 className="font-bold text-lg mt-6">Sales History</h3>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {sales.map((sale) => (
              <div key={sale.id} className="rounded-2xl border border-border bg-card p-5 glass group transition-all">
                <div className="flex justify-between items-start mb-4">
                  <div>
                    <h3 className="font-bold text-lg">{sale.buyerName}</h3>
                    <p className="text-xs text-muted-foreground mt-1">{sale.saleDate ? formatDate(sale.saleDate) : 'Unknown Date'} • {sale.buyerContact}</p>
                  </div>
                  <div className="flex gap-2">
                    <div title={isFarmCompleted ? "This farm has been completed." : ""}>
                      <Button size="icon" variant="ghost" onClick={() => handleOpenModal(sale)} disabled={isFarmCompleted}>
                        <Edit2 className="w-4 h-4" />
                      </Button>
                    </div>
                    <div title={isFarmCompleted ? "This farm has been completed." : ""}>
                      <Button size="icon" variant="ghost" className="text-muted-foreground hover:text-red-400 hover:bg-red-500/10" onClick={() => {
                        setSaleToDelete(sale);
                        setConfirmDelete(true);
                      }} disabled={isFarmCompleted}>
                        <Trash2 className="w-4 h-4" />
                      </Button>
                    </div>
                  </div>
                </div>
                
                <div className="grid grid-cols-2 gap-2 text-sm mt-4">
                  <div className="flex justify-between border-b border-border/50 pb-1">
                    <span className="text-muted-foreground">Birds Sold</span>
                    <span className="font-semibold">{sale.birdsSold}</span>
                  </div>
                  <div className="flex justify-between border-b border-border/50 pb-1">
                    <span className="text-muted-foreground">Avg Weight</span>
                    <span className="font-semibold">{sale.averageWeight} kg</span>
                  </div>
                  <div className="flex justify-between border-b border-border/50 pb-1">
                    <span className="text-muted-foreground">Price/Kg</span>
                    <span className="font-semibold">{formatCurrency(sale.pricePerKg)}</span>
                  </div>
                  <div className="flex justify-between border-b border-border/50 pb-1">
                    <span className="text-muted-foreground">Total Revenue</span>
                    <span className="font-semibold text-emerald-500">{formatCurrency(sale.revenue)}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      ) : (
        <div className="rounded-2xl p-8 text-center glass mt-6">
          <p className="text-muted-foreground text-sm">
            No sales records found for this farm. Add your first sale.
          </p>
        </div>
      )}

      <Modal
        open={isModalOpen}
        onClose={handleCloseModal}
        title={editingSale ? 'Edit Sale' : 'Add Sale'}
      >
        <SaleForm
          defaultValues={editingSale}
          onSubmit={handleSubmit}
          onCancel={handleCloseModal}
          loading={addSale.isPending || updateSale.isPending}
        />
      </Modal>
      
      <ConfirmModal
        open={confirmDelete}
        onClose={() => {
          setConfirmDelete(false);
          setSaleToDelete(undefined);
        }}
        onConfirm={handleDelete}
        title="Delete Sale"
        description="Are you sure you want to delete this sale? This action cannot be undone."
        confirmLabel="Delete"
        loading={deleteMutation.isPending}
        destructive
      />
    </div>
  );
}

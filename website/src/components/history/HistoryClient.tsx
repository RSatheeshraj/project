'use client';

import { useScanHistory, useDeleteScanHistory } from '@/hooks/useScanHistory';
import { LoadingScreen } from '@/components/common/LoadingScreen';
import { ErrorState } from '@/components/ui/States';
import { Button } from '@/components/ui/Button';
import { Download, Trash2, ShieldAlert } from 'lucide-react';
import { useToast } from '@/components/ui/Toast';
import { formatDate } from '@/lib/utils';
import { createBrandedPDF } from '@/lib/pdf';
import autoTable from 'jspdf-autotable';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { ConfirmModal } from '@/components/ui/Modal';
import { useAuth } from '@/contexts/AuthContext';
import type { ScanHistory } from '@/types/models';

export function HistoryClient() {
  const { userProfile } = useAuth();
  const { data: scans, isLoading, error } = useScanHistory();
  const deleteMutation = useDeleteScanHistory();
  const { toast } = useToast();
  
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [scanToDelete, setScanToDelete] = useState<ScanHistory | undefined>();
  const router = useRouter();

  if (isLoading) return <LoadingScreen />;
  if (error) return <ErrorState title="Failed to load scan history" />;

  const handleDelete = async () => {
    if (!scanToDelete) return;
    try {
      await deleteMutation.mutateAsync(scanToDelete.id);
      toast('Scan history deleted', 'success');
      setConfirmDelete(false);
      setScanToDelete(undefined);
    } catch {
      toast('Failed to delete scan history', 'error');
    }
  };

  const exportToPDF = async () => {
    if (!scans || scans.length === 0) {
      toast('No data to export', 'error');
      return;
    }
    
    const { doc, startY, addFooter } = await createBrandedPDF('PoultryGuardLite AI Scan History', userProfile);
    
    const tableData = scans.map(scan => [
      scan.createdAt ? formatDate(scan.createdAt) : 'Unknown',
      scan.farmName,
      scan.batchName,
      scan.result.diseaseName,
      `${scan.result.confidence}%`,
      scan.result.severity
    ]);

    autoTable(doc, {
      startY,
      head: [['Date', 'Farm', 'Batch', 'Disease', 'Confidence', 'Severity']],
      body: tableData,
      styles: { font: 'Roboto' }
    });
    
    addFooter();
    doc.save('PoultryGuard_Scan_History.pdf');
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-foreground">AI Scan Reports</h2>
          <p className="text-muted-foreground text-sm mt-1">Historical AI diagnostics data.</p>
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
        </div>
      </div>

      {scans && scans.length > 0 ? (
        <div className="space-y-4">
          {scans.map((scan) => (
            <div 
              key={scan.id} 
              onClick={() => router.push(`/history/${scan.id}`)}
              className="rounded-2xl border border-border bg-card p-5 glass cursor-pointer hover:border-primary/50 transition-colors group"
            >
              <div className="flex justify-between items-start mb-4">
                <div className="flex gap-4">
                  <div className={`w-12 h-12 rounded-xl flex items-center justify-center shrink-0 ${
                    scan.result.severity === 'High' || scan.result.severity === 'Critical' 
                      ? 'bg-red-500/20 text-red-400' 
                      : 'bg-green-500/20 text-green-400'
                  }`}>
                    <ShieldAlert className="w-6 h-6" />
                  </div>
                  <div>
                    <h3 className="font-bold text-lg leading-tight">{scan.result.diseaseName}</h3>
                    <p className="text-xs text-muted-foreground mt-1">
                      {scan.farmName} &bull; {scan.batchName} &bull; {scan.createdAt ? formatDate(scan.createdAt) : 'Unknown'}
                    </p>
                  </div>
                </div>
                <div className="flex flex-col items-end">
                  <span className={`px-3 py-1 rounded-full text-xs font-bold ${
                    scan.result.severity === 'High' || scan.result.severity === 'Critical' 
                      ? 'bg-red-500/20 text-red-400' 
                      : 'bg-green-500/20 text-green-400'
                  }`}>
                    {scan.result.severity}
                  </span>
                  <span className="text-xs text-muted-foreground mt-2">
                    Conf: {scan.result.confidence}%
                  </span>
                </div>
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4 pt-4 border-t border-border/50 text-sm">
                <div>
                  <h4 className="font-semibold text-primary mb-1">Possible Cause</h4>
                  <p className="text-muted-foreground">{scan.result.possibleCause}</p>
                </div>
                <div>
                  <h4 className="font-semibold text-red-400 mb-1">Immediate Action</h4>
                  <p className="text-muted-foreground">{scan.result.immediateAction}</p>
                </div>
                <div>
                  <h4 className="font-semibold text-primary mb-1">Treatment</h4>
                  <p className="text-muted-foreground">{scan.result.treatment}</p>
                </div>
                <div>
                  <h4 className="font-semibold text-primary mb-1">Prevention</h4>
                  <p className="text-muted-foreground">{scan.result.prevention}</p>
                </div>
              </div>
              
              <div className="flex justify-between items-center mt-4 pt-4 border-t border-border/50">
                <span className="text-xs font-semibold px-2 py-1 bg-secondary rounded text-secondary-foreground">
                  Isolation: {scan.result.isolationRequired ? 'REQUIRED' : 'Not Required'}
                </span>
                <Button size="sm" variant="ghost" className="text-muted-foreground hover:text-red-400 opacity-0 group-hover:opacity-100 transition-opacity" onClick={(e) => {
                  e.stopPropagation();
                  setScanToDelete(scan);
                  setConfirmDelete(true);
                }}>
                  <Trash2 className="w-4 h-4 mr-2" />
                  Delete Record
                </Button>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="rounded-2xl p-8 text-center glass">
          <p className="text-muted-foreground text-sm">
            No scan history yet. Use the AI Scanner or the mobile app to run your first scan.
          </p>
        </div>
      )}
      
      <ConfirmModal
        open={confirmDelete}
        onClose={() => {
          setConfirmDelete(false);
          setScanToDelete(undefined);
        }}
        onConfirm={handleDelete}
        title="Delete Scan Record"
        description="Are you sure you want to delete this scan record? This action cannot be undone."
        confirmLabel="Delete"
        loading={deleteMutation.isPending}
        destructive
      />
    </div>
  );
}

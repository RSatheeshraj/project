'use client';

import { useScanHistoryById } from '@/hooks/useScanHistory';
import { LoadingScreen } from '@/components/common/LoadingScreen';
import { ErrorState } from '@/components/ui/States';
import { Button } from '@/components/ui/Button';
import { ArrowLeft, Printer, Download, ShieldAlert, CheckCircle2, AlertTriangle } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { formatDate } from '@/lib/utils';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { RobotoRegular, RobotoBold } from '@/lib/fonts';
import { useToast } from '@/components/ui/Toast';

export function ScanDetailsClient({ scanId }: { scanId: string }) {
  const { data: scan, isLoading, error } = useScanHistoryById(scanId);
  const router = useRouter();
  const { toast } = useToast();

  if (isLoading) return <LoadingScreen />;
  if (error || !scan) return <ErrorState title="Failed to load scan details" />;

  const isHighSeverity = scan.result.severity === 'High' || scan.result.severity === 'Critical';

  const exportToPDF = () => {
    const doc = new jsPDF();
    
    doc.addFileToVFS('Roboto-Regular.ttf', RobotoRegular);
    doc.addFont('Roboto-Regular.ttf', 'Roboto', 'normal');
    doc.addFileToVFS('Roboto-Bold.ttf', RobotoBold);
    doc.addFont('Roboto-Bold.ttf', 'Roboto', 'bold');
    doc.setFont('Roboto', 'normal');
    
    doc.setFontSize(22);
    doc.text('PoultryGuardLite - AI Scan Report', 14, 22);
    
    doc.setFontSize(12);
    doc.text(`Date: ${scan.createdAt ? formatDate(scan.createdAt) : 'Unknown'}`, 14, 32);
    doc.text(`Farm: ${scan.farmName}`, 14, 38);
    doc.text(`Batch: ${scan.batchName}`, 14, 44);

    doc.setFontSize(16);
    doc.text(`Diagnosis: ${scan.result.diseaseName}`, 14, 56);
    
    autoTable(doc, {
      startY: 62,
      head: [['Metric', 'Value']],
      body: [
        ['Confidence', `${scan.result.confidence}%`],
        ['Severity', scan.result.severity],
        ['Isolation Required', scan.result.isolationRequired ? 'Yes' : 'No'],
      ],
      theme: 'grid',
      styles: { font: 'Roboto' }
    });

    autoTable(doc, {
      startY: (doc as jsPDF & { lastAutoTable?: { finalY: number } }).lastAutoTable?.finalY ?? 62 + 10,
      head: [['Recommendation', 'Details']],
      body: [
        ['Possible Cause', scan.result.possibleCause],
        ['Immediate Action', scan.result.immediateAction],
        ['Treatment', scan.result.treatment],
        ['Prevention', scan.result.prevention],
      ],
      theme: 'grid',
      styles: { cellWidth: 'wrap', font: 'Roboto' },
      columnStyles: {
        0: { cellWidth: 40 },
        1: { cellWidth: 'auto' }
      }
    });
    
    doc.save(`Scan_Report_${scan.id}.pdf`);
    toast('PDF downloaded successfully', 'success');
  };

  return (
    <div className="space-y-6 max-w-4xl mx-auto pb-20">
      {/* Sticky Action Bar */}
      <div className="sticky top-0 z-10 -mx-4 px-4 py-3 bg-background/80 backdrop-blur-md border-b border-border flex items-center justify-between">
        <Button variant="ghost" onClick={() => router.back()} className="hover:bg-secondary">
          <ArrowLeft className="w-4 h-4 mr-2" />
          Back
        </Button>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => window.print()} className="hidden sm:flex">
            <Printer className="w-4 h-4 mr-2" />
            Print
          </Button>
          <Button onClick={exportToPDF} className="bg-primary text-primary-foreground hover:bg-primary/90">
            <Download className="w-4 h-4 mr-2" />
            Download PDF
          </Button>
        </div>
      </div>

      {/* Header Info */}
      <div className="text-center md:text-left space-y-1">
        <h2 className="text-2xl font-bold text-foreground">Scan Report</h2>
        <p className="text-muted-foreground text-sm">
          {scan.farmName} &bull; {scan.batchName} &bull; {scan.createdAt ? formatDate(scan.createdAt) : 'Unknown'}
        </p>
      </div>

      {/* Disease Overview Card */}
      <div className="rounded-2xl border border-border bg-card p-6 glass shadow-lg">
        <div className="flex flex-col md:flex-row gap-6 items-center md:items-start justify-between">
          <div className="flex items-center gap-4">
            <div className={`w-16 h-16 rounded-2xl flex items-center justify-center shrink-0 ${
              isHighSeverity ? 'bg-red-500/20 text-red-400' : 'bg-green-500/20 text-green-400'
            }`}>
              {isHighSeverity ? <ShieldAlert className="w-8 h-8" /> : <CheckCircle2 className="w-8 h-8" />}
            </div>
            <div>
              <h3 className="font-extrabold text-2xl leading-tight">{scan.result.diseaseName}</h3>
              <div className="flex items-center gap-3 mt-2">
                <span className={`px-3 py-1 rounded-full text-xs font-bold ${
                  isHighSeverity ? 'bg-red-500/20 text-red-400' : 'bg-green-500/20 text-green-400'
                }`}>
                  {scan.result.severity} Severity
                </span>
                {scan.result.isolationRequired && (
                  <span className="px-3 py-1 rounded-full text-xs font-bold bg-amber-500/20 text-amber-400 flex items-center">
                    <AlertTriangle className="w-3 h-3 mr-1" />
                    Isolation Required
                  </span>
                )}
              </div>
            </div>
          </div>
          
          <div className="w-full md:w-48 space-y-2">
            <div className="flex justify-between text-sm font-semibold">
              <span>Confidence</span>
              <span className="text-primary">{scan.result.confidence}%</span>
            </div>
            <div className="h-3 w-full bg-secondary rounded-full overflow-hidden">
              <div 
                className="h-full bg-primary transition-all duration-500 ease-out" 
                style={{ width: `${scan.result.confidence}%` }}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Recommendations Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="rounded-2xl border border-border bg-card p-5 glass flex flex-col h-full hover:border-primary/50 transition-colors">
          <h4 className="font-semibold text-primary mb-3 flex items-center">
            <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center mr-3">
              <span className="text-primary text-sm">1</span>
            </div>
            Possible Cause
          </h4>
          <p className="text-muted-foreground leading-relaxed flex-grow">{scan.result.possibleCause}</p>
        </div>

        <div className="rounded-2xl border border-border bg-card p-5 glass flex flex-col h-full hover:border-red-400/50 transition-colors">
          <h4 className="font-semibold text-red-400 mb-3 flex items-center">
            <div className="w-8 h-8 rounded-full bg-red-400/10 flex items-center justify-center mr-3">
              <span className="text-red-400 text-sm">2</span>
            </div>
            Immediate Action
          </h4>
          <p className="text-muted-foreground leading-relaxed flex-grow">{scan.result.immediateAction}</p>
        </div>

        <div className="rounded-2xl border border-border bg-card p-5 glass flex flex-col h-full hover:border-blue-400/50 transition-colors">
          <h4 className="font-semibold text-blue-400 mb-3 flex items-center">
            <div className="w-8 h-8 rounded-full bg-blue-400/10 flex items-center justify-center mr-3">
              <span className="text-blue-400 text-sm">3</span>
            </div>
            Treatment Plan
          </h4>
          <p className="text-muted-foreground leading-relaxed flex-grow">{scan.result.treatment}</p>
        </div>

        <div className="rounded-2xl border border-border bg-card p-5 glass flex flex-col h-full hover:border-green-400/50 transition-colors">
          <h4 className="font-semibold text-green-400 mb-3 flex items-center">
            <div className="w-8 h-8 rounded-full bg-green-400/10 flex items-center justify-center mr-3">
              <span className="text-green-400 text-sm">4</span>
            </div>
            Prevention Strategy
          </h4>
          <p className="text-muted-foreground leading-relaxed flex-grow">{scan.result.prevention}</p>
        </div>
      </div>
    </div>
  );
}
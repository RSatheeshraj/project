'use client';

import React, { useCallback, useRef, useState } from 'react';
import {
  Microscope,
  Upload,
  X,
  ImageIcon,
  ShieldAlert,
  ShieldCheck,
  AlertTriangle,
  Zap,
  Stethoscope,
  Shield,
  Search,
  CheckCircle,
  Loader2,
} from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Select } from '@/components/ui/Select';
import { useToast } from '@/components/ui/Toast';
import { useFarms } from '@/hooks/useFarms';
import { useBatches } from '@/hooks/useBatches';
import { useAiScan } from '@/hooks/useAiScan';
import type { AiScanResult, Farm, Batch } from '@/types/models';

function severityColor(severity: string): string {
  switch (severity.toLowerCase()) {
    case 'low': return 'text-green-400';
    case 'medium': return 'text-amber-400';
    case 'high':
    case 'critical': return 'text-red-400';
    default: return 'text-muted-foreground';
  }
}

function severityBg(severity: string): string {
  switch (severity.toLowerCase()) {
    case 'low': return 'bg-green-500/10 border-green-500/30';
    case 'medium': return 'bg-amber-500/10 border-amber-500/30';
    case 'high':
    case 'critical': return 'bg-red-500/10 border-red-500/30';
    default: return 'bg-muted border-border';
  }
}

function isCritical(severity: string): boolean {
  const s = severity.toLowerCase();
  return s === 'high' || s === 'critical';
}

interface ResultCardProps {
  title: string;
  content: string;
  icon: React.ReactNode;
  colorClass: string;
  bgClass: string;
}

function ResultCard({ title, content, icon, colorClass, bgClass }: ResultCardProps) {
  return (
    <div className={`rounded-2xl border p-4 ${bgClass}`}>
      <div className={`flex items-center gap-2 mb-2 ${colorClass}`}>
        {icon}
        <span className="text-sm font-semibold">{title}</span>
      </div>
      <p className="text-sm text-foreground/80 leading-relaxed">{content}</p>
    </div>
  );
}

function ResultPanel({ result, imageUrl, onReset }: { result: AiScanResult; imageUrl: string; onReset: () => void }) {
  const critical = isCritical(result.severity);
  void critical;
  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      {imageUrl && (
        <div className="rounded-2xl overflow-hidden border border-border h-48 lg:h-64">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={imageUrl} alt="Scanned image" className="w-full h-full object-cover" />
        </div>
      )}
      <div className="glass rounded-2xl p-5">
        <h3 className="text-xl font-bold text-foreground mb-3">{result.diseaseName}</h3>
        <div className="flex flex-wrap gap-2 mb-3">
          <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold border ${severityBg(result.severity)} ${severityColor(result.severity)}`}>
            <AlertTriangle className="w-3.5 h-3.5" />
            {result.severity} Severity
          </span>
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-primary/10 border border-primary/30 text-primary">
            <Microscope className="w-3.5 h-3.5" />
            {result.confidence}% Confidence
          </span>
        </div>
        {result.isolationRequired && (
          <div className="flex items-start gap-3 mt-3 p-3 rounded-xl bg-red-500/10 border border-red-500/40">
            <ShieldAlert className="w-5 h-5 text-red-400 shrink-0 mt-0.5" />
            <p className="text-sm text-red-300 font-semibold">
              Isolation Required - Separate affected birds immediately to prevent spread.
            </p>
          </div>
        )}
        {!result.isolationRequired && (
          <div className="flex items-center gap-2 mt-3 text-xs text-green-400">
            <ShieldCheck className="w-4 h-4" />
            Isolation not required
          </div>
        )}
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <ResultCard title="Possible Cause" content={result.possibleCause} icon={<Search className="w-4 h-4" />} colorClass="text-blue-400" bgClass="bg-blue-500/5 border-blue-500/20" />
        <ResultCard title="Immediate Action" content={result.immediateAction} icon={<Zap className="w-4 h-4" />} colorClass="text-amber-400" bgClass="bg-amber-500/5 border-amber-500/20" />
        <ResultCard title="Treatment Plan" content={result.treatment} icon={<Stethoscope className="w-4 h-4" />} colorClass="text-primary" bgClass="bg-primary/5 border-primary/20" />
        <ResultCard title="Prevention" content={result.prevention} icon={<Shield className="w-4 h-4" />} colorClass="text-green-400" bgClass="bg-green-500/5 border-green-500/20" />
      </div>
      <Button variant="outline" className="w-full" onClick={onReset}>
        Scan Another Image
      </Button>
    </div>
  );
}

export function ScanClient() {
  const { toast } = useToast();
  const [selectedFarmId, setSelectedFarmId] = useState('');
  const [selectedBatchId, setSelectedBatchId] = useState('');
  const [file, setFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [isDragging, setIsDragging] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [result, setResult] = useState<AiScanResult | null>(null);
  // Keep the local preview URL to show the image even if we don't upload it to storage
  const [resultImageUrl, setResultImageUrl] = useState('');

  const { data: farms, isLoading: farmsLoading } = useFarms();
  const { data: batches, isLoading: batchesLoading } = useBatches(selectedFarmId);
  const scanMutation = useAiScan();

  const ACCEPTED = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
  const MAX_MB = 10;

  function validateFile(f: File): string | null {
    if (!ACCEPTED.includes(f.type)) return `Unsupported file type (${f.type}). Use JPEG, PNG, WebP, or GIF.`;
    if (f.size > MAX_MB * 1024 * 1024) return `Image is too large (max ${MAX_MB} MB).`;
    return null;
  }

  function setImage(f: File) {
    const err = validateFile(f);
    if (err) { toast(err, 'error'); return; }
    setFile(f);
    const url = URL.createObjectURL(f);
    setPreviewUrl(url);
    setResultImageUrl(url);
    setResult(null);
  }

  function clearImage() {
    if (previewUrl) URL.revokeObjectURL(previewUrl);
    setFile(null);
    setPreviewUrl(null);
    setResult(null);
    setResultImageUrl('');
    if (fileInputRef.current) fileInputRef.current.value = '';
  }

  const onDragOver = useCallback((e: React.DragEvent) => { e.preventDefault(); setIsDragging(true); }, []);
  const onDragLeave = useCallback((e: React.DragEvent) => { e.preventDefault(); setIsDragging(false); }, []);
  const onDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault(); setIsDragging(false);
    const dropped = e.dataTransfer.files[0];
    if (dropped) setImage(dropped);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const onFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const picked = e.target.files?.[0];
    if (picked) setImage(picked);
  };

  async function handleAnalyze() {
    if (!selectedFarmId || !selectedBatchId) { toast('Please select a Farm and Batch first.', 'error'); return; }
    if (!file) { toast('Please upload an image to analyze.', 'error'); return; }
    
    try {
      const output = await scanMutation.mutateAsync({
        file,
        farmId: selectedFarmId,
        batchId: selectedBatchId,
      });
      setResult(output.result);
      toast('Scan complete! Result saved to history.', 'success');
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'An unexpected error occurred.';
      toast(msg, 'error');
    }
  }

  function handleReset() {
    clearImage(); setResult(null); scanMutation.reset();
  }

  const isProcessing = scanMutation.isPending;
  const activeFarms = farms?.filter((f: Farm) => !['completed', 'closed', 'archived'].includes((f.status || 'Active').trim().toLowerCase()));
  const farmOptions = activeFarms?.map((f: Farm) => ({ value: f.id, label: f.name })) ?? [];
  const batchOptions = batches?.map((b: Batch) => ({ value: b.id, label: b.batchName })) ?? [];

  return (
    <div className="space-y-6 max-w-4xl mx-auto">
      <div>
        <h2 className="text-2xl font-bold text-foreground flex items-center gap-2">
          <Microscope className="w-6 h-6 text-primary" />
          AI Disease Scan
        </h2>
        <p className="text-muted-foreground text-sm mt-1">
          Upload a photo of bird droppings or affected areas. Gemini Vision AI will diagnose potential diseases using flock context.
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="space-y-5">
          <div className="glass rounded-2xl p-5 space-y-4">
            <h3 className="text-sm font-semibold text-foreground/70 uppercase tracking-wider">Flock Context</h3>
            {farmsLoading ? (
              <div className="flex items-center gap-2 text-sm text-muted-foreground"><Loader2 className="w-4 h-4 animate-spin" />Loading farms...</div>
            ) : farmOptions.length === 0 ? (
              <p className="text-sm text-amber-400">Add a farm first to use AI Scan.</p>
            ) : (
              <Select label="Farm" id="scan-farm-select" options={farmOptions} placeholder="Select a farm" value={selectedFarmId} onChange={(e) => { setSelectedFarmId(e.target.value); setSelectedBatchId(''); }} disabled={isProcessing} />
            )}
            {selectedFarmId && (
              batchesLoading ? (
                <div className="flex items-center gap-2 text-sm text-muted-foreground"><Loader2 className="w-4 h-4 animate-spin" />Loading batches...</div>
              ) : batchOptions.length === 0 ? (
                <p className="text-sm text-muted-foreground">No active batches in this farm.</p>
              ) : (
                <Select label="Batch" id="scan-batch-select" options={batchOptions} placeholder="Select a batch" value={selectedBatchId} onChange={(e) => setSelectedBatchId(e.target.value)} disabled={isProcessing} />
              )
            )}
          </div>

          <div className="glass rounded-2xl p-5 space-y-4">
            <h3 className="text-sm font-semibold text-foreground/70 uppercase tracking-wider">Image Upload</h3>
            {previewUrl ? (
              <div className="relative rounded-xl overflow-hidden border border-border">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={previewUrl} alt="Preview" className="w-full h-48 object-cover" />
                {!isProcessing && (
                  <button onClick={clearImage} className="absolute top-2 right-2 p-1.5 rounded-lg bg-black/60 text-white hover:bg-red-500/80 transition-colors" aria-label="Remove image">
                    <X className="w-4 h-4" />
                  </button>
                )}
                {isProcessing && (
                  <div className="absolute inset-0 bg-black/60 flex flex-col items-center justify-center gap-2">
                    <p className="text-white text-sm font-semibold animate-pulse">Analyzing...</p>
                  </div>
                )}
              </div>
            ) : (
              <div
                onDragOver={onDragOver} onDragLeave={onDragLeave} onDrop={onDrop}
                onClick={() => fileInputRef.current?.click()}
                className={['border-2 border-dashed rounded-xl p-8 flex flex-col items-center gap-3 cursor-pointer transition-all duration-200 select-none', isDragging ? 'border-primary bg-primary/5 scale-[1.01]' : 'border-border hover:border-primary/50 hover:bg-muted/30'].join(' ')}
              >
                <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center">
                  <Upload className="w-6 h-6 text-primary" />
                </div>
                <div className="text-center">
                  <p className="text-sm font-semibold text-foreground">{isDragging ? 'Drop to upload' : 'Drag & drop or click to upload'}</p>
                  <p className="text-xs text-muted-foreground mt-1">JPEG, PNG, WebP, GIF - max 10 MB</p>
                </div>
                <div className="flex items-center gap-1 text-xs text-muted-foreground/60">
                  <ImageIcon className="w-3.5 h-3.5" />
                  Bird droppings, affected areas, or birds
                </div>
              </div>
            )}
            <input ref={fileInputRef} type="file" accept="image/jpeg,image/png,image/webp,image/gif" className="sr-only" onChange={onFileChange} disabled={isProcessing} id="scan-file-input" />
          </div>

          <Button id="scan-analyze-btn" className="w-full h-12 text-base glow-primary" onClick={handleAnalyze} disabled={isProcessing || !file || !selectedFarmId || !selectedBatchId} loading={isProcessing}>
            {isProcessing ? (
              <>{'Analyzing...'}</>
            ) : (
              <><Microscope className="w-5 h-5" />Analyze with Gemini AI</>
            )}
          </Button>

          {isProcessing && (
            <div className="flex items-center gap-3 p-4 rounded-xl bg-primary/5 border border-primary/20">
              <div className="relative w-8 h-8 shrink-0">
                <div className="absolute inset-0 rounded-full border-2 border-primary/20" />
                <div className="absolute inset-0 rounded-full border-2 border-t-primary animate-spin" />
              </div>
              <div>
                <p className="text-sm font-semibold text-foreground">Analyzing...</p>
                <p className="text-xs text-muted-foreground">Building Context & Gemini Processing...</p>
              </div>
            </div>
          )}
        </div>

        <div>
          {result ? (
            <ResultPanel result={result} imageUrl={resultImageUrl} onReset={handleReset} />
          ) : (
            <div className="glass rounded-2xl p-8 h-full flex flex-col items-center justify-center text-center gap-4 min-h-[300px]">
              <div className="w-16 h-16 rounded-full bg-primary/10 flex items-center justify-center">
                <Microscope className="w-8 h-8 text-primary/60" />
              </div>
              <div>
                <h3 className="text-lg font-semibold text-foreground/70">Disease Detection</h3>
                <p className="text-sm text-muted-foreground mt-2 max-w-xs">
                  Select a farm, batch, and upload a photo to detect potential poultry diseases using Gemini Vision AI.
                </p>
              </div>
              {scanMutation.isSuccess && (
                <div className="flex items-center gap-2 text-green-400 text-sm mt-2">
                  <CheckCircle className="w-4 h-4" />
                  Scan saved to history
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
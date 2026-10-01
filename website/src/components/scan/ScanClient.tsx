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
  Sparkles,
  ArrowRight,
  Cpu,
  Layers,
} from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Select } from '@/components/ui/Select';
import { useToast } from '@/components/ui/Toast';
import { useFarms } from '@/hooks/useFarms';
import { useBatches } from '@/hooks/useBatches';
import { useAiScan } from '@/hooks/useAiScan';
import {
  TrainedModelService,
  type TrainedModelResult,
} from '@/lib/services/TrainedModelService';
import { ModelPopupModal } from '@/components/scan/ModelPopupModal';
import { ScanHistoryRepository } from '@/repositories/scan-history.repository';
import type { AiScanResult, Farm, Batch } from '@/types/models';

type AnalysisMode = 'picture' | 'disease';

function severityColor(severity: string): string {
  switch (severity.toLowerCase()) {
    case 'low':
      return 'text-green-400';
    case 'medium':
      return 'text-amber-400';
    case 'high':
    case 'critical':
      return 'text-red-400';
    default:
      return 'text-muted-foreground';
  }
}

function severityBg(severity: string): string {
  switch (severity.toLowerCase()) {
    case 'low':
      return 'bg-green-500/10 border-green-500/30';
    case 'medium':
      return 'bg-amber-500/10 border-amber-500/30';
    case 'high':
    case 'critical':
      return 'bg-red-500/10 border-red-500/30';
    default:
      return 'bg-muted border-border';
  }
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

function ResultPanel({
  result,
  imageUrl,
  trainedResult,
  analysisMode,
  onReset,
}: {
  result: AiScanResult;
  imageUrl: string;
  trainedResult: TrainedModelResult | null;
  analysisMode: AnalysisMode;
  onReset: () => void;
}) {
  return (
    <div className="space-y-6 animate-in fade-in duration-500">
      {imageUrl && (
        <div className="rounded-2xl overflow-hidden border border-border h-48 lg:h-64">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src={imageUrl} alt="Scanned image" className="w-full h-full object-cover" />
        </div>
      )}

      {/* Mode Tag & Model Verification Banner (For Disease Analysis) */}
      {analysisMode === 'disease' && trainedResult && (
        <div className="p-4 rounded-2xl bg-purple-500/10 border border-purple-500/30 flex items-center justify-between gap-3">
          <div className="flex items-center gap-2.5">
            <div className="w-9 h-9 rounded-xl bg-purple-500/20 flex items-center justify-center text-purple-400">
              <Cpu className="w-5 h-5" />
            </div>
            <div>
              <p className="text-xs font-bold text-purple-300">Trained AI Model Classification</p>
              <p className="text-sm font-semibold text-foreground">
                {trainedResult.diseaseDisplayName || trainedResult.diseaseName}
              </p>
            </div>
          </div>
          <span className="px-3 py-1 rounded-full text-xs font-bold bg-purple-500/20 text-purple-300 border border-purple-500/30">
            {trainedResult.confidence}% Model Conf.
          </span>
        </div>
      )}

      <div className="glass rounded-2xl p-5">
        <div className="flex items-center justify-between gap-2 mb-2">
          <span className="text-xs font-bold uppercase tracking-wider text-muted-foreground">
            {analysisMode === 'disease' ? 'Gemini AI Final Diagnosis' : 'AI Picture Analysis Result'}
          </span>
          <span className="px-2.5 py-0.5 rounded-md text-[10px] font-bold bg-primary/10 text-primary border border-primary/20">
            {analysisMode === 'disease' ? 'Disease Analysis' : 'Picture Analysis'}
          </span>
        </div>

        <h3 className="text-xl font-bold text-foreground mb-3">{result.diseaseName}</h3>

        <div className="flex flex-wrap gap-2 mb-3">
          <span
            className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold border ${severityBg(
              result.severity
            )} ${severityColor(result.severity)}`}
          >
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
        <ResultCard
          title="Possible Cause"
          content={result.possibleCause}
          icon={<Search className="w-4 h-4" />}
          colorClass="text-blue-400"
          bgClass="bg-blue-500/5 border-blue-500/20"
        />
        <ResultCard
          title="Immediate Action"
          content={result.immediateAction}
          icon={<Zap className="w-4 h-4" />}
          colorClass="text-amber-400"
          bgClass="bg-amber-500/5 border-amber-500/20"
        />
        <ResultCard
          title="Treatment Plan"
          content={result.treatment}
          icon={<Stethoscope className="w-4 h-4" />}
          colorClass="text-primary"
          bgClass="bg-primary/5 border-primary/20"
        />
        <ResultCard
          title="Prevention"
          content={result.prevention}
          icon={<Shield className="w-4 h-4" />}
          colorClass="text-green-400"
          bgClass="bg-green-500/5 border-green-500/20"
        />
      </div>

      <Button variant="outline" className="w-full" onClick={onReset}>
        Scan Another Image
      </Button>
    </div>
  );
}

export function ScanClient() {
  const { toast } = useToast();

  // Analysis mode choice: 'picture' (EXISTING) vs 'disease' (NEW)
  const [analysisMode, setAnalysisMode] = useState<AnalysisMode>('picture');

  const [selectedFarmId, setSelectedFarmId] = useState('');
  const [selectedBatchId, setSelectedBatchId] = useState('');
  const [file, setFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [isDragging, setIsDragging] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [result, setResult] = useState<AiScanResult | null>(null);
  const [resultImageUrl, setResultImageUrl] = useState('');

  // Trained AI Model popup modal state (for Disease Analysis)
  const [trainedResult, setTrainedResult] = useState<TrainedModelResult | null>(null);
  const [showTrainedModal, setShowTrainedModal] = useState(false);
  const [isEvaluatingModel, setIsEvaluatingModel] = useState(false);

  const { data: farms, isLoading: farmsLoading } = useFarms();
  const { data: batches, isLoading: batchesLoading } = useBatches(selectedFarmId);
  const scanMutation = useAiScan();

  const ACCEPTED = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
  const MAX_MB = 10;

  function validateFile(f: File): string | null {
    if (!ACCEPTED.includes(f.type))
      return `Unsupported file type (${f.type}). Use JPEG, PNG, WebP, or GIF.`;
    if (f.size > MAX_MB * 1024 * 1024) return `Image is too large (max ${MAX_MB} MB).`;
    return null;
  }

  function setImage(f: File) {
    const err = validateFile(f);
    if (err) {
      toast(err, 'error');
      return;
    }
    setFile(f);
    const url = URL.createObjectURL(f);
    setPreviewUrl(url);
    setResultImageUrl(url);
    setResult(null);
    setTrainedResult(null);
  }

  function clearImage() {
    if (previewUrl) URL.revokeObjectURL(previewUrl);
    setFile(null);
    setPreviewUrl(null);
    setResult(null);
    setTrainedResult(null);
    setResultImageUrl('');
    if (fileInputRef.current) fileInputRef.current.value = '';
  }

  const onDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  }, []);

  const onDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
  }, []);

  const onDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    const dropped = e.dataTransfer.files[0];
    if (dropped) setImage(dropped);
  }, []);

  const onFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const picked = e.target.files?.[0];
    if (picked) setImage(picked);
  };

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. Picture Analysis – EXISTING FUNCTION FLOW
  // ─────────────────────────────────────────────────────────────────────────────
  async function handlePictureAnalysis() {
    if (!selectedFarmId || !selectedBatchId) {
      toast('Please select a Farm and Batch first.', 'error');
      return;
    }
    if (!file) {
      toast('Please upload an image to analyze.', 'error');
      return;
    }

    const selectedFarm = farms?.find((f: Farm) => f.id === selectedFarmId);
    const selectedBatch = batches?.find((b: Batch) => b.id === selectedBatchId);

    try {
      const output = await scanMutation.mutateAsync({
        file,
        farmId: selectedFarmId,
        batchId: selectedBatchId,
        farmName: selectedFarm?.name,
        batchName: selectedBatch?.batchName,
        birdType: selectedBatch?.birdType,
        totalBirds: selectedBatch?.totalBirds,
        arrivalDate: selectedBatch?.arrivalDate ? new Date(selectedBatch.arrivalDate).toISOString() : undefined,
        analysisType: 'picture_analysis',
      });
      setResult(output.result);

      // Save directly to user's client Firestore database
      try {
        await ScanHistoryRepository.addScanHistory({
          farmId: selectedFarmId,
          batchId: selectedBatchId,
          farmName: selectedFarm?.name || 'Poultry Farm',
          batchName: selectedBatch?.batchName || 'Active Batch',
          imageUrl: previewUrl || '',
          result: output.result,
        });
      } catch (saveErr) {
        console.warn('[ScanClient] Client history save note:', saveErr);
      }

      toast('Picture analysis complete! Result saved to history.', 'success');
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'An unexpected error occurred.';
      toast(msg, 'error');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. Disease Analysis – NEW FUNCTION FLOW
  // ─────────────────────────────────────────────────────────────────────────────
  // Step 1: Run custom trained TFLite model inference on chicken image & show Popup Modal
  async function handleStartDiseaseAnalysis() {
    if (!selectedFarmId || !selectedBatchId) {
      toast('Please select a Farm and Batch first.', 'error');
      return;
    }
    if (!file) {
      toast('Please upload a chicken image to analyze.', 'error');
      return;
    }

    setIsEvaluatingModel(true);
    try {
      console.log('[ScanClient] Running custom trained TFLite model on image...');
      const evalResult = await TrainedModelService.analyzeImage(file);
      setTrainedResult(evalResult);
      setShowTrainedModal(true);
    } catch (e) {
      console.error('[ScanClient] Model execution error:', e);
      toast('Failed to analyze image with trained model. Proceeding to Gemini...', 'error');
      // Even if model loading failed, allow fallback result
      setTrainedResult({
        isSuccess: false,
        diseaseName: 'Unidentified',
        diseaseDisplayName: 'Unidentified Condition',
        confidence: 40.0,
        threshold: 60,
        message: 'The trained model could not confidently identify this image.',
      });
      setShowTrainedModal(true);
    } finally {
      setIsEvaluatingModel(false);
    }
  }

  // Step 2: User presses "Continue" on popup modal -> Send image to Gemini API
  async function handleProceedFromTrainedModal() {
    setShowTrainedModal(false);
    if (!file || !selectedFarmId || !selectedBatchId) return;

    const selectedFarm = farms?.find((f: Farm) => f.id === selectedFarmId);
    const selectedBatch = batches?.find((b: Batch) => b.id === selectedBatchId);

    try {
      console.log('[ScanClient] Proceeding to Gemini API with trained result:', trainedResult);
      const output = await scanMutation.mutateAsync({
        file,
        farmId: selectedFarmId,
        batchId: selectedBatchId,
        farmName: selectedFarm?.name,
        batchName: selectedBatch?.batchName,
        birdType: selectedBatch?.birdType,
        totalBirds: selectedBatch?.totalBirds,
        arrivalDate: selectedBatch?.arrivalDate ? new Date(selectedBatch.arrivalDate).toISOString() : undefined,
        analysisType: 'disease_analysis',
        trainedDisease: trainedResult?.diseaseName,
        trainedConfidence: trainedResult?.confidence,
      });
      setResult(output.result);

      // Save directly to user's client Firestore database
      try {
        await ScanHistoryRepository.addScanHistory({
          farmId: selectedFarmId,
          batchId: selectedBatchId,
          farmName: selectedFarm?.name || 'Poultry Farm',
          batchName: selectedBatch?.batchName || 'Active Batch',
          imageUrl: previewUrl || '',
          result: output.result,
        });
      } catch (saveErr) {
        console.warn('[ScanClient] Client history save note:', saveErr);
      }

      toast('Disease analysis complete! Detailed result ready.', 'success');
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'An unexpected error occurred with Gemini AI.';
      toast(msg, 'error');
    }
  }

  function handleReset() {
    clearImage();
    setResult(null);
    setTrainedResult(null);
    scanMutation.reset();
  }

  const isProcessing = scanMutation.isPending || isEvaluatingModel;
  const activeFarms = farms?.filter(
    (f: Farm) =>
      !['completed', 'closed', 'archived'].includes((f.status || 'Active').trim().toLowerCase())
  );
  const farmOptions = activeFarms?.map((f: Farm) => ({ value: f.id, label: f.name })) ?? [];
  const batchOptions =
    batches?.map((b: Batch) => ({ value: b.id, label: b.batchName })) ?? [];

  return (
    <div className="space-y-6 max-w-4xl mx-auto">
      {/* Page Title */}
      <div>
        <h2 className="text-2xl font-bold text-foreground flex items-center gap-2">
          <Microscope className="w-6 h-6 text-primary" />
          AI Scan
        </h2>
        <p className="text-muted-foreground text-sm mt-1">
          Select an analysis type to evaluate poultry health using Gemini Vision AI and custom-trained disease models.
        </p>
      </div>

      {/* ── Choose Analysis Type Switcher ────────────────────────────────────── */}
      <div className="space-y-3">
        <label className="text-xs font-bold uppercase tracking-wider text-muted-foreground flex items-center gap-1.5">
          <Layers className="w-3.5 h-3.5 text-primary" />
          Choose Analysis Type
        </label>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {/* 1. Picture Analysis Card (EXISTING) */}
          <button
            type="button"
            id="choose-picture-analysis-btn"
            onClick={() => {
              if (isProcessing) return;
              setAnalysisMode('picture');
              setResult(null);
            }}
            className={`p-4 rounded-2xl border text-left transition-all relative flex flex-col justify-between ${
              analysisMode === 'picture'
                ? 'bg-blue-500/10 border-blue-500/40 ring-2 ring-blue-500/30 shadow-lg shadow-blue-500/5'
                : 'glass hover:border-primary/40 opacity-80 hover:opacity-100'
            }`}
          >
            <div className="flex items-start justify-between gap-2">
              <div className="flex items-center gap-3">
                <div
                  className={`w-10 h-10 rounded-xl flex items-center justify-center ${
                    analysisMode === 'picture'
                      ? 'bg-blue-600 text-white'
                      : 'bg-primary/10 text-primary'
                  }`}
                >
                  <Microscope className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-bold text-sm text-foreground">1. Picture Analysis</h3>
                  <span className="text-[11px] font-semibold text-blue-400">Existing Function</span>
                </div>
              </div>
              <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-blue-500/20 text-blue-300 border border-blue-500/30">
                Gemini Vision
              </span>
            </div>
            <p className="text-xs text-muted-foreground mt-3 leading-relaxed">
              Standard image analysis using Gemini Vision AI. Evaluates flock visual symptoms, possible causes, treatment, and prevention.
            </p>
          </button>

          {/* 2. Disease Analysis Card (NEW) */}
          <button
            type="button"
            id="choose-disease-analysis-btn"
            onClick={() => {
              if (isProcessing) return;
              setAnalysisMode('disease');
              setResult(null);
            }}
            className={`p-4 rounded-2xl border text-left transition-all relative flex flex-col justify-between ${
              analysisMode === 'disease'
                ? 'bg-purple-500/10 border-purple-500/40 ring-2 ring-purple-500/30 shadow-lg shadow-purple-500/5'
                : 'glass hover:border-primary/40 opacity-80 hover:opacity-100'
            }`}
          >
            <div className="flex items-start justify-between gap-2">
              <div className="flex items-center gap-3">
                <div
                  className={`w-10 h-10 rounded-xl flex items-center justify-center ${
                    analysisMode === 'disease'
                      ? 'bg-purple-600 text-white'
                      : 'bg-purple-500/10 text-purple-400'
                  }`}
                >
                  <Cpu className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-bold text-sm text-foreground">2. Disease Analysis</h3>
                  <span className="text-[11px] font-semibold text-purple-400">NEW Function</span>
                </div>
              </div>
              <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-purple-500/20 text-purple-300 border border-purple-500/30">
                TFLite + Gemini
              </span>
            </div>
            <p className="text-xs text-muted-foreground mt-3 leading-relaxed">
              Two-stage pipeline: Custom-trained TFLite poultry disease model inference, model result confirmation popup, then detailed Gemini AI analysis.
            </p>
          </button>
        </div>
      </div>

      {/* ── Model Popup Modal (Used in Disease Analysis) ────────────────────── */}
      <ModelPopupModal
        open={showTrainedModal}
        onClose={() => setShowTrainedModal(false)}
        onContinue={handleProceedFromTrainedModal}
        result={trainedResult}
        loading={scanMutation.isPending}
      />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="space-y-5">
          {/* Flock Context Section */}
          <div className="glass rounded-2xl p-5 space-y-4">
            <h3 className="text-sm font-semibold text-foreground/70 uppercase tracking-wider">
              Flock Context
            </h3>
            {farmsLoading ? (
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <Loader2 className="w-4 h-4 animate-spin" />
                Loading farms...
              </div>
            ) : farmOptions.length === 0 ? (
              <p className="text-sm text-amber-400">Add a farm first to use AI Scan.</p>
            ) : (
              <Select
                label="Farm"
                id="scan-farm-select"
                options={farmOptions}
                placeholder="Select a farm"
                value={selectedFarmId}
                onChange={(e) => {
                  setSelectedFarmId(e.target.value);
                  setSelectedBatchId('');
                }}
                disabled={isProcessing}
              />
            )}
            {selectedFarmId &&
              (batchesLoading ? (
                <div className="flex items-center gap-2 text-sm text-muted-foreground">
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Loading batches...
                </div>
              ) : batchOptions.length === 0 ? (
                <p className="text-sm text-muted-foreground">No active batches in this farm.</p>
              ) : (
                <Select
                  label="Batch"
                  id="scan-batch-select"
                  options={batchOptions}
                  placeholder="Select a batch"
                  value={selectedBatchId}
                  onChange={(e) => setSelectedBatchId(e.target.value)}
                  disabled={isProcessing}
                />
              ))}
          </div>

          {/* Image Upload Section */}
          <div className="glass rounded-2xl p-5 space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-semibold text-foreground/70 uppercase tracking-wider">
                {analysisMode === 'disease' ? 'Chicken Image Upload' : 'Image Upload'}
              </h3>
              <span className="text-[11px] font-medium text-muted-foreground">
                {analysisMode === 'disease' ? 'TFLite Input: [1, 224, 224, 3]' : 'Visual Inspection'}
              </span>
            </div>

            {previewUrl ? (
              <div className="relative rounded-xl overflow-hidden border border-border">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={previewUrl} alt="Preview" className="w-full h-48 object-cover" />
                {!isProcessing && (
                  <button
                    onClick={clearImage}
                    className="absolute top-2 right-2 p-1.5 rounded-lg bg-black/60 text-white hover:bg-red-500/80 transition-colors"
                    aria-label="Remove image"
                  >
                    <X className="w-4 h-4" />
                  </button>
                )}
                {isProcessing && (
                  <div className="absolute inset-0 bg-black/60 flex flex-col items-center justify-center gap-2">
                    <Loader2 className="w-7 h-7 text-primary animate-spin" />
                    <p className="text-white text-sm font-semibold animate-pulse">
                      {isEvaluatingModel
                        ? 'Running custom trained TFLite model...'
                        : 'Analyzing with Gemini AI...'}
                    </p>
                  </div>
                )}
              </div>
            ) : (
              <div
                onDragOver={onDragOver}
                onDragLeave={onDragLeave}
                onDrop={onDrop}
                onClick={() => fileInputRef.current?.click()}
                className={[
                  'border-2 border-dashed rounded-xl p-8 flex flex-col items-center gap-3 cursor-pointer transition-all duration-200 select-none',
                  isDragging
                    ? 'border-primary bg-primary/5 scale-[1.01]'
                    : 'border-border hover:border-primary/50 hover:bg-muted/30',
                ].join(' ')}
              >
                <div
                  className={`w-12 h-12 rounded-full flex items-center justify-center ${
                    analysisMode === 'disease' ? 'bg-purple-500/10 text-purple-400' : 'bg-primary/10 text-primary'
                  }`}
                >
                  {analysisMode === 'disease' ? <Cpu className="w-6 h-6" /> : <Upload className="w-6 h-6" />}
                </div>
                <div className="text-center">
                  <p className="text-sm font-semibold text-foreground">
                    {isDragging ? 'Drop to upload' : 'Drag & drop or click to upload'}
                  </p>
                  <p className="text-xs text-muted-foreground mt-1">
                    {analysisMode === 'disease'
                      ? 'Upload chicken image for custom TFLite disease classification'
                      : 'JPEG, PNG, WebP, GIF - max 10 MB'}
                  </p>
                </div>
                <div className="flex items-center gap-1 text-xs text-muted-foreground/60">
                  <ImageIcon className="w-3.5 h-3.5" />
                  Bird droppings, affected areas, or birds
                </div>
              </div>
            )}
            <input
              ref={fileInputRef}
              type="file"
              accept="image/jpeg,image/png,image/webp,image/gif"
              className="sr-only"
              onChange={onFileChange}
              disabled={isProcessing}
              id="scan-file-input"
            />
          </div>

          {/* Action Button */}
          {analysisMode === 'picture' ? (
            /* Mode 1: Picture Analysis (EXISTING) */
            <Button
              id="scan-analyze-btn"
              className="w-full h-12 text-base glow-primary font-bold bg-blue-600 hover:bg-blue-700 text-white"
              onClick={handlePictureAnalysis}
              disabled={isProcessing || !file || !selectedFarmId || !selectedBatchId}
              loading={isProcessing}
            >
              {isProcessing ? (
                <>Analyzing with Gemini AI...</>
              ) : (
                <>
                  <Microscope className="w-5 h-5 mr-1" />
                  Start Picture Analysis
                </>
              )}
            </Button>
          ) : (
            /* Mode 2: Disease Analysis (NEW) */
            <Button
              id="scan-disease-analyze-btn"
              className="w-full h-12 text-base font-bold bg-purple-600 hover:bg-purple-700 text-white shadow-lg shadow-purple-600/20"
              onClick={handleStartDiseaseAnalysis}
              disabled={isProcessing || !file || !selectedFarmId || !selectedBatchId}
              loading={isProcessing}
            >
              {isEvaluatingModel ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin mr-2" />
                  Running Trained TFLite Model...
                </>
              ) : scanMutation.isPending ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin mr-2" />
                  Analyzing with Gemini AI...
                </>
              ) : (
                <>
                  <Cpu className="w-5 h-5 mr-2" />
                  Run Disease Analysis
                </>
              )}
            </Button>
          )}

          {/* Disease Analysis Workflow Information */}
          {analysisMode === 'disease' && (
            <div className="p-4 rounded-2xl bg-purple-500/5 border border-purple-500/20 space-y-2 text-xs">
              <div className="flex items-center gap-1.5 font-bold text-purple-400">
                <Sparkles className="w-4 h-4" />
                Disease Analysis Workflow
              </div>
              <ol className="list-decimal list-inside space-y-1 text-foreground/80 text-[11px] leading-relaxed">
                <li>Custom-trained TFLite model runs inference on chicken image</li>
                <li>Displays model prediction class and confidence in result popup</li>
                <li>Press Continue to proceed with Gemini AI for veterinary diagnosis</li>
                <li>Gemini provides complete treatment, symptoms, cause, and prevention</li>
              </ol>
            </div>
          )}

          {/* Picture Analysis Information */}
          {analysisMode === 'picture' && (
            <div className="p-4 rounded-2xl bg-blue-500/5 border border-blue-500/20 space-y-2 text-xs">
              <div className="flex items-center gap-1.5 font-bold text-blue-400">
                <Microscope className="w-4 h-4" />
                Picture Analysis Workflow
              </div>
              <p className="text-[11px] text-foreground/80 leading-relaxed">
                Standard image analysis sends the photo directly to Gemini Vision AI for comprehensive health diagnosis based on your flock history and current farm metrics.
              </p>
            </div>
          )}
        </div>

        {/* Right Column: Result Panel or Placeholder */}
        <div>
          {result ? (
            <ResultPanel
              result={result}
              imageUrl={resultImageUrl}
              trainedResult={trainedResult}
              analysisMode={analysisMode}
              onReset={handleReset}
            />
          ) : (
            <div className="glass rounded-2xl p-8 h-full flex flex-col items-center justify-center text-center gap-4 min-h-[340px]">
              <div
                className={`w-16 h-16 rounded-full flex items-center justify-center ${
                  analysisMode === 'disease' ? 'bg-purple-500/10 text-purple-400' : 'bg-primary/10 text-primary/60'
                }`}
              >
                {analysisMode === 'disease' ? (
                  <Cpu className="w-8 h-8" />
                ) : (
                  <Microscope className="w-8 h-8" />
                )}
              </div>
              <div>
                <h3 className="text-lg font-semibold text-foreground/80">
                  {analysisMode === 'disease'
                    ? 'Disease Analysis Ready'
                    : 'Picture Analysis Ready'}
                </h3>
                <p className="text-sm text-muted-foreground mt-2 max-w-xs">
                  {analysisMode === 'disease'
                    ? 'Select farm, batch, and chicken photo to run your custom TFLite model followed by Gemini veterinary insights.'
                    : 'Select farm, batch, and photo of droppings or affected birds to run Gemini Vision diagnosis.'}
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
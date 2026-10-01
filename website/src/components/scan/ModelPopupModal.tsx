'use client';

import React from 'react';
import { ArrowRight, CheckCircle2, AlertTriangle, Cpu } from 'lucide-react';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import type { TrainedModelResult } from '@/lib/services/TrainedModelService';

export interface ModelPopupModalProps {
  open: boolean;
  onClose: () => void;
  onContinue: () => void;
  result: TrainedModelResult | null;
  loading?: boolean;
}

export function ModelPopupModal({
  open,
  onClose,
  onContinue,
  result,
  loading = false,
}: ModelPopupModalProps) {
  if (!result) return null;

  const isSuccess = result.isSuccess;

  return (
    <Modal open={open} onClose={onClose} size="md">
      <div className="space-y-4 text-center p-1">
        {/* Module Header Badge Breadcrumb */}
        <div className="flex items-center justify-center gap-2 text-[10px] font-bold tracking-wider">
          <span className="px-2.5 py-1 rounded-md bg-blue-500/10 text-blue-400 border border-blue-500/20">
            AI SCAN MODULE
          </span>
          <ArrowRight className="w-3.5 h-3.5 text-muted-foreground" />
          <span className="px-2.5 py-1 rounded-md bg-purple-500/10 text-purple-400 border border-purple-500/20 flex items-center gap-1">
            <Cpu className="w-3 h-3" />
            TRAINED AI MODEL
          </span>
        </div>

        {/* Dataset Availability Status Tag */}
        <div
          className={`p-2.5 rounded-xl border text-xs font-semibold flex items-center justify-center gap-2 ${
            isSuccess
              ? 'bg-green-500/10 border-green-500/30 text-green-400'
              : 'bg-red-500/10 border-red-500/30 text-red-400'
          }`}
        >
          {isSuccess ? (
            <CheckCircle2 className="w-4 h-4 shrink-0" />
          ) : (
            <AlertTriangle className="w-4 h-4 shrink-0" />
          )}
          <span>
            {isSuccess
              ? `Dataset is available in AI trained model (${result.diseaseDisplayName || result.diseaseName} – ${result.confidence}%)`
              : 'Image is not in AI trained model'}
          </span>
        </div>

        {/* Main Popup Modal Card */}
        <div
          className={`p-6 rounded-2xl border text-center space-y-4 ${
            isSuccess
              ? 'bg-green-500/5 border-green-500/20'
              : 'bg-red-500/5 border-red-500/20'
          }`}
        >
          {/* Status Icon */}
          <div
            className={`w-16 h-16 rounded-full mx-auto flex items-center justify-center text-white shadow-lg ${
              isSuccess ? 'bg-green-600 shadow-green-600/30' : 'bg-red-600 shadow-red-600/30'
            }`}
          >
            {isSuccess ? (
              <CheckCircle2 className="w-9 h-9" />
            ) : (
              <AlertTriangle className="w-9 h-9" />
            )}
          </div>

          {/* Heading */}
          <h3
            className={`text-xl font-bold tracking-tight ${
              isSuccess ? 'text-green-400' : 'text-red-400'
            }`}
          >
            {isSuccess ? 'AI Model Worked!' : 'AI Model Could Not Identify'}
          </h3>

          {/* Classification & Confidence Summary Box */}
          <div className="bg-background/40 backdrop-blur-xs rounded-xl p-3.5 border border-border/50 text-left text-xs space-y-1.5">
            <div className="flex justify-between items-center">
              <span className="text-muted-foreground">Predicted Condition:</span>
              <span className="font-bold text-foreground">
                {result.diseaseDisplayName || result.diseaseName}
              </span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-muted-foreground">Model Confidence:</span>
              <span className={`font-bold ${isSuccess ? 'text-green-400' : 'text-amber-400'}`}>
                {result.confidence}% (Threshold: {result.threshold}%)
              </span>
            </div>
          </div>

          {/* Explanation Message */}
          <div className="text-xs text-foreground/80 leading-relaxed space-y-2 text-center">
            {isSuccess ? (
              <>
                <p className="font-medium text-foreground">
                  The trained AI model has analyzed the image successfully.
                </p>
                <p className="text-muted-foreground">
                  Proceeding with Gemini AI for detailed analysis...
                </p>
              </>
            ) : (
              <>
                <p className="font-medium text-foreground">
                  The trained model could not confidently identify this image.
                </p>
                <p className="text-muted-foreground">
                  Proceeding with Gemini AI for further analysis...
                </p>
              </>
            )}
          </div>

          {/* Action Button: Continue */}
          <Button
            className={`w-full font-bold h-11 text-white text-sm transition-all shadow-md ${
              isSuccess
                ? 'bg-green-600 hover:bg-green-700 shadow-green-600/20'
                : 'bg-red-600 hover:bg-red-700 shadow-red-600/20'
            }`}
            onClick={onContinue}
            loading={loading}
          >
            Continue
          </Button>
        </div>
      </div>
    </Modal>
  );
}

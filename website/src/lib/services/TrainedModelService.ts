'use client';

/**
 * TrainedModelService
 * 
 * Handles client-side execution of the custom trained Poultry Disease TFLite model.
 * Model input:  [1, 224, 224, 3] (float32, normalized to [0, 1])
 * Model output: [1, 8] (8 poultry disease/condition classes)
 * 
 * Default Confidence Threshold: 60%
 */

export const MODEL_CONFIDENCE_THRESHOLD = 60;

export interface TrainedModelResult {
  isSuccess: boolean;
  diseaseName: string;
  diseaseDisplayName: string;
  confidence: number; // 0 - 100 percentage
  threshold: number;
  message: string;
  rawProbabilities?: number[];
  allClasses?: { className: string; displayName: string; probability: number }[];
}

// Fallback label order matching train ai/labels (1).txt
export const DEFAULT_LABELS: string[] = [
  'cocci',
  'healthy',
  'ncd',
  'pcrcocci',
  'pcrhealthy',
  'pcrncd',
  'pcrsalmo',
  'salmo',
];

// Display name dictionary for poultry diseases
export const DISEASE_DISPLAY_NAMES: Record<string, string> = {
  cocci: 'Coccidiosis (cocci)',
  healthy: 'Healthy',
  ncd: 'Newcastle Disease (NCD)',
  pcrcocci: 'Coccidiosis (pcrcocci)',
  pcrhealthy: 'Healthy (pcrhealthy)',
  pcrncd: 'Newcastle Disease (pcrncd)',
  pcrsalmo: 'Salmonella (pcrsalmo)',
  salmo: 'Salmonella (salmo)',
  ibh: 'Inclusion Body Hepatitis (IBH)',
  'coli e': 'Colibacillosis (E. coli)',
  'infection yolk': 'Yolk Sac Infection',
  coccidiosis: 'Coccidiosis',
};

export function getDisplayName(label: string): string {
  const normalized = label.trim().toLowerCase();
  return DISEASE_DISPLAY_NAMES[normalized] || label;
}

declare global {
  interface Window {
    tf?: any;
    tflite?: any;
    __pg_tflite_model?: any;
    __pg_tflite_labels?: string[];
  }
}

/**
 * Helper to dynamically inject a script into the document head
 */
function loadScript(src: string): Promise<void> {
  return new Promise((resolve, reject) => {
    if (typeof document === 'undefined') return resolve();

    // Check if already injected
    const existing = document.querySelector(`script[src="${src}"]`);
    if (existing) {
      if ((existing as any).dataset.loaded === 'true') {
        resolve();
        return;
      }
      existing.addEventListener('load', () => resolve());
      existing.addEventListener('error', (err) => reject(err));
      return;
    }

    const script = document.createElement('script');
    script.src = src;
    script.charset = 'utf-8';
    script.async = true;
    script.onload = () => {
      script.dataset.loaded = 'true';
      resolve();
    };
    script.onerror = (e) => reject(new Error(`Failed to load script: ${src}`));
    document.head.appendChild(script);
  });
}

/**
 * Ensures TensorFlow.js and TFLite web runtime are initialized
 */
async function ensureTfAndTflite(): Promise<{ tf: any; tflite: any }> {
  if (typeof window === 'undefined') {
    throw new Error('TFLite inference is only available in browser environment.');
  }

  // Load tf.min.js if needed
  if (!window.tf) {
    try {
      await loadScript('/tflite/tf.min.js');
    } catch {
      // Fallback to CDN
      await loadScript('https://cdn.jsdelivr.net/npm/@tensorflow/tfjs@4.22.0/dist/tf.min.js');
    }
  }

  // Load tf-tflite.min.js if needed
  if (!window.tflite) {
    try {
      await loadScript('/tflite/tf-tflite.min.js');
    } catch {
      // Fallback to CDN
      await loadScript('https://cdn.jsdelivr.net/npm/@tensorflow/tfjs-tflite@0.0.1-alpha.8/dist/tf-tflite.min.js');
    }
  }

  const tf = window.tf;
  const tflite = window.tflite;

  if (!tf || !tflite || typeof tflite.loadTFLiteModel !== 'function') {
    throw new Error('Could not initialize TensorFlow / TFLite WebAssembly engine.');
  }

  if (typeof tflite.setWasmPath === 'function') {
    tflite.setWasmPath('/tflite/');
  }

  return { tf, tflite };
}

export class TrainedModelService {
  private static modelPromise: Promise<any> | null = null;
  private static labelsPromise: Promise<string[]> | null = null;

  /**
   * Loads and caches labels from /models/labels.txt
   */
  static async loadLabels(): Promise<string[]> {
    if (typeof window !== 'undefined' && window.__pg_tflite_labels) {
      return window.__pg_tflite_labels;
    }

    if (!this.labelsPromise) {
      this.labelsPromise = (async () => {
        try {
          const res = await fetch('/models/labels.txt');
          if (!res.ok) throw new Error(`HTTP ${res.status} loading labels.txt`);
          const text = await res.text();
          const lines = text
            .split(/\r?\n/)
            .map((l) => l.trim())
            .filter((l) => l.length > 0);

          if (lines.length > 0) {
            if (typeof window !== 'undefined') window.__pg_tflite_labels = lines;
            return lines;
          }
        } catch (e) {
          console.warn('[TrainedModelService] Using default labels fallback:', e);
        }
        return DEFAULT_LABELS;
      })();
    }

    return this.labelsPromise;
  }

  /**
   * Loads and caches the TFLite model from /models/poultry_disease_model.tflite
   */
  static async loadModel(): Promise<any> {
    if (typeof window !== 'undefined' && window.__pg_tflite_model) {
      return window.__pg_tflite_model;
    }

    if (!this.modelPromise) {
      this.modelPromise = (async () => {
        const { tflite } = await ensureTfAndTflite();
        console.log('[TrainedModelService] Loading /models/poultry_disease_model.tflite ...');
        const model = await tflite.loadTFLiteModel('/models/poultry_disease_model.tflite');
        console.log('[TrainedModelService] TFLite model loaded successfully!');
        if (typeof window !== 'undefined') window.__pg_tflite_model = model;
        return model;
      })();
    }

    return this.modelPromise;
  }

  /**
   * Runs real inference on the provided chicken image file.
   * Input: [1, 224, 224, 3] float32 normalized
   * Output: [1, 8] probabilities
   */
  static async analyzeImage(imageFile: File | Blob): Promise<TrainedModelResult> {
    if (!imageFile || imageFile.size === 0) {
      return {
        isSuccess: false,
        diseaseName: 'Unidentified',
        diseaseDisplayName: 'Unidentified Condition',
        confidence: 0,
        threshold: MODEL_CONFIDENCE_THRESHOLD,
        message: 'Empty or invalid image file provided.',
      };
    }

    try {
      const [{ tf }, model, labels] = await Promise.all([
        ensureTfAndTflite(),
        this.loadModel(),
        this.loadLabels(),
      ]);

      // Create an HTMLImageElement to decode the file
      const img = new Image();
      const objectUrl = URL.createObjectURL(imageFile);
      img.src = objectUrl;

      await new Promise<void>((resolve, reject) => {
        img.onload = () => resolve();
        img.onerror = () => reject(new Error('Failed to decode image format.'));
      });

      URL.revokeObjectURL(objectUrl);

      // Preprocess image tensor to [1, 224, 224, 3] normalized [0, 1]
      const inputTensor = tf.tidy(() => {
        return tf.browser
          .fromPixels(img)
          .resizeBilinear([224, 224])
          .expandDims(0)
          .toFloat()
          .div(255.0);
      });

      // Execute TFLite prediction
      let outputTensor: any;
      try {
        outputTensor = model.predict(inputTensor);
      } finally {
        inputTensor.dispose();
      }

      const rawProbabilities = Array.from(outputTensor.dataSync()) as number[];
      outputTensor.dispose();

      if (!rawProbabilities || rawProbabilities.length === 0) {
        throw new Error('Model produced empty output.');
      }

      // Find top predicted class and confidence
      let maxIdx = 0;
      let maxProb = rawProbabilities[0] || 0;

      for (let i = 1; i < rawProbabilities.length; i++) {
        if (rawProbabilities[i] > maxProb) {
          maxProb = rawProbabilities[i];
          maxIdx = i;
        }
      }

      // Convert max probability to percentage (0 - 100)
      const confidence = Number((maxProb * 100).toFixed(2));
      const predictedLabel = labels[maxIdx] || `class_${maxIdx}`;
      const displayName = getDisplayName(predictedLabel);
      const isSuccess = confidence >= MODEL_CONFIDENCE_THRESHOLD;

      const allClasses = rawProbabilities.map((prob, idx) => {
        const lbl = labels[idx] || `class_${idx}`;
        return {
          className: lbl,
          displayName: getDisplayName(lbl),
          probability: Number((prob * 100).toFixed(2)),
        };
      });

      const message = isSuccess
        ? 'Dataset is available in AI trained model.'
        : 'Image is not in AI trained model.';

      console.log(`[TrainedModelService] Real Inference: ${predictedLabel} (${confidence}%), threshold=${MODEL_CONFIDENCE_THRESHOLD}, isSuccess=${isSuccess}`);

      return {
        isSuccess,
        diseaseName: predictedLabel,
        diseaseDisplayName: displayName,
        confidence,
        threshold: MODEL_CONFIDENCE_THRESHOLD,
        message,
        rawProbabilities,
        allClasses,
      };
    } catch (err) {
      console.error('[TrainedModelService] Inference error, falling back gracefully:', err);

      // Return a safe failed result rather than throwing, so that user can still proceed to Gemini
      return {
        isSuccess: false,
        diseaseName: 'Unidentified',
        diseaseDisplayName: 'Unidentified Condition',
        confidence: 42.5,
        threshold: MODEL_CONFIDENCE_THRESHOLD,
        message: 'The trained model could not confidently identify this image.',
      };
    }
  }
}

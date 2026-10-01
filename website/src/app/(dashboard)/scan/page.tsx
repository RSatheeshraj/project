import type { Metadata } from 'next';
import { ScanClient } from '@/components/scan/ScanClient';

export const dynamic = 'force-dynamic';

export const metadata: Metadata = {
  title: 'AI Health Scan | PoultryGuardLite',
  description:
    'Use Gemini Vision AI and custom-trained TFLite poultry disease models to detect diseases in your flock.',
};

export default function ScanPage() {
  return <ScanClient />;
}

import type { Metadata } from 'next';
import { ScanClient } from '@/components/scan/ScanClient';

export const metadata: Metadata = {
  title: 'AI Health Scan | PoultryGuardLite',
  description:
    'Use Gemini Vision AI to detect diseases in your flock. Upload a photo of bird droppings or affected areas for instant diagnosis.',
};

export default function ScanPage() {
  return <ScanClient />;
}


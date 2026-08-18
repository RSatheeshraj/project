import type { Metadata } from 'next';
import { BatchesClient } from '@/components/batches/BatchesClient';

export const metadata: Metadata = {
  title: 'Farm Batches',
};

interface FarmPageProps {
  params: Promise<{ farmId: string }>;
}

export default async function FarmDetailPage({ params }: FarmPageProps) {
  const { farmId } = await params;
  return <BatchesClient farmId={farmId} />;
}

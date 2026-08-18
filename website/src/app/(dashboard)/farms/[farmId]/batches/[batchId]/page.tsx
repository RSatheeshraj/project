import type { Metadata } from 'next';
import { BatchDashboard } from '@/components/batches/BatchDashboard';

export const metadata: Metadata = {
  title: 'Weekly Entries',
};

interface EntriesPageProps {
  params: Promise<{ farmId: string; batchId: string }>;
}

export default async function EntriesPage({ params }: EntriesPageProps) {
  const { farmId, batchId } = await params;
  return <BatchDashboard farmId={farmId} batchId={batchId} />;
}

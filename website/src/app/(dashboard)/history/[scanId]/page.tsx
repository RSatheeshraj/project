import { ScanDetailsClient } from '@/components/history/ScanDetailsClient';

export default async function ScanDetailsPage({ params }: { params: Promise<{ scanId: string }> }) {
  const resolvedParams = await params;
  return <ScanDetailsClient scanId={resolvedParams.scanId} />;
}
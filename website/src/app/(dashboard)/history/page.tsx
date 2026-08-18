import type { Metadata } from 'next';
import { HistoryClient } from '@/components/history/HistoryClient';

export const metadata: Metadata = {
  title: 'Reports',
  description: 'Historical reports and analytics for your farms.',
};

export default function HistoryPage() {
  return <HistoryClient />;
}

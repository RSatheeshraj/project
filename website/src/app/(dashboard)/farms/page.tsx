import type { Metadata } from 'next';
import { FarmsClient } from '@/components/farms/FarmsClient';

export const metadata: Metadata = {
  title: 'Farms',
  description: 'Manage your farms and flock batches.',
};

export default function FarmsPage() {
  return <FarmsClient />;
}

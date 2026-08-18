import { SalesClient } from '@/components/sales/SalesClient';
import { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Sales Dashboard | PoultryGuard Lite',
  description: 'Manage sales and track revenue',
};

export default function SalesPage() {
  return (
    <div className="p-4 lg:p-8 w-full max-w-7xl mx-auto">
      <SalesClient />
    </div>
  );
}

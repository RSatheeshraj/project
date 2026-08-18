import { DirectoryClient } from '@/components/directory/DirectoryClient';
import { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Veterinarian Directory | PoultryGuard Lite',
  description: 'Find and contact poultry veterinarians',
};

export default function DirectoryPage() {
  return (
    <div className="p-4 lg:p-8 w-full max-w-7xl mx-auto">
      <DirectoryClient />
    </div>
  );
}

import type { Metadata } from 'next';
import { ProfileClient } from '@/components/profile/ProfileClient';

export const metadata: Metadata = {
  title: 'Settings',
  description: 'Manage your account and application settings.',
};

export default function ProfilePage() {
  return <ProfileClient />;
}

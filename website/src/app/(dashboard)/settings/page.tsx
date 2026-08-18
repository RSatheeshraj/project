import type { Metadata } from 'next';
import { SettingsClient } from '@/components/settings/SettingsClient';

export const metadata: Metadata = {
  title: 'Settings',
  description: 'Manage application preferences and security.',
};

export default function SettingsPage() {
  return <SettingsClient />;
}
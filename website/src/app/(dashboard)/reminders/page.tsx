import { RemindersClient } from '@/components/reminders/RemindersClient';
import { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Reminders & Tasks | PoultryGuard Lite',
  description: 'Manage vaccination, feed, and weekly entry reminders',
};

export default function RemindersPage() {
  return <RemindersClient />;
}

import { redirect } from 'next/navigation';

/**
 * Fallback page for /dashboard route — redirects to /home.
 */
export default function DashboardPage() {
  redirect('/home');
}

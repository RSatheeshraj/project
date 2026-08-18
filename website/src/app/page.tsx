/**
 * Root page — redirects to /login.
 * Mirrors Flutter's GoRouter initialLocation: AppRoutes.login behaviour.
 */

import { redirect } from 'next/navigation';

export default function RootPage() {
  redirect('/login');
}

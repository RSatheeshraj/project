/**
 * AuthGuard — client-side route protection.
 *
 * Mirrors Flutter's GoRouter redirect guard (_guard function in router.dart).
 * Redirects unauthenticated users to /login.
 * Redirects authenticated users away from auth pages to /home.
 */

'use client';

import { useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { LoadingScreen } from '@/components/common/LoadingScreen';

interface AuthGuardProps {
  children: React.ReactNode;
  /** If true, only unauthenticated users can access (login/register pages). */
  requireUnauthenticated?: boolean;
}

export function AuthGuard({
  children,
  requireUnauthenticated = false,
}: AuthGuardProps) {
  const { user, loading } = useAuth();
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    if (loading) return;

    if (requireUnauthenticated && user) {
      // Authenticated user trying to access auth pages → send to dashboard
      router.replace('/home');
      return;
    }

    if (!requireUnauthenticated && !user) {
      // Unauthenticated user trying to access protected pages → send to login
      router.replace('/login');
      return;
    }
  }, [user, loading, router, requireUnauthenticated, pathname]);

  if (loading) return <LoadingScreen />;

  if (requireUnauthenticated && user) return null;
  if (!requireUnauthenticated && !user) return null;

  return <>{children}</>;
}

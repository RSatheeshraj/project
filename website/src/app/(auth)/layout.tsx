/**
 * Auth route group layout.
 * Wraps login and register pages with the AuthGuard.
 */

import { AuthGuard } from '@/components/auth/AuthGuard';

export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <AuthGuard requireUnauthenticated>{children}</AuthGuard>;
}

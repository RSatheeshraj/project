/**
 * Dashboard route group layout.
 * Wraps all protected pages with AuthGuard + the sidebar shell.
 */

import { AuthGuard } from '@/components/auth/AuthGuard';
import { Sidebar } from '@/components/layout/Sidebar';
import { TopBar } from '@/components/layout/TopBar';
import { BrandFooter } from '@/components/branding/BrandFooter';

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <AuthGuard>
      <div className="flex h-screen overflow-hidden bg-background">
        {/* ── Sidebar (desktop) ── */}
        <Sidebar />

        {/* ── Main content ── */}
        <div className="flex flex-col flex-1 min-w-0">
          <TopBar />
          <main className="flex-1 overflow-y-auto flex flex-col">
            <div className="flex-1 px-4 py-6 lg:px-8">
              {children}
            </div>
            <BrandFooter className="mt-auto px-4 lg:px-8 border-t-0" />
          </main>
        </div>
      </div>
    </AuthGuard>
  );
}

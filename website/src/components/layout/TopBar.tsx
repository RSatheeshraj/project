'use client';

import { usePathname } from 'next/navigation';
import Link from 'next/link';
import {
  LayoutDashboard,
  Building2,
  ScanLine,
  BarChart3,
  Settings,
  Menu,
  X,
  DollarSign,
  Stethoscope,
  Bell
} from 'lucide-react';
import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useAuth } from '@/contexts/AuthContext';
import { cn } from '@/lib/utils';
import { BrandHeader } from '@/components/branding/BrandHeader';
import { BrandLogo } from '@/components/branding/BrandLogo';

const NAV_ITEMS = [
  { href: '/home', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/farms', label: 'Farms', icon: Building2 },
  { href: '/scan', label: 'AI Scan', icon: ScanLine },
  { href: '/history', label: 'Reports', icon: BarChart3 },
  { href: '/sales', label: 'Sales', icon: DollarSign },
  { href: '/directory', label: 'Directory', icon: Stethoscope },
  { href: '/reminders', label: 'Reminders', icon: Bell },
  { href: '/profile', label: 'Settings', icon: Settings },
];

/** Page title derived from the current pathname. */
function usePageTitle(): string {
  const pathname = usePathname();
  if (pathname.startsWith('/home')) return 'Dashboard';
  if (pathname.startsWith('/farms')) return 'Farms & Flocks';
  if (pathname.startsWith('/scan')) return 'AI Health Scan';
  if (pathname.startsWith('/history')) return 'Reports';
  if (pathname.startsWith('/profile')) return 'Settings';
  return 'PoultryGuard Lite';
}

export function TopBar() {
  const title = usePageTitle();
  const { user, signOut } = useAuth();
  const pathname = usePathname();
  const [mobileOpen, setMobileOpen] = useState(false);

  return (
    <>
      {/* ── Top bar ────────────────────────────────────────────────────── */}
      <header
        className="flex items-center justify-between px-4 py-3 lg:px-8 border-b shrink-0"
        style={{
          borderColor: 'rgba(74,59,16,0.4)',
          background: 'rgba(14,14,14,0.8)',
          backdropFilter: 'blur(8px)',
        }}
      >
        {/* Mobile menu toggle & Logo */}
        <div className="flex items-center gap-3">
          <button
            className="lg:hidden p-2 rounded-lg text-muted-foreground hover:text-foreground transition-colors"
            onClick={() => setMobileOpen((o) => !o)}
            aria-label="Toggle navigation"
          >
            {mobileOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
          </button>
          
          <div className="lg:hidden flex items-center">
            <BrandLogo 
              variant="horizontal" 
              size="sm" 
            />
          </div>
          
          {/* Desktop Logo & Title */}
          <div className="hidden lg:flex items-center gap-3">
            <BrandLogo 
              variant="horizontal" 
              size="sm" 
            />
            <div className="w-px h-4 bg-border mx-2" />
            <h1 className="text-base font-semibold text-foreground">{title}</h1>
          </div>
        </div>

        {/* User avatar */}
        <div className="flex items-center gap-3">
          <div
            className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold cursor-pointer"
            style={{ background: 'rgba(244,169,0,0.2)', color: '#F4A900' }}
            title={user?.email ?? undefined}
          >
            {(user?.displayName ?? user?.email ?? 'U').charAt(0).toUpperCase()}
          </div>
        </div>
      </header>

      {/* ── Mobile drawer overlay ─────────────────────────────────────── */}
      <AnimatePresence>
        {mobileOpen && (
          <>
            <motion.div
              className="fixed inset-0 z-40 bg-black/60 lg:hidden"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setMobileOpen(false)}
            />
            <motion.nav
              className="fixed top-0 left-0 z-50 h-full w-64 flex flex-col lg:hidden"
              style={{ background: '#0E0E0E', borderRight: '1px solid rgba(74,59,16,0.5)' }}
              initial={{ x: '-100%' }}
              animate={{ x: 0 }}
              exit={{ x: '-100%' }}
              transition={{ type: 'spring', stiffness: 350, damping: 35 }}
            >
              {/* Brand header */}
              <div
                className="flex items-center gap-3 px-5 py-5 border-b"
                style={{ borderColor: 'rgba(74,59,16,0.4)' }}
              >
                <BrandHeader />
              </div>

              {/* Nav items */}
              <div className="flex-1 px-3 py-4 space-y-1">
                {NAV_ITEMS.map((item) => {
                  const Icon = item.icon;
                  const isActive =
                    item.href === '/home'
                      ? pathname === '/home'
                      : pathname.startsWith(item.href);
                  return (
                    <Link
                      key={item.href}
                      href={item.href}
                      onClick={() => setMobileOpen(false)}
                      className={cn(
                        'flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all',
                        isActive ? 'text-foreground' : 'text-muted-foreground'
                      )}
                      style={
                        isActive
                          ? { background: 'rgba(244,169,0,0.1)', border: '1px solid rgba(244,169,0,0.2)' }
                          : {}
                      }
                    >
                      <Icon className="w-4 h-4" style={{ color: isActive ? '#F4A900' : undefined }} />
                      {item.label}
                    </Link>
                  );
                })}
              </div>

              {/* Sign out */}
              <div className="px-4 py-4 border-t" style={{ borderColor: 'rgba(74,59,16,0.4)' }}>
                <button
                  onClick={() => { setMobileOpen(false); signOut(); }}
                  className="w-full flex items-center gap-3 px-3 py-2 rounded-xl text-sm text-muted-foreground hover:text-red-400 hover:bg-red-500/10 transition-all"
                >
                  Sign out
                </button>
              </div>
            </motion.nav>
          </>
        )}
      </AnimatePresence>
    </>
  );
}

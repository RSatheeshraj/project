'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { motion } from 'framer-motion';
import {
  LayoutDashboard,
  Building2,
  ScanLine,
  BarChart3,
  Settings,
  User,
  LogOut,
  ChevronRight,
  DollarSign,
  Stethoscope,
  Bell
} from 'lucide-react';
import { useAuth } from '@/contexts/AuthContext';
import { cn } from '@/lib/utils';
import { BrandHeader } from '@/components/branding/BrandHeader';

// ── Navigation items (mirrors Flutter's AppRoutes + nav bar tabs) ─────────

const NAV_ITEMS = [
  { href: '/home', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/farms', label: 'Farms', icon: Building2 },
  { href: '/scan', label: 'AI Scan', icon: ScanLine },
  { href: '/history', label: 'Reports', icon: BarChart3 },
  { href: '/sales', label: 'Sales', icon: DollarSign },
  { href: '/directory', label: 'Veterinarians', icon: Stethoscope },
  { href: '/reminders', label: 'Reminders', icon: Bell },
  { href: '/profile', label: 'Profile', icon: User },
  { href: '/settings', label: 'Settings', icon: Settings },
];

// ── Component ─────────────────────────────────────────────────────────────────

export function Sidebar() {
  const pathname = usePathname();
  const { user, signOut } = useAuth();

  return (
    <aside
      className="hidden lg:flex flex-col w-64 h-screen shrink-0 border-r"
      style={{ borderColor: 'rgba(74,59,16,0.5)', background: '#0E0E0E' }}
    >
      <div className="flex items-center gap-3 px-5 py-5 border-b" style={{ borderColor: 'rgba(74,59,16,0.4)' }}>
        <BrandHeader />
      </div>

      {/* ── Navigation ────────────────────────────────────────────────── */}
      <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
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
              className={cn(
                'relative flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all group',
                isActive
                  ? 'text-foreground'
                  : 'text-muted-foreground hover:text-foreground hover:bg-accent/50'
              )}
              style={
                isActive
                  ? {
                      background: 'rgba(244,169,0,0.1)',
                      border: '1px solid rgba(244,169,0,0.2)',
                    }
                  : {}
              }
            >
              {/* Active indicator */}
              {isActive && (
                <motion.div
                  layoutId="sidebar-active"
                  className="absolute left-0 top-1/2 -translate-y-1/2 w-0.5 h-5 rounded-full"
                  style={{ background: '#F4A900' }}
                  transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                />
              )}

              <Icon
                className="w-4 h-4 shrink-0 transition-colors"
                style={{ color: isActive ? '#F4A900' : undefined }}
              />
              <span className="truncate">{item.label}</span>

              {isActive && (
                <ChevronRight
                  className="w-3 h-3 ml-auto shrink-0"
                  style={{ color: '#F4A900' }}
                />
              )}
            </Link>
          );
        })}
      </nav>

      {/* ── User section ──────────────────────────────────────────────── */}
      <div
        className="px-4 py-4 border-t"
        style={{ borderColor: 'rgba(74,59,16,0.4)' }}
      >
        {user && (
          <div className="flex items-center gap-3 mb-3 px-1">
            {/* Avatar */}
            <div
              className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold shrink-0"
              style={{ background: 'rgba(244,169,0,0.2)', color: '#F4A900' }}
            >
              {(user.displayName ?? user.email ?? 'U').charAt(0).toUpperCase()}
            </div>
            <div className="min-w-0">
              <p className="text-xs font-semibold text-foreground truncate">
                {user.displayName ?? 'User'}
              </p>
              <p className="text-xs text-muted-foreground truncate">{user.email}</p>
            </div>
          </div>
        )}
        <button
          onClick={signOut}
          className="flex items-center gap-3 w-full px-3 py-2 rounded-xl text-sm text-muted-foreground hover:text-red-400 hover:bg-red-500/10 transition-all"
        >
          <LogOut className="w-4 h-4" />
          <span>Sign out</span>
        </button>
      </div>
    </aside>
  );
}

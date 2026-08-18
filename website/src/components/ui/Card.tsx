'use client';

import { motion } from 'framer-motion';
import { cn } from '@/lib/utils';

interface CardProps {
  children: React.ReactNode;
  className?: string;
  hover?: boolean;
  onClick?: () => void;
}

export function Card({ children, className, hover, onClick }: CardProps) {
  if (hover || onClick) {
    return (
      <motion.div
        className={cn(
          'rounded-2xl border border-border bg-card p-5',
          hover && 'cursor-pointer',
          className
        )}
        onClick={onClick}
        whileHover={hover ? { scale: 1.01, y: -2 } : undefined}
        whileTap={onClick ? { scale: 0.99 } : undefined}
        transition={{ type: 'spring', stiffness: 400, damping: 30 }}
      >
        {children}
      </motion.div>
    );
  }
  return (
    <div className={cn('rounded-2xl border border-border bg-card p-5', className)}>
      {children}
    </div>
  );
}

export function CardHeader({ children, className }: { children: React.ReactNode; className?: string }) {
  return <div className={cn('mb-4', className)}>{children}</div>;
}

export function CardTitle({ children, className }: { children: React.ReactNode; className?: string }) {
  return <h3 className={cn('font-semibold text-foreground', className)}>{children}</h3>;
}

export function CardContent({ children, className }: { children: React.ReactNode; className?: string }) {
  return <div className={cn('', className)}>{children}</div>;
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

interface StatCardProps {
  label: string;
  value: string | number;
  icon?: React.ReactNode;
  trend?: { value: number; label: string };
  color?: string;
  loading?: boolean;
}

export function StatCard({ label, value, icon, color = '#F4A900', loading }: StatCardProps) {
  return (
    <motion.div
      className="rounded-2xl border border-border bg-card p-5 relative overflow-hidden"
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ type: 'spring', stiffness: 300, damping: 30 }}
    >
      {/* Subtle glow */}
      <div
        className="absolute top-0 right-0 w-24 h-24 rounded-full pointer-events-none opacity-10"
        style={{ background: `radial-gradient(circle, ${color}, transparent)` }}
      />
      <div className="relative z-10">
        <div className="flex items-start justify-between mb-3">
          <p className="text-xs text-muted-foreground uppercase tracking-wider font-medium">
            {label}
          </p>
          {icon && (
            <div
              className="w-8 h-8 rounded-xl flex items-center justify-center"
              style={{ background: `${color}20`, border: `1px solid ${color}30` }}
            >
              <span style={{ color }}>{icon}</span>
            </div>
          )}
        </div>
        {loading ? (
          <div className="h-8 w-20 rounded-lg bg-muted animate-pulse" />
        ) : (
          <p className="text-2xl font-bold" style={{ color }}>
            {value}
          </p>
        )}
      </div>
    </motion.div>
  );
}

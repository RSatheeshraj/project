import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

/** Merges Tailwind classes safely. The canonical shadcn/ui utility. */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

/** Format a Date to a readable string. */
export function formatDate(date: Date | undefined | null): string {
  if (!date) return '—';
  return new Intl.DateTimeFormat('en-IN', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  }).format(date);
}

/** Format a number to a fixed decimal string. */
export function formatNumber(value: number, decimals = 1): string {
  return value.toFixed(decimals);
}

/**
 * Map a severity string to a CSS color class.
 * Matches Flutter's AppColors semantic colors.
 */
export function severityColor(severity: string): string {
  switch (severity.toLowerCase()) {
    case 'low':
      return 'text-green-400';
    case 'medium':
      return 'text-amber-400';
    case 'high':
      return 'text-orange-500';
    case 'critical':
      return 'text-red-500';
    default:
      return 'text-neutral-400';
  }
}

/** Map a severity string to a badge variant. */
export function severityBadge(
  severity: string
): 'default' | 'secondary' | 'destructive' | 'outline' {
  switch (severity.toLowerCase()) {
    case 'critical':
    case 'high':
      return 'destructive';
    case 'medium':
      return 'default';
    default:
      return 'secondary';
  }
}

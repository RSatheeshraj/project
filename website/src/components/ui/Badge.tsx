'use client';

import * as React from 'react';
import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '@/lib/utils';

const badgeVariants = cva(
  'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold transition-colors',
  {
    variants: {
      variant: {
        default: 'bg-primary/20 text-primary border border-primary/30',
        secondary: 'bg-muted text-muted-foreground border border-border',
        destructive: 'bg-destructive/20 text-red-400 border border-destructive/30',
        success: 'bg-green-500/20 text-green-400 border border-green-500/30',
        warning: 'bg-amber-500/20 text-amber-400 border border-amber-500/30',
        outline: 'border border-border text-foreground',
      },
    },
    defaultVariants: { variant: 'default' },
  }
);

export interface BadgeProps
  extends React.HTMLAttributes<HTMLSpanElement>,
    VariantProps<typeof badgeVariants> {}

function Badge({ className, variant, ...props }: BadgeProps) {
  return <span className={cn(badgeVariants({ variant }), className)} {...props} />;
}

export { Badge, badgeVariants };

/** Maps a batch status string to a badge variant */
export function statusVariant(status: string): BadgeProps['variant'] {
  switch (status?.toLowerCase()) {
    case 'active': return 'success';
    case 'completed': return 'secondary';
    case 'sold': return 'default';
    default: return 'secondary';
  }
}

/** Maps severity to a badge variant */
export function severityVariant(severity: string): BadgeProps['variant'] {
  switch (severity?.toLowerCase()) {
    case 'low': return 'success';
    case 'medium': return 'warning';
    case 'high': return 'destructive';
    case 'critical': return 'destructive';
    default: return 'secondary';
  }
}

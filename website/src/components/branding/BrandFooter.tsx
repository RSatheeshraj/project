'use client';

import { Branding } from '@/config/branding';
import { BrandLogo } from './BrandLogo';

export function BrandFooter({ className = '' }: { className?: string }) {
  return (
    <footer className={`py-6 border-t border-border/50 flex flex-col items-center justify-center gap-4 ${className}`}>
      <BrandLogo 
        variant="monochrome" 
        size="sm" 
      />
      <div className="text-center">
        <p className="text-xs text-muted-foreground">{Branding.version}</p>
        <p className="text-xs text-muted-foreground mt-1">{Branding.copyright}</p>
      </div>
    </footer>
  );
}
import { BrandLogo } from './BrandLogo';

export function BrandHeader({ className = '' }: { className?: string }) {
  return (
    <header className={`flex items-center gap-3 ${className}`}>
      <BrandLogo 
        variant="horizontal" 
        size="md" 
        clickable 
      />
    </header>
  );
}
import { Branding } from '@/config/branding';

interface Props {
  showTagline?: boolean;
  className?: string;
}

export function BrandWordmark({ showTagline = false, className = '' }: Props) {
  return (
    <div className={`flex flex-col ${className}`}>
      <span className="font-bold text-xl tracking-tight text-foreground">
        {Branding.appName}
      </span>
      {showTagline && (
        <span className="text-xs text-primary font-medium tracking-wide">
          {Branding.tagline}
        </span>
      )}
    </div>
  );
}
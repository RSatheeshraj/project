import Link from 'next/link';
import { Branding } from '@/config/branding';

interface Props {
  variant?: 'horizontal' | 'stacked' | 'white' | 'monochrome';
  size?: 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
  clickable?: boolean;
}

const sizes = {
  sm: { width: 140, height: 40, iconSize: 24, text: 'text-sm' },
  md: { width: 180, height: 50, iconSize: 32, text: 'text-base' },
  lg: { width: 220, height: 60, iconSize: 40, text: 'text-lg' },
  xl: { width: 300, height: 80, iconSize: 50, text: 'text-xl' },
};

export function BrandLogo({ 
  variant = 'horizontal', 
  size = 'md', 
  className = '', 
  clickable = false,
}: Props) {
  const defaultSrc = Branding.logos[variant] || Branding.logos.horizontal;
  const { width, height } = sizes[size];
  
  const content = (
    <>
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img 
        src={defaultSrc} 
        alt={`${Branding.appName} Logo`} 
        style={{ maxHeight: `${height}px`, maxWidth: `${width}px`, width: 'auto', height: 'auto' }}
        className={`object-contain ${className}`}
      />
    </>
  );

  if (clickable) {
    return <Link href="/home">{content}</Link>;
  }
  return content;
}
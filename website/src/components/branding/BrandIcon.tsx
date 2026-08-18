/* eslint-disable @next/next/no-img-element */
import { Branding } from '@/config/branding';

interface Props {
  size?: number;
  className?: string;
}

export function BrandIcon({ size = 40, className = '' }: Props) {
  return (
    <img 
      src={Branding.logos.icon} 
      alt={`${Branding.appName} Icon`} 
      width={size} 
      height={size}
      className={`object-contain ${className}`}
    />
  );
}
import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
import { Providers } from '@/components/layout/Providers';
import { Branding } from '@/config/branding';

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
  display: 'swap',
});

export const metadata: Metadata = {
  title: {
    default: Branding.meta.title,
    template: `%s | ${Branding.appName}`,
  },
  description: Branding.meta.description,
  keywords: ['poultry', 'farm management', 'AI', 'disease detection', 'flock monitoring', 'PoultryGuardLite'],
  authors: [{ name: Branding.companyName }],
  openGraph: {
    title: Branding.meta.title,
    description: Branding.meta.description,
    type: 'website',
  },
  icons: {
    icon: [
      { url: Branding.favicons.icon192, sizes: '192x192', type: 'image/png' },
      { url: Branding.favicons.icon512, sizes: '512x512', type: 'image/png' },
    ],
    apple: [
      { url: Branding.favicons.apple, sizes: '180x180', type: 'image/png' },
    ],
  },
  manifest: '/manifest.json',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={inter.variable} suppressHydrationWarning>
      <body className="min-h-screen bg-background text-foreground antialiased">
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}

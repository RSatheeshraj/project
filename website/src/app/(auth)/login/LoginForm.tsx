'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { motion } from 'framer-motion';
import { Eye, EyeOff, Mail, Lock, AlertCircle } from 'lucide-react';
import { useAuth, AuthError } from '@/contexts/AuthContext';
import { BrandLogo } from '@/components/branding/BrandLogo';
import { Branding } from '@/config/branding';

// ── Validation schema (mirrors Flutter's form validation) ─────────────────

const loginSchema = z.object({
  email: z
    .string()
    .min(1, 'Email is required')
    .email('Please enter a valid email address.'),
  password: z.string().min(1, 'Password is required'),
});

type LoginFormValues = z.infer<typeof loginSchema>;

// ── Component ─────────────────────────────────────────────────────────────────

export function LoginForm() {
  const { signIn } = useAuth();
  const router = useRouter();
  const [showPassword, setShowPassword] = useState(false);
  const [authError, setAuthError] = useState<string | null>(null);

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginFormValues>({
    resolver: zodResolver(loginSchema),
  });

  async function onSubmit(values: LoginFormValues) {
    setAuthError(null);
    try {
      await signIn(values.email, values.password);
      router.replace('/home');
    } catch (err) {
      if (err instanceof AuthError) {
        setAuthError(err.message);
      } else {
        setAuthError('Something went wrong. Please try again.');
      }
    }
  }

  return (
    <div className="min-h-screen flex">
      {/* ── Left panel: branding ──────────────────────────────────────── */}
      <motion.div
        className="hidden lg:flex flex-col justify-between p-12 w-[45%] relative overflow-hidden"
        style={{
          background:
            'linear-gradient(135deg, #1A1200 0%, #121212 40%, #0D1A0E 100%)',
        }}
        initial={{ opacity: 0, x: -40 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ duration: 0.6 }}
      >
        {/* Amber radial glow */}
        <div
          className="absolute top-0 left-0 w-96 h-96 rounded-full pointer-events-none"
          style={{
            background: 'radial-gradient(circle, rgba(244,169,0,0.15) 0%, transparent 70%)',
          }}
        />
        <div
          className="absolute bottom-0 right-0 w-72 h-72 rounded-full pointer-events-none"
          style={{
            background: 'radial-gradient(circle, rgba(46,125,50,0.12) 0%, transparent 70%)',
          }}
        />

        {/* Logo + brand */}
        <div className="relative z-10 mb-8">
          <BrandLogo variant="horizontal" size="xl" className="mb-4" />
          <h2 className="text-xl text-muted-foreground font-medium">{Branding.tagline}</h2>
        </div>

        {/* Feature highlights */}
        <div className="relative z-10 space-y-5">
          {[
            { icon: '🏚️', title: 'Farm Management', desc: 'Manage multiple farms and flocks in one place' },
            { icon: '🤖', title: 'AI Disease Detection', desc: 'Gemini Vision identifies diseases from photos' },
            { icon: '📊', title: 'Health Analytics', desc: 'Weekly entries track mortality, weight & more' },
          ].map((f) => (
            <div key={f.title} className="flex items-start gap-4">
              <div
                className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0 text-lg"
                style={{
                  background: 'rgba(244,169,0,0.12)',
                  border: '1px solid rgba(244,169,0,0.2)',
                }}
              >
                {f.icon}
              </div>
              <div>
                <p className="text-sm font-semibold text-foreground">{f.title}</p>
                <p className="text-xs text-muted-foreground mt-0.5">{f.desc}</p>
              </div>
            </div>
          ))}
        </div>

        <p className="relative z-10 text-xs text-muted-foreground">
          {Branding.copyright}
        </p>
      </motion.div>

      {/* ── Right panel: form ─────────────────────────────────────────── */}
      <motion.div
        className="flex-1 flex items-center justify-center p-6 lg:p-12 bg-background"
        initial={{ opacity: 0, x: 40 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ duration: 0.6 }}
      >
        <div className="w-full max-w-md">
          {/* Mobile logo */}
          <div className="flex items-center gap-3 mb-10 lg:hidden">
            <BrandLogo variant="horizontal" size="lg" />
          </div>

          <h2 className="text-2xl font-bold text-foreground mb-2">Welcome back</h2>
          <p className="text-muted-foreground text-sm mb-8">
            Sign in to your account to continue.
          </p>

          <form onSubmit={handleSubmit(onSubmit)} className="space-y-5" noValidate>
            {/* Auth error banner */}
            {authError && (
              <motion.div
                className="flex items-start gap-3 rounded-lg px-4 py-3 text-sm"
                style={{
                  background: 'rgba(183,28,28,0.12)',
                  border: '1px solid rgba(183,28,28,0.3)',
                  color: '#ef9a9a',
                }}
                initial={{ opacity: 0, y: -8 }}
                animate={{ opacity: 1, y: 0 }}
              >
                <AlertCircle className="w-4 h-4 mt-0.5 shrink-0" style={{ color: '#B71C1C' }} />
                <span>{authError}</span>
              </motion.div>
            )}

            {/* Email */}
            <div className="space-y-1.5">
              <label className="text-sm font-medium text-foreground" htmlFor="login-email">
                Email address
              </label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none" />
                <input
                  id="login-email"
                  type="email"
                  autoComplete="email"
                  placeholder="you@example.com"
                  className="w-full rounded-xl pl-10 pr-4 py-3 text-sm text-foreground placeholder:text-muted-foreground transition-all outline-none focus:ring-2"
                  style={{
                    background: 'rgba(42,42,42,0.8)',
                    border: errors.email
                      ? '1px solid rgba(183,28,28,0.7)'
                      : '1px solid rgba(74,59,16,0.7)',
                    '--tw-ring-color': '#F4A900',
                  } as React.CSSProperties}
                  {...register('email')}
                />
              </div>
              {errors.email && (
                <p className="text-xs text-red-400">{errors.email.message}</p>
              )}
            </div>

            {/* Password */}
            <div className="space-y-1.5">
              <label className="text-sm font-medium text-foreground" htmlFor="login-password">
                Password
              </label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none" />
                <input
                  id="login-password"
                  type={showPassword ? 'text' : 'password'}
                  autoComplete="current-password"
                  placeholder="••••••••"
                  className="w-full rounded-xl pl-10 pr-12 py-3 text-sm text-foreground placeholder:text-muted-foreground transition-all outline-none focus:ring-2"
                  style={{
                    background: 'rgba(42,42,42,0.8)',
                    border: errors.password
                      ? '1px solid rgba(183,28,28,0.7)'
                      : '1px solid rgba(74,59,16,0.7)',
                    '--tw-ring-color': '#F4A900',
                  } as React.CSSProperties}
                  {...register('password')}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((p) => !p)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors"
                  aria-label={showPassword ? 'Hide password' : 'Show password'}
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
              {errors.password && (
                <p className="text-xs text-red-400">{errors.password.message}</p>
              )}
            </div>

            {/* Submit */}
            <motion.button
              type="submit"
              disabled={isSubmitting}
              className="w-full py-3 rounded-xl text-sm font-semibold transition-all relative overflow-hidden disabled:opacity-60 disabled:cursor-not-allowed"
              style={{
                background: isSubmitting
                  ? 'rgba(244,169,0,0.6)'
                  : 'linear-gradient(135deg, #F4A900 0%, #d4920a 100%)',
                color: '#1A1200',
                boxShadow: isSubmitting ? 'none' : '0 4px 20px rgba(244,169,0,0.35)',
              }}
              whileHover={{ scale: isSubmitting ? 1 : 1.01 }}
              whileTap={{ scale: isSubmitting ? 1 : 0.99 }}
            >
              {isSubmitting ? (
                <span className="flex items-center justify-center gap-2">
                  <span className="w-4 h-4 rounded-full border-2 border-amber-900/40 border-t-amber-900 animate-spin" />
                  Signing in…
                </span>
              ) : (
                'Sign in'
              )}
            </motion.button>
          </form>

          <p className="mt-6 text-center text-sm text-muted-foreground">
            Don&apos;t have an account?{' '}
            <Link
              href="/register"
              className="font-semibold transition-colors hover:underline"
              style={{ color: '#F4A900' }}
            >
              Create one
            </Link>
          </p>
        </div>
      </motion.div>
    </div>
  );
}

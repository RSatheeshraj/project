'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { motion, AnimatePresence } from 'framer-motion';
import { Eye, EyeOff, Mail, Lock, User, AlertCircle, CheckCircle } from 'lucide-react';
import { useAuth, AuthError } from '@/contexts/AuthContext';

// ── Validation schemas ─────────────────────────────────────────────────────────

const step1Schema = z
  .object({
    name: z.string().min(2, 'Name must be at least 2 characters.').max(50),
    email: z.string().min(1, 'Email is required').email('Please enter a valid email address.'),
    password: z
      .string()
      .min(8, 'Password must be at least 8 characters.')
      .max(100),
    confirmPassword: z.string().min(1, 'Please confirm your password.'),
  })
  .refine((d) => d.password === d.confirmPassword, {
    message: 'Passwords do not match.',
    path: ['confirmPassword'],
  });

type RegisterFormValues = z.infer<typeof step1Schema>;

// ── Component ─────────────────────────────────────────────────────────────────

export function RegisterForm() {
  const { register: authRegister } = useAuth();
  const router = useRouter();
  
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  
  const [authError, setAuthError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<RegisterFormValues>({
    resolver: zodResolver(step1Schema),
    mode: 'onTouched',
  });

  const onSubmit = async (values: RegisterFormValues) => {
    setAuthError(null);
    setIsSubmitting(true);
    try {
      await authRegister({
        name: values.name,
        email: values.email,
        password: values.password,
        // Fulfilling backwards compatibility for AuthContext/AuthRepository
        ownerName: '',
        companyName: '',
        phoneNumber: '',
        address: '',
        city: '',
        state: '',
        country: '',
        pincode: '',
        whatsappNumber: '',
        companyEmail: '',
        gstNumber: '',
        farmRegistrationNumber: '',
        websiteUrl: '',
        companyDescription: '',
        preferredCurrency: 'INR',
        preferredWeightUnit: 'Kg',
        defaultFarmName: '',
        defaultFarmType: 'Broiler',
        profilePhotoFile: undefined,
        logoFile: undefined
      });
      
      setSuccess(true);
      setTimeout(() => router.replace('/dashboard'), 1500);
    } catch (err) {
      if (err instanceof AuthError) {
        setAuthError(err.message);
      } else {
        setAuthError('Something went wrong. Please try again.');
        console.error(err);
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-6 bg-background pt-12 pb-12">
      <div className="w-full max-w-lg">
        <motion.div
          className="flex items-center gap-3 mb-8 justify-center"
          initial={{ opacity: 0, y: -16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4 }}
        >
          <div
            className="w-10 h-10 rounded-xl flex items-center justify-center"
            style={{
              background: 'linear-gradient(135deg, rgba(244,169,0,0.25), rgba(46,125,50,0.2))',
              border: '1px solid rgba(244,169,0,0.4)',
            }}
          >
            <span className="text-xl">🐔</span>
          </div>
          <span className="text-lg font-bold" style={{ color: '#F4A900' }}>
            PoultryGuard Lite
          </span>
        </motion.div>

        <motion.div
          className="bg-card p-8 rounded-2xl border border-border shadow-sm"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.1 }}
        >
          <h2 className="text-2xl font-bold text-foreground mb-6">
            Create an Account
          </h2>

          {/* Success state */}
          {success && (
            <motion.div
              className="flex items-center gap-3 rounded-lg px-4 py-3 text-sm mb-5"
              style={{
                background: 'rgba(46,125,50,0.12)',
                border: '1px solid rgba(46,125,50,0.35)',
                color: '#81c784',
              }}
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
            >
              <CheckCircle className="w-4 h-4 shrink-0" style={{ color: '#2E7D32' }} />
              <span>Account created! Redirecting to dashboard…</span>
            </motion.div>
          )}

          <form onSubmit={handleSubmit(onSubmit)} className="space-y-5" noValidate>
            {/* Auth error */}
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

            <AnimatePresence mode="wait">
              <motion.div
                key="step1"
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
                transition={{ duration: 0.3 }}
                className="space-y-5"
              >
                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-foreground">Full name *</label>
                  <div className="relative">
                    <User className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none" />
                    <input
                      type="text"
                      placeholder="Your full name"
                      className="w-full rounded-xl pl-10 pr-4 py-3 text-sm text-foreground placeholder:text-muted-foreground transition-all outline-none focus:ring-2 bg-background/50 border-border"
                      style={{ border: errors.name ? '1px solid rgba(183,28,28,0.7)' : '1px solid rgba(74,59,16,0.7)', '--tw-ring-color': '#F4A900' } as React.CSSProperties}
                      {...register('name')}
                    />
                  </div>
                  {errors.name && <p className="text-xs text-red-400">{errors.name.message}</p>}
                </div>

                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-foreground">Email address *</label>
                  <div className="relative">
                    <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none" />
                    <input
                      type="email"
                      placeholder="you@example.com"
                      className="w-full rounded-xl pl-10 pr-4 py-3 text-sm text-foreground placeholder:text-muted-foreground transition-all outline-none focus:ring-2 bg-background/50 border-border"
                      style={{ border: errors.email ? '1px solid rgba(183,28,28,0.7)' : '1px solid rgba(74,59,16,0.7)', '--tw-ring-color': '#F4A900' } as React.CSSProperties}
                      {...register('email')}
                    />
                  </div>
                  {errors.email && <p className="text-xs text-red-400">{errors.email.message}</p>}
                </div>

                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-foreground">Password *</label>
                  <div className="relative">
                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none" />
                    <input
                      type={showPassword ? 'text' : 'password'}
                      placeholder="Min. 8 characters"
                      className="w-full rounded-xl pl-10 pr-12 py-3 text-sm text-foreground placeholder:text-muted-foreground transition-all outline-none focus:ring-2 bg-background/50 border-border"
                      style={{ border: errors.password ? '1px solid rgba(183,28,28,0.7)' : '1px solid rgba(74,59,16,0.7)', '--tw-ring-color': '#F4A900' } as React.CSSProperties}
                      {...register('password')}
                    />
                    <button type="button" onClick={() => setShowPassword(!showPassword)} className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors">
                      {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  </div>
                  {errors.password && <p className="text-xs text-red-400">{errors.password.message}</p>}
                </div>

                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-foreground">Confirm password *</label>
                  <div className="relative">
                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none" />
                    <input
                      type={showConfirm ? 'text' : 'password'}
                      placeholder="Repeat your password"
                      className="w-full rounded-xl pl-10 pr-12 py-3 text-sm text-foreground placeholder:text-muted-foreground transition-all outline-none focus:ring-2 bg-background/50 border-border"
                      style={{ border: errors.confirmPassword ? '1px solid rgba(183,28,28,0.7)' : '1px solid rgba(74,59,16,0.7)', '--tw-ring-color': '#F4A900' } as React.CSSProperties}
                      {...register('confirmPassword')}
                    />
                    <button type="button" onClick={() => setShowConfirm(!showConfirm)} className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors">
                      {showConfirm ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  </div>
                  {errors.confirmPassword && <p className="text-xs text-red-400">{errors.confirmPassword.message}</p>}
                </div>

                <motion.button 
                  type="submit" 
                  disabled={isSubmitting || success} 
                  className="w-full py-3 rounded-xl text-sm font-semibold transition-all mt-4 disabled:opacity-60 disabled:cursor-not-allowed flex items-center justify-center gap-2" 
                  style={{ background: 'linear-gradient(135deg, #F4A900 0%, #d4920a 100%)', color: '#1A1200', boxShadow: '0 4px 20px rgba(244,169,0,0.35)' }}
                >
                  {isSubmitting ? (
                    <>
                      <span className="w-4 h-4 rounded-full border-2 border-amber-900/40 border-t-amber-900 animate-spin" />
                      Creating account…
                    </>
                  ) : (
                    'Create Account'
                  )}
                </motion.button>
              </motion.div>
            </AnimatePresence>
          </form>

          <p className="mt-8 text-center text-sm text-muted-foreground">
            Already have an account?{' '}
            <Link href="/login" className="font-semibold transition-colors hover:underline" style={{ color: '#F4A900' }}>
              Sign in
            </Link>
          </p>
        </motion.div>
      </div>
    </div>
  );
}

'use client';

import { motion } from 'framer-motion';
import { BrandIcon } from '@/components/branding/BrandIcon';
import { BrandWordmark } from '@/components/branding/BrandWordmark';

export function LoadingScreen() {
  return (
    <div className="fixed inset-0 flex flex-col items-center justify-center bg-background z-50">
      {/* Animated amber logo mark */}
      <motion.div
        className="relative"
        initial={{ opacity: 0, scale: 0.8 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.4, ease: 'easeOut' }}
      >
        {/* Outer glow ring */}
        <motion.div
          className="absolute inset-0 rounded-full"
          style={{
            background:
              'radial-gradient(circle, rgba(244,169,0,0.3) 0%, transparent 70%)',
          }}
          animate={{ scale: [1, 1.3, 1] }}
          transition={{ duration: 2, repeat: Infinity, ease: 'easeInOut' }}
        />

        {/* Icon container */}
        <div
          className="relative w-20 h-20 rounded-2xl flex items-center justify-center glow-primary"
          style={{
            background: 'linear-gradient(135deg, rgba(244,169,0,0.1), rgba(46,125,50,0.1))',
            border: '1px solid rgba(244,169,0,0.2)',
          }}
        >
          <BrandIcon size={64} />
        </div>
      </motion.div>

      {/* Brand name */}
      <motion.div
        className="mt-6 text-center"
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2, duration: 0.4 }}
      >
        <BrandWordmark showTagline className="items-center" />
      </motion.div>

      {/* Loading dots */}
      <motion.div
        className="mt-8 flex gap-2"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.4 }}
      >
        {[0, 1, 2].map((i) => (
          <motion.div
            key={i}
            className="w-2 h-2 rounded-full"
            style={{ backgroundColor: '#F4A900' }}
            animate={{ scale: [1, 1.4, 1], opacity: [0.5, 1, 0.5] }}
            transition={{
              duration: 1.2,
              repeat: Infinity,
              delay: i * 0.2,
              ease: 'easeInOut',
            }}
          />
        ))}
      </motion.div>
    </div>
  );
}

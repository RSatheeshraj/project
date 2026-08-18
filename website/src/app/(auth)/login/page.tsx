import type { Metadata } from 'next';
import { LoginForm } from './LoginForm';

export const metadata: Metadata = {
  title: 'Sign In',
  description: 'Sign in to your PoultryGuard Lite account.',
};

export default function LoginPage() {
  return <LoginForm />;
}

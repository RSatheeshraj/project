'use client';

import { useState } from 'react';

import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { useToast } from '@/components/ui/Toast';
import { Bell, Lock, Palette, Cpu, ShieldAlert, Info } from 'lucide-react';
import { updatePassword, EmailAuthProvider, reauthenticateWithCredential } from 'firebase/auth';
import auth from '@/lib/firebase/auth';

export function SettingsClient() {
  const { toast } = useToast();
  
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [isUpdatingPassword, setIsUpdatingPassword] = useState(false);

  const handleUpdatePassword = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!auth.currentUser || !auth.currentUser.email || !newPassword || !currentPassword) return;
    
    if (newPassword !== confirmPassword) {
      toast('New passwords do not match', 'error');
      return;
    }

    if (newPassword.length < 6) {
      toast('Password must be at least 6 characters', 'error');
      return;
    }

    setIsUpdatingPassword(true);
    try {
      // Reauthenticate first
      const credential = EmailAuthProvider.credential(auth.currentUser.email, currentPassword);
      await reauthenticateWithCredential(auth.currentUser, credential);

      await updatePassword(auth.currentUser, newPassword);
      toast('Password updated successfully', 'success');
      setCurrentPassword('');
      setNewPassword('');
      setConfirmPassword('');
    } catch (error) {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const err = error as any;
      if (err.code === 'auth/wrong-password' || err.code === 'auth/invalid-credential') {
        toast('Incorrect current password.', 'error');
      } else if (err.code === 'auth/too-many-requests') {
        toast('Too many attempts. Please try again later.', 'error');
      } else {
        toast(err.message || 'Failed to update password', 'error');
      }
    } finally {
      setIsUpdatingPassword(false);
    }
  };

  return (
    <div className="space-y-6 max-w-3xl mx-auto">
      <div>
        <h2 className="text-2xl font-bold text-foreground">Settings</h2>
        <p className="text-muted-foreground text-sm mt-1">
          Manage application preferences and security.
        </p>
      </div>

      {/* Security Settings (Supported) */}
      <div className="rounded-2xl p-6 glass border border-border/50">
        <div className="flex items-center gap-2 mb-6">
          <Lock className="w-5 h-5 text-primary" />
          <h3 className="font-semibold text-lg text-foreground">Security</h3>
        </div>
        
        <form onSubmit={handleUpdatePassword} className="space-y-4 max-w-md">
          <div className="space-y-2">
            <label className="text-sm font-medium text-foreground">Current Password</label>
            <Input
              type="password"
              value={currentPassword}
              onChange={(e) => setCurrentPassword(e.target.value)}
              placeholder="••••••••"
              required
            />
          </div>
          <div className="space-y-2">
            <label className="text-sm font-medium text-foreground">New Password</label>
            <Input
              type="password"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              placeholder="••••••••"
              required
            />
            <p className="text-xs text-muted-foreground">Must be at least 6 characters long.</p>
          </div>
          <div className="space-y-2">
            <label className="text-sm font-medium text-foreground">Confirm New Password</label>
            <Input
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              placeholder="••••••••"
              required
            />
          </div>
          <Button type="submit" loading={isUpdatingPassword} disabled={!newPassword || !currentPassword || !confirmPassword}>
            Update Password
          </Button>
        </form>
      </div>

      {/* Appearance Settings (Disabled in UI as per requirements for v1.0 standard dark theme) */}
      <div className="rounded-2xl p-6 glass border border-border/50 opacity-80">
        <div className="flex items-center gap-2 mb-4">
          <Palette className="w-5 h-5 text-foreground" />
          <h3 className="font-semibold text-lg text-foreground">Appearance</h3>
        </div>
        <div className="flex items-center justify-between p-4 bg-background/50 rounded-xl border border-border/50">
          <div>
            <p className="font-medium text-foreground">Theme Preference</p>
            <p className="text-sm text-muted-foreground">Premium Dark Theme is the default for PoultryGuardLite v1.0.</p>
          </div>
          <div className="px-3 py-1 bg-primary/20 text-primary rounded-md text-xs font-semibold">
            Dark Mode Only
          </div>
        </div>
      </div>

      {/* Preferences (Unsupported backend features) */}
      <div className="rounded-2xl p-6 glass border border-border/50 opacity-80">
        <div className="flex items-center gap-2 mb-4">
          <Info className="w-4 h-4 text-amber-400" />
          <h3 className="font-semibold text-lg text-foreground">Preferences</h3>
        </div>
        <p className="text-sm text-muted-foreground mb-6">
          These settings require additional backend configuration and are disabled in this release.
        </p>

        <div className="space-y-4 pointer-events-none">
          <div className="flex items-center justify-between p-4 bg-background/50 rounded-xl border border-border/50 opacity-50">
            <div className="flex items-center gap-3">
              <Bell className="w-5 h-5 text-muted-foreground" />
              <div>
                <p className="font-medium text-foreground">Push Notifications</p>
                <p className="text-sm text-muted-foreground">Receive alerts for high mortality or critical AI scans.</p>
              </div>
            </div>
            <div className="w-12 h-6 rounded-full bg-muted"></div>
          </div>

          <div className="flex items-center justify-between p-4 bg-background/50 rounded-xl border border-border/50 opacity-50">
            <div className="flex items-center gap-3">
              <Cpu className="w-5 h-5 text-muted-foreground" />
              <div>
                <p className="font-medium text-foreground">AI Auto-Scan</p>
                <p className="text-sm text-muted-foreground">Automatically scan images uploaded in weekly entries.</p>
              </div>
            </div>
            <div className="w-12 h-6 rounded-full bg-muted"></div>
          </div>
        </div>
      </div>

      {/* Danger Zone */}
      <div className="rounded-2xl p-6 border border-red-500/20 bg-red-500/5 opacity-80">
        <div className="flex items-center gap-2 mb-4">
          <ShieldAlert className="w-5 h-5 text-red-400" />
          <h3 className="font-semibold text-lg text-red-400">Account Deletion</h3>
        </div>
        <p className="text-sm text-muted-foreground mb-4">
          Deleting your account is permanent. This feature is restricted in v1.0 to prevent accidental data loss. Contact support to request deletion.
        </p>
        <Button variant="outline" className="text-red-400 border-red-500/20 opacity-50 cursor-not-allowed">
          Delete Account
        </Button>
      </div>

    </div>
  );
}
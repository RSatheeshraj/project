/* eslint-disable react-hooks/set-state-in-effect */
'use client';

import { useAuth } from '@/contexts/AuthContext';

import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { useToast } from '@/components/ui/Toast';
import { useState, useEffect, useCallback } from 'react';
import { User, Loader2, LogOut, Mail, Phone } from 'lucide-react';
import { useRouter } from 'next/navigation';

export function ProfileClient() {
  const { user, userProfile, updateProfileData, signOut } = useAuth();
  const router = useRouter();
  const { toast } = useToast();
  
  
  const [isSigningOut, setIsSigningOut] = useState(false);
  const [saveProgress, setSaveProgress] = useState<string | null>(null);
  const isSaving = saveProgress !== null;
  const [isEditing, setIsEditing] = useState(false);
  
  // Personal Info
  const [displayName, setDisplayName] = useState('');
  const [whatsappNumber, setWhatsappNumber] = useState('');

  const resetForm = useCallback(() => {
    if (userProfile) {
      setDisplayName(userProfile.displayName || user?.displayName || '');
      setWhatsappNumber(userProfile.whatsappNumber || '');
    }
    setIsEditing(false);
  }, [userProfile, user]);

  // Initialize from userProfile
  useEffect(() => {
    if (!isEditing) {
      resetForm();
    }
  }, [isEditing, resetForm]);

  const handleCancel = () => {
    resetForm();
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user?.uid) return;
    
    setSaveProgress('Saving Profile...');
    try {
      await updateProfileData(
        {
          displayName,
          whatsappNumber,
        },
        undefined,
        false,
        undefined,
        false,
        (progress) => {
          if (typeof progress === 'number') {
            setSaveProgress(`Saving... ${progress}%`);
          } else {
            setSaveProgress(progress);
          }
        }
      );
      
      toast('✅ Profile Updated Successfully', 'success');
      
      setIsEditing(false);

    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to save profile information';
      toast(errorMessage, 'error');
      console.error(err);
    } finally {
      setSaveProgress(null);
    }
  };


  const inputClassName = (baseClass = "") => {
    if (!isEditing) {
      return `${baseClass} bg-background/30 border-border/20 cursor-default focus:ring-0 opacity-90`;
    }
    return baseClass;
  };



  const handleSignOut = async () => {
    setIsSigningOut(true);
    try {
      await signOut();
      router.push('/login');
    } catch {
      toast('Failed to sign out', 'error');
      setIsSigningOut(false);
    }
  };

  return (
    <div className="space-y-6 max-w-4xl mx-auto pb-12">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-2xl font-bold text-foreground">Profile Settings</h2>
          <p className="text-muted-foreground text-sm mt-1">
            Manage your account and company details.
          </p>
        </div>
        <div className="flex items-center gap-3 w-full sm:w-auto mt-4 sm:mt-0">
          {!isEditing ? (
            <Button type="button" onClick={() => setIsEditing(true)} className="w-full sm:w-auto px-6" style={{ background: 'linear-gradient(135deg, #F4A900 0%, #d4920a 100%)', color: '#1A1200' }}>
              Edit Profile
            </Button>
          ) : (
            <>
              <Button type="button" variant="outline" onClick={handleCancel} className="w-full sm:w-auto px-6" disabled={isSaving}>
                Cancel
              </Button>
              <Button type="submit" onClick={handleSave} loading={isSaving} className="w-full sm:w-auto px-8" style={{ background: 'linear-gradient(135deg, #F4A900 0%, #d4920a 100%)', color: '#1A1200' }}>
                {saveProgress || 'Save Changes'}
              </Button>
            </>
          )}
        </div>
      </div>

      <form onSubmit={handleSave} className="space-y-6">
        {/* PERSONAL INFO */}
        <div className="rounded-2xl p-6 glass border border-border/50">
          <div className="flex items-center gap-2 mb-6 pb-2 border-b border-border/30">
            <User className="w-5 h-5 text-primary" />
            <h3 className="font-semibold text-foreground text-lg">Personal Information</h3>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div className="space-y-2">
              <label className="text-sm font-medium text-foreground">Display Name *</label>
              <div className="relative">
                <User className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none" />
                <Input value={displayName} onChange={(e) => setDisplayName(e.target.value)} placeholder="Your full name" readOnly={!isEditing} className={inputClassName("pl-10")} required />
              </div>
            </div>
            
            <div className="space-y-2">
              <label className="text-sm font-medium text-foreground">Email Address</label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none" />
                <Input value={user?.email || ''} disabled className="pl-10 opacity-70 cursor-not-allowed" />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium text-foreground">Firebase UID</label>
              <div className="relative">
                <Input value={user?.uid || ''} disabled className="opacity-70 cursor-not-allowed font-mono text-xs" />
              </div>
            </div>
            
            <div className="space-y-2">
              <label className="text-sm font-medium text-foreground">Registration Date</label>
              <div className="relative">
                <Input value={userProfile?.createdAt ? new Date(userProfile.createdAt).toLocaleDateString() : ''} disabled className="opacity-70 cursor-not-allowed" />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-sm font-medium text-foreground">Last Updated</label>
              <div className="relative">
                <Input value={userProfile?.updatedAt ? new Date(userProfile.updatedAt).toLocaleDateString() : ''} disabled className="opacity-70 cursor-not-allowed" />
              </div>
            </div>
            
            <div className="space-y-2">
              <label className="text-sm font-medium text-foreground">WhatsApp Number</label>
              <div className="relative">
                <Phone className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none" />
                <Input value={whatsappNumber} onChange={(e) => setWhatsappNumber(e.target.value)} placeholder="1234567890" readOnly={!isEditing} className={inputClassName("pl-10")} />
              </div>
            </div>
          </div>
        </div>
      </form>

      <div className="rounded-2xl p-6 border border-red-500/20 bg-red-500/5 mt-8">
        <h3 className="font-semibold text-red-400 mb-2">Danger Zone</h3>
        <p className="text-sm text-muted-foreground mb-4">
          Log out of your account on this device.
        </p>
        <Button 
          variant="outline" 
          className="text-red-400 border-red-500/20 hover:bg-red-500/10"
          onClick={handleSignOut}
          disabled={isSigningOut}
        >
          {isSigningOut ? <Loader2 className="w-4 h-4 mr-2 animate-spin" /> : <LogOut className="w-4 h-4 mr-2" />}
          Sign Out
        </Button>
      </div>
    </div>
  );
}

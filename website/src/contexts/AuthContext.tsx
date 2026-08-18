/**
 * AuthContext — global authentication state provider.
 *
 * Subscribes to Firebase auth state changes and exposes the current user
 * and their Firestore profile to the entire component tree via React Context.
 */

'use client';

import {
  createContext,
  useContext,
  useEffect,
  useState,
  useCallback,
  type ReactNode,
} from 'react';
import { onAuthStateChanged, type User } from 'firebase/auth';
import { doc, getDoc, onSnapshot } from 'firebase/firestore';
import auth from '@/lib/firebase/auth';
import db from '@/lib/firebase/firestore';
import { AuthRepository, AuthError } from '@/repositories/auth.repository';
import type { AppUser, UserProfile } from '@/types/models';

interface AuthContextValue {
  user: AppUser | null;
  userProfile: UserProfile | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  register: (params: {
    name: string;
    email: string;
    password: string;
    ownerName: string;
    companyName: string;
    phoneNumber: string;
    address: string;
    city: string;
    state: string;
    country: string;
    pincode: string;
    whatsappNumber?: string;
    companyEmail?: string;
    gstNumber?: string;
    farmRegistrationNumber?: string;
    websiteUrl?: string;
    companyDescription?: string;
    preferredCurrency?: string;
    preferredWeightUnit?: string;
    defaultFarmName?: string;
    defaultFarmType?: string;
    profilePhotoFile?: Blob | File;
    logoFile?: Blob | File;
  }) => Promise<void>;
  updateProfileData: (
    updates: Partial<UserProfile>,
    newLogo?: Blob | File,
    removeLogo?: boolean,
    newProfilePhoto?: Blob | File,
    removeProfilePhoto?: boolean,
    onProgress?: (progress: number | string) => void
  ) => Promise<void>;
  refreshProfile: () => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

function toAppUser(user: User): AppUser {
  return {
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    photoURL: user.photoURL,
  };
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AppUser | null>(null);
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);

  // Load profile manually
  const refreshProfile = useCallback(async () => {
    if (!auth.currentUser) return;
    const docRef = doc(db, 'users', auth.currentUser.uid);
    const snap = await getDoc(docRef);
    if (snap.exists()) {
      setUserProfile(snap.data() as UserProfile);
    } else {
      setUserProfile(null);
    }
  }, []);

  useEffect(() => {
    let unsubscribeProfile: () => void = () => {};

    const unsubscribeAuth = onAuthStateChanged(auth, async (firebaseUser) => {
      if (firebaseUser) {
        setUser(toAppUser(firebaseUser));
        
        // Listen to Firestore profile updates in real-time
        unsubscribeProfile = onSnapshot(doc(db, 'users', firebaseUser.uid), (docSnap) => {
          if (docSnap.exists()) {
            setUserProfile(docSnap.data() as UserProfile);
          } else {
            setUserProfile(null);
          }
          setLoading(false);
        });
      } else {
        setUser(null);
        setUserProfile(null);
        setLoading(false);
        unsubscribeProfile();
      }
    });

    return () => {
      unsubscribeAuth();
      unsubscribeProfile();
    };
  }, []);

  const signIn = useCallback(async (email: string, password: string) => {
    await AuthRepository.signInWithEmail({ email, password });
  }, []);

  const register = useCallback(
    async (params: Parameters<AuthContextValue['register']>[0]) => {
      await AuthRepository.registerWithEmail(params);
    },
    []
  );

  const updateProfileData = useCallback(async (
    updates: Partial<UserProfile>,
    newLogo?: Blob | File,
    removeLogo?: boolean,
    newProfilePhoto?: Blob | File,
    removeProfilePhoto?: boolean,
    onProgress?: (progress: number | string) => void
  ) => {
    if (!user || !userProfile) throw new Error('Not authenticated');
    await AuthRepository.updateUserProfile(user.uid, userProfile, updates, newLogo, removeLogo, newProfilePhoto, removeProfilePhoto, onProgress);
    // Profile will auto-update via onSnapshot listener
  }, [user, userProfile]);

  const signOut = useCallback(async () => {
    await AuthRepository.signOut();
  }, []);

  return (
    <AuthContext.Provider value={{ user, userProfile, loading, signIn, register, updateProfileData, refreshProfile, signOut }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error('useAuth must be used within an <AuthProvider>.');
  }
  return ctx;
}

export { AuthError };

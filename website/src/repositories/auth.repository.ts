/**
 * AuthRepository — web equivalent of Flutter's AuthRepository.
 *
 * Wraps Firebase Auth with typed, user-friendly error messages.
 * Error codes mirror Flutter's _mapError() switch exactly.
 */

import {
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut as firebaseSignOut,
  updateProfile,
  type User,
} from 'firebase/auth';
import { doc, setDoc, updateDoc } from 'firebase/firestore';
import { ref, uploadBytes, getDownloadURL, deleteObject, uploadBytesResumable } from 'firebase/storage';
import auth from '@/lib/firebase/auth';
import db from '@/lib/firebase/firestore';
import storage from '@/lib/firebase/storage';
import type { UserProfile } from '@/types/models';

// ── Error mapping ─────────────────────────────────────────────────────────────

function mapAuthError(code: string, fallback?: string): string {
  switch (code) {
    case 'auth/user-not-found':
    case 'auth/wrong-password':
    case 'auth/invalid-credential':
      return 'Incorrect email or password.';
    case 'auth/email-already-in-use':
      return 'An account with this email already exists.';
    case 'auth/weak-password':
      return 'Password must be at least 6 characters.';
    case 'auth/invalid-email':
      return 'Please enter a valid email address.';
    case 'auth/user-disabled':
      return 'This account has been disabled.';
    case 'auth/too-many-requests':
      return 'Too many attempts. Please try again later.';
    default:
      return fallback ?? 'Authentication failed.';
  }
}

export class AuthError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'AuthError';
  }
}

// ── Repository ────────────────────────────────────────────────────────────────

export const AuthRepository = {
  /** The currently signed-in user, or null. */
  get currentUser(): User | null {
    return auth.currentUser;
  },

  /**
   * Signs in with email and password.
   * Throws AuthError with a user-friendly message on failure.
   */
  async signInWithEmail({
    email,
    password,
  }: {
    email: string;
    password: string;
  }): Promise<void> {
    try {
      await signInWithEmailAndPassword(auth, email.trim(), password);
    } catch (err: unknown) {
      const code = (err as { code?: string }).code ?? '';
      const msg = (err as { message?: string }).message;
      throw new AuthError(mapAuthError(code, msg));
    }
  },

  /**
   * Creates a new account, sets the display name, uploads logo, and creates Firestore profile.
   * Throws AuthError with a user-friendly message on failure.
   */
  async registerWithEmail(params: {
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
  }): Promise<void> {
    try {
      const credential = await createUserWithEmailAndPassword(
        auth,
        params.email.trim(),
        params.password
      );
      
      const user = credential.user;
      await updateProfile(user, { displayName: params.name.trim() });

      let companyLogoUrl = '';
      let companyLogoPath = '';
      if (params.logoFile) {
        companyLogoPath = `company-logos/${user.uid}/logo_${Date.now()}.jpg`;
        const logoRef = ref(storage, companyLogoPath);
        await uploadBytes(logoRef, params.logoFile);
        companyLogoUrl = await getDownloadURL(logoRef);
      }

      let profilePhotoUrl = '';
      let profilePhotoPath = '';
      if (params.profilePhotoFile) {
        profilePhotoPath = `profile-photos/${user.uid}/photo_${Date.now()}.jpg`;
        const photoRef = ref(storage, profilePhotoPath);
        await uploadBytes(photoRef, params.profilePhotoFile);
        profilePhotoUrl = await getDownloadURL(photoRef);
        await updateProfile(user, { photoURL: profilePhotoUrl });
      }

      const now = new Date().toISOString();
      const userProfile: UserProfile = {
        uid: user.uid,
        displayName: params.name.trim(),
        email: params.email.trim(),
        ownerName: params.ownerName.trim(),
        companyName: params.companyName.trim(),
        phoneNumber: params.phoneNumber.trim(),
        address: params.address.trim(),
        city: params.city.trim(),
        state: params.state.trim(),
        country: params.country.trim(),
        pincode: params.pincode.trim(),
        whatsappNumber: params.whatsappNumber?.trim() || '',
        companyEmail: params.companyEmail?.trim() || '',
        gstNumber: params.gstNumber?.trim() || '',
        farmRegistrationNumber: params.farmRegistrationNumber?.trim() || '',
        websiteUrl: params.websiteUrl?.trim() || '',
        companyDescription: params.companyDescription?.trim() || '',
        preferredCurrency: params.preferredCurrency || 'INR',
        preferredWeightUnit: params.preferredWeightUnit || 'Kg',
        defaultFarmName: params.defaultFarmName?.trim() || '',
        defaultFarmType: params.defaultFarmType?.trim() || '',
        companyLogoUrl,
        companyLogoPath,
        profilePhotoUrl,
        profilePhotoPath,
        createdAt: now,
        updatedAt: now,
      };

      await setDoc(doc(db, 'users', user.uid), userProfile);

    } catch (err: unknown) {
      const code = (err as { code?: string }).code ?? '';
      const msg = (err as { message?: string }).message;
      throw new AuthError(mapAuthError(code, msg));
    }
  },

  /**
   * Updates an existing user profile, optionally replacing the logo.
   */
  async updateUserProfile(
    uid: string,
    currentProfile: UserProfile,
    updates: Partial<UserProfile>,
    newLogoFile?: Blob | File,
    removeLogo?: boolean,
    newProfilePhotoFile?: Blob | File,
    removeProfilePhoto?: boolean,
    onProgress?: (progress: number | string) => void
  ): Promise<void> {
    let { companyLogoUrl, companyLogoPath, profilePhotoUrl, profilePhotoPath } = currentProfile;

    try {
      if (removeLogo || newLogoFile) {
        if (companyLogoPath) {
          try {
            await deleteObject(ref(storage, companyLogoPath));
          } catch (e) {
            console.warn('Failed to delete old logo', e);
          }
        }
        companyLogoUrl = '';
        companyLogoPath = '';
      }

      if (newLogoFile) {
        companyLogoPath = `company-logos/${uid}/logo_${Date.now()}.jpg`;
        const logoRef = ref(storage, companyLogoPath);
        
        onProgress?.(0);
        const uploadTask = uploadBytesResumable(logoRef, newLogoFile);
        
        await new Promise<void>((resolve, reject) => {
          uploadTask.on(
            'state_changed',
            (snapshot) => {
              const progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
              onProgress?.(Math.round(progress));
            },
            (error) => {
              reject(error);
            },
            () => {
              resolve();
            }
          );
        });

        companyLogoUrl = await getDownloadURL(logoRef);
      }

      if (removeProfilePhoto || newProfilePhotoFile) {
        if (profilePhotoPath) {
          try {
            await deleteObject(ref(storage, profilePhotoPath));
          } catch (e) {
            console.warn('Failed to delete old profile photo', e);
          }
        }
        profilePhotoUrl = '';
        profilePhotoPath = '';
      }

      if (newProfilePhotoFile) {
        profilePhotoPath = `profile-photos/${uid}/photo_${Date.now()}.jpg`;
        const photoRef = ref(storage, profilePhotoPath);
        await uploadBytes(photoRef, newProfilePhotoFile);
        profilePhotoUrl = await getDownloadURL(photoRef);
      }

      // Filter out undefined values
      const safeUpdates = Object.entries(updates).reduce((acc, [key, value]) => {
        if (value !== undefined) acc[key] = value;
        return acc;
      }, {} as Record<string, unknown>);

      const updatedData: Record<string, unknown> = {
        ...safeUpdates,
        updatedAt: new Date().toISOString(),
      };

      if (companyLogoUrl !== undefined) updatedData.companyLogoUrl = companyLogoUrl;
      if (companyLogoPath !== undefined) updatedData.companyLogoPath = companyLogoPath;
      if (profilePhotoUrl !== undefined) updatedData.profilePhotoUrl = profilePhotoUrl;
      if (profilePhotoPath !== undefined) updatedData.profilePhotoPath = profilePhotoPath;

      onProgress?.('Saving Profile...');
      await updateDoc(doc(db, 'users', uid), updatedData);
      
      const authUpdates: { displayName?: string; photoURL?: string } = {};
      if (updates.displayName) authUpdates.displayName = updates.displayName;
      if (profilePhotoUrl !== undefined) authUpdates.photoURL = profilePhotoUrl;
      
      if (Object.keys(authUpdates).length > 0 && auth.currentUser) {
         await updateProfile(auth.currentUser, authUpdates);
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : (err as { message?: string })?.message || 'Failed to update profile data or upload logo';
      throw new AuthError(msg);
    }
  },

  /** Signs out the current user. */
  async signOut(): Promise<void> {
    await firebaseSignOut(auth);
  },
};

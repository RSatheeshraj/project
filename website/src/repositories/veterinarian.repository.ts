import {
  addDoc,
  deleteDoc,
  doc,
  getDocs,
  query,
  where,
  serverTimestamp,
  updateDoc
} from 'firebase/firestore';
import db, { veterinariansCol } from '@/lib/firebase/firestore';
import auth from '@/lib/firebase/auth';
import type { Veterinarian, VeterinarianInput } from '@/types/models';
import { RepositoryError } from './farm.repository';

function requireUid(): string {
  const uid = auth.currentUser?.uid;
  if (!uid) throw new RepositoryError('You must be signed in.');
  return uid;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function toVeterinarian(id: string, data: Record<string, any>): Veterinarian {
  return {
    id,
    doctorName: data.doctorName ?? '',
    phoneNumber: data.phoneNumber ?? '',
    whatsappNumber: data.whatsappNumber ?? '',
    email: data.email ?? '',
    address: data.address ?? '',
    isEmergency: data.isEmergency ?? false,
    ownerId: data.ownerId ?? '',
    createdAt: data.createdAt?.toDate(),
    updatedAt: data.updatedAt?.toDate(),
  };
}

export const VeterinarianRepository = {
  async getVeterinarians(): Promise<Veterinarian[]> {
    const uid = requireUid();
    try {
      const q = query(
        veterinariansCol(),
        where('ownerId', '==', uid)
      );
      const snap = await getDocs(q);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const vets = snap.docs.map((d) => toVeterinarian(d.id, d.data() as any));
      
      return vets.sort((a, b) => {
        const timeA = a.createdAt?.getTime() || 0;
        const timeB = b.createdAt?.getTime() || 0;
        return timeB - timeA;
      });
    } catch (error) {
      console.error('Failed to fetch veterinarians:', error);
      return []; 
    }
  },

  async addVeterinarian(input: VeterinarianInput): Promise<void> {
    const uid = requireUid();
    
    await addDoc(veterinariansCol(), {
      ...input,
      ownerId: uid,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
  },

  async updateVeterinarian(id: string, data: Partial<VeterinarianInput>): Promise<void> {
    requireUid();
    const docRef = doc(db, 'veterinarians', id);
    // Ideally we would verify ownerId here but client side checking isn't full security anyway
    
    await updateDoc(docRef, {
      ...data,
      updatedAt: serverTimestamp(),
    });
  },

  async deleteVeterinarian(id: string): Promise<void> {
    requireUid();
    const docRef = doc(db, 'veterinarians', id);
    await deleteDoc(docRef);
  },
};

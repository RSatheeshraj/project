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
import db, { remindersCol } from '@/lib/firebase/firestore';
import auth from '@/lib/firebase/auth';
import type { Reminder, ReminderInput } from '@/types/models';
import { RepositoryError } from './farm.repository';

function requireUid(): string {
  const uid = auth.currentUser?.uid;
  if (!uid) throw new RepositoryError('You must be signed in.');
  return uid;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function toReminder(id: string, data: Record<string, any>): Reminder {
  return {
    id,
    ownerId: data.ownerId ?? '',
    farmId: data.farmId ?? '',
    batchId: data.batchId,
    title: data.title ?? '',
    description: data.description,
    category: data.category ?? 'Custom',
    dueDate: data.dueDate?.toDate() ?? new Date(),
    status: data.status ?? 'Pending',
    notificationEnabled: data.notificationEnabled,
    notifyBeforeDays: data.notifyBeforeDays,
    createdAt: data.createdAt?.toDate(),
    updatedAt: data.updatedAt?.toDate(),
  };
}

export const ReminderRepository = {
  async getReminders(farmId?: string): Promise<Reminder[]> {
    const uid = requireUid();
    try {
      let q = query(
        remindersCol(),
        where('ownerId', '==', uid)
      );

      if (farmId) {
        q = query(q, where('farmId', '==', farmId));
      }

      const snap = await getDocs(q);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const reminders = snap.docs.map((d) => toReminder(d.id, d.data() as any));
      
      return reminders.sort((a, b) => {
        const timeA = a.dueDate.getTime();
        const timeB = b.dueDate.getTime();
        return timeA - timeB;
      });
    } catch (error) {
      console.error('Failed to fetch reminders:', error);
      return []; 
    }
  },

  async addReminder(input: ReminderInput): Promise<void> {
    const uid = requireUid();
    
    // Clean input to remove undefined values
    const cleanedInput = Object.fromEntries(
      Object.entries(input).filter(([, v]) => v !== undefined)
    );

    await addDoc(remindersCol(), {
      ...cleanedInput,
      ownerId: uid,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
  },

  async updateReminder(id: string, data: Partial<ReminderInput>): Promise<void> {
    requireUid();
    const docRef = doc(db, 'reminders', id);
    
    // Clean data to remove undefined values
    const cleanedData = Object.fromEntries(
      Object.entries(data).filter(([, v]) => v !== undefined)
    );

    await updateDoc(docRef, {
      ...cleanedData,
      updatedAt: serverTimestamp(),
    });
  },

  async deleteReminder(id: string): Promise<void> {
    requireUid();
    const docRef = doc(db, 'reminders', id);
    await deleteDoc(docRef);
  },
};

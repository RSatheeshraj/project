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
import db, { salesCol } from '@/lib/firebase/firestore';
import auth from '@/lib/firebase/auth';
import type { Sale, SaleInput } from '@/types/models';
import { RepositoryError } from './farm.repository';

function requireUid(): string {
  const uid = auth.currentUser?.uid;
  if (!uid) throw new RepositoryError('You must be signed in.');
  return uid;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function toSale(id: string, data: Record<string, any>): Sale {
  return {
    id,
    farmId: data.farmId ?? '',
    batchId: data.batchId ?? '',
    ownerId: data.ownerId ?? '',
    saleDate: data.saleDate?.toDate(),
    birdsSold: data.birdsSold ?? 0,
    averageWeight: data.averageWeight ?? 0,
    pricePerKg: data.pricePerKg ?? 0,
    buyerName: data.buyerName ?? '',
    buyerContact: data.buyerContact ?? '',
    invoiceNumber: data.invoiceNumber ?? '',
    notes: data.notes ?? '',
    totalWeight: data.totalWeight ?? 0,
    revenue: data.revenue ?? 0,
    estimatedProfit: data.estimatedProfit ?? 0,
    createdAt: data.createdAt?.toDate(),
    updatedAt: data.updatedAt?.toDate(),
  };
}

export const SaleRepository = {
  async getSales(farmId: string, batchId?: string): Promise<Sale[]> {
    const uid = requireUid();
    try {
      const q = batchId
        ? query(
            salesCol(),
            where('ownerId', '==', uid),
            where('farmId', '==', farmId),
            where('batchId', '==', batchId)
          )
        : query(
            salesCol(),
            where('ownerId', '==', uid),
            where('farmId', '==', farmId)
          );
      const snap = await getDocs(q);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const sales = snap.docs.map((d) => toSale(d.id, d.data() as any));
      
      // Sort in memory to avoid needing a composite index in Firestore
      return sales.sort((a, b) => {
        const dateA = a.saleDate?.getTime() || 0;
        const dateB = b.saleDate?.getTime() || 0;
        return dateB - dateA; // Descending
      });
    } catch (error) {
      console.error('Failed to fetch sales:', error);
      return []; // Graceful fallback
    }
  },

  async addSale(input: SaleInput): Promise<void> {
    const uid = requireUid();
    const totalWeight = input.birdsSold * input.averageWeight;
    const revenue = totalWeight * input.pricePerKg;
    const estimatedProfit = revenue * 0.2; // Rough estimate or whatever we can do
    
    await addDoc(salesCol(), {
      ...input,
      totalWeight,
      revenue,
      estimatedProfit,
      ownerId: uid,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
  },

  async updateSale(sale: Sale): Promise<void> {
    const uid = requireUid();
    if (sale.ownerId !== uid) {
      throw new RepositoryError('Not authorized.');
    }
    const docRef = doc(db, 'sales', sale.id);
    const totalWeight = sale.birdsSold * sale.averageWeight;
    const revenue = totalWeight * sale.pricePerKg;
    const estimatedProfit = revenue * 0.2;

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { id, createdAt, ownerId, ...data } = sale;
    
    await updateDoc(docRef, {
      ...data,
      totalWeight,
      revenue,
      estimatedProfit,
      updatedAt: serverTimestamp(),
    });
  },

  async deleteSale(saleId: string): Promise<void> {
    const docRef = doc(db, 'sales', saleId);
    await deleteDoc(docRef);
  },
};

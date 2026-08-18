/**
 * TypeScript domain models for PoultryGuardLite.
 *
 * These interfaces are the TypeScript equivalent of the Flutter data models:
 *   FarmModel     → Farm
 *   BatchModel    → Batch
 *   EntryModel    → WeeklyEntry
 *   ScanHistoryModel → ScanHistory
 *   AiScanResultModel → AiScanResult
 *
 * Firestore Timestamp fields are converted to JS Date objects by the repositories.
 */

// ── Farm ──────────────────────────────────────────────────────────────────────

/** Mirrors Flutter's FarmModel. Firestore path: /farms/{farmId} */
export interface Farm {
  id: string;
  name: string;
  /** Farm type: e.g. "Broiler", "Layer" */
  type: string;
  ownerName: string;
  phone: string;
  address: string;
  sheds: number;
  capacity: number;
  notes: string;
  /** e.g. "active", "completed", "closed", "archived" */
  status?: string;
  ownerId: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export type FarmInput = Omit<Farm, 'id' | 'ownerId' | 'createdAt' | 'updatedAt'>;

// ── Batch ─────────────────────────────────────────────────────────────────────

/**
 * Mirrors Flutter's BatchModel.
 * Firestore path: /farms/{farmId}/batches/{batchId}
 */
export interface Batch {
  id: string;
  farmId: string;
  ownerId: string;
  batchName: string;
  /** e.g. "Broiler", "Layer" */
  birdType: string;
  breed: string;
  totalBirds: number;
  currentBirds: number;
  supplier: string;
  arrivalDate?: Date;
  expectedMarketDate?: Date;
  /** e.g. "Active", "Completed", "Sold" */
  status: string;
  notes: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export type BatchInput = Omit<Batch, 'id' | 'ownerId' | 'createdAt' | 'updatedAt'>;


// ── Weekly Entry ──────────────────────────────────────────────────────────────

/**
 * Mirrors Flutter's EntryModel.
 * Firestore path: /farms/{farmId}/batches/{batchId}/weekly_entries/{entryId}
 */
export interface WeeklyEntry {
  id: string;
  batchId: string;
  farmId: string;
  ownerId: string;
  entryDate?: Date;
  feedConsumedKg: number;
  waterConsumedLitres: number;
  mortalityCount: number;
  averageWeightKg: number;
  temperature: number;
  humidity: number;
  vaccination: string;
  medicine: string;
  notes: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export type WeeklyEntryInput = Omit<
  WeeklyEntry,
  'id' | 'ownerId' | 'createdAt' | 'updatedAt'
>;

// ── AI Scan Result ────────────────────────────────────────────────────────────

/** Mirrors Flutter's AiScanResultModel — the structured Gemini Vision response */
export interface AiScanResult {
  diseaseName: string;
  confidence: number;
  /** "Low" | "Medium" | "High" | "Critical" */
  severity: string;
  possibleCause: string;
  immediateAction: string;
  treatment: string;
  prevention: string;
  isolationRequired: boolean;
}

// ── Scan History ──────────────────────────────────────────────────────────────

/**
 * Mirrors Flutter's ScanHistoryModel.
 * Firestore path: /scan_history/{scanId}
 */
export interface ScanHistory {
  id: string;
  ownerId: string;
  farmId: string;
  batchId: string;
  farmName: string;
  batchName: string;
  imageUrl: string;
  result: AiScanResult;
  createdAt?: Date;
  updatedAt?: Date;
}

// ── Sales ──────────────────────────────────────────────────────────────────────

/**
 * Firestore path: /sales/{saleId}
 */
export interface Sale {
  id: string;
  farmId: string;
  batchId: string;
  ownerId: string;
  saleDate?: Date;
  birdsSold: number;
  averageWeight: number;
  pricePerKg: number;
  buyerName: string;
  buyerContact: string;
  invoiceNumber: string;
  notes: string;
  totalWeight: number;
  revenue: number;
  estimatedProfit: number;
  createdAt?: Date;
  updatedAt?: Date;
}

export type SaleInput = Omit<Sale, 'id' | 'ownerId' | 'totalWeight' | 'revenue' | 'estimatedProfit' | 'createdAt' | 'updatedAt'>;

// ── Auth ──────────────────────────────────────────────────────────────────────

/** Minimal user info derived from Firebase Auth User */
export interface AppUser {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoURL: string | null;
}

/** Firestore Profile derived from users/{uid} */
export interface UserProfile {
  uid: string;
  displayName: string;
  email: string;
  profilePhotoUrl?: string;
  profilePhotoPath?: string;
  designation?: string;
  companyName: string;
  ownerName: string;
  phoneNumber: string;
  whatsappNumber?: string;
  companyEmail?: string;
  gstNumber?: string;
  farmRegistrationNumber?: string;
  websiteUrl?: string;
  companyDescription?: string;
  companyLogoUrl?: string;
  companyLogoPath?: string;
  address: string;
  city: string;
  state: string;
  country: string;
  pincode: string;
  preferredCurrency?: string;
  preferredWeightUnit?: string;
  defaultFarmName?: string;
  defaultFarmType?: string;
  preferredLanguage?: string;
  timeZone?: string;
  dateFormat?: string;
  createdAt?: string | Date;
  updatedAt?: string | Date;
}

// ── Veterinarian ──────────────────────────────────────────────────────────────

/**
 * Firestore path: /veterinarians/{id}
 */
export interface Veterinarian {
  id: string;
  doctorName: string;
  phoneNumber: string;
  whatsappNumber: string;
  email: string;
  address: string;
  isEmergency: boolean;
  ownerId: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export type VeterinarianInput = Omit<Veterinarian, 'id' | 'createdAt' | 'updatedAt' | 'ownerId'>;

// ── Reminder ──────────────────────────────────────────────────────────────────

/**
 * Firestore path: /reminders/{id}
 */
export interface Reminder {
  id: string;
  ownerId: string;
  farmId: string;
  batchId?: string;
  title: string;
  description?: string;
  category: 'Vaccination' | 'Feed' | 'Medicine' | 'Weekly Entry' | 'AI Scan' | 'Custom';
  dueDate: Date;
  status: 'Pending' | 'Completed';
  notificationEnabled?: boolean;
  notifyBeforeDays?: number;
  createdAt?: Date;
  updatedAt?: Date;
}

export type ReminderInput = Omit<Reminder, 'id' | 'ownerId' | 'createdAt' | 'updatedAt'>;

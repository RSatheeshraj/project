import { initializeApp, getApps } from 'firebase/app';
import {
  getAuth,
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  updateProfile,
} from 'firebase/auth';
import {
  getFirestore,
  collection,
  doc,
  setDoc,
  addDoc,
  getDocs,
  query,
  where,
  deleteDoc,
  Timestamp,
  terminate,
} from 'firebase/firestore';
import { readFileSync, existsSync } from 'fs';

// ── Load Firebase Config ─────────────────────────────────────────────────────

function getFirebaseConfig() {
  const defaults = {
    apiKey: 'AIzaSyCAv3VoRXAxnI6HAgbpYhYmECtHJA0MjLk',
    authDomain: 'poultryguardlite-435d9.firebaseapp.com',
    projectId: 'poultryguardlite-435d9',
    storageBucket: 'poultryguardlite-435d9.firebasestorage.app',
    messagingSenderId: '1050344579652',
    appId: '1:1050344579652:web:4f86bd6b3d9e00a9661211',
    measurementId: 'G-85CB46ZV2K',
  };

  if (existsSync('.env.local')) {
    const envContent = readFileSync('.env.local', 'utf-8');
    envContent.split('\n').forEach((line) => {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) return;
      const match = trimmed.match(/^([^=]+)=(.*)$/);
      if (match) {
        let val = match[2].trim();
        if (val.startsWith('"') && val.endsWith('"')) val = val.slice(1, -1);
        const key = match[1].trim();
        if (key === 'NEXT_PUBLIC_FIREBASE_API_KEY') defaults.apiKey = val;
        if (key === 'NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN') defaults.authDomain = val;
        if (key === 'NEXT_PUBLIC_FIREBASE_PROJECT_ID') defaults.projectId = val;
        if (key === 'NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET') defaults.storageBucket = val;
        if (key === 'NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID') defaults.messagingSenderId = val;
        if (key === 'NEXT_PUBLIC_FIREBASE_APP_ID') defaults.appId = val;
        if (key === 'NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID') defaults.measurementId = val;
      }
    });
  }

  return defaults;
}

// ── CLI argument parser ──────────────────────────────────────────────────────

function parseArgs() {
  const args = process.argv.slice(2);
  const options = {
    email: 'farmer.demo@poultryguard.com',
    password: 'Password123!',
    name: 'Demo Farmer',
    cleanExisting: true,
  };

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--email' && args[i + 1]) options.email = args[++i];
    if (args[i] === '--password' && args[i + 1]) options.password = args[++i];
    if (args[i] === '--name' && args[i + 1]) options.name = args[++i];
    if (args[i] === '--keep-existing') options.cleanExisting = false;
  }
  return options;
}

// ── Main Seeder ──────────────────────────────────────────────────────────────

async function main() {
  console.log('🐔 =================================================');
  console.log('🐔   PoultryGuard Lite — Database Seeder Script    ');
  console.log('🐔 =================================================\n');

  const options = parseArgs();
  const config = getFirebaseConfig();

  console.log(`📡 Target Firebase Project: "${config.projectId}"`);
  console.log(`👤 Target User:            ${options.email}\n`);

  const app = getApps().length ? getApps()[0] : initializeApp(config);
  const auth = getAuth(app);
  const db = getFirestore(app);

  // 1. Authenticate or Create Account
  let user;
  try {
    const cred = await signInWithEmailAndPassword(auth, options.email, options.password);
    user = cred.user;
    console.log(`✅ Signed into existing account (UID: ${user.uid})`);
  } catch (err) {
    if (err.code === 'auth/user-not-found' || err.code === 'auth/invalid-credential') {
      try {
        const cred = await createUserWithEmailAndPassword(auth, options.email, options.password);
        user = cred.user;
        await updateProfile(user, { displayName: options.name });
        console.log(`✨ Created new account (UID: ${user.uid})`);
      } catch (createErr) {
        throw new Error(`Failed to create user: ${createErr.message}`);
      }
    } else {
      throw err;
    }
  }

  const uid = user.uid;

  // 2. Clean previous data for this user if requested
  if (options.cleanExisting) {
    console.log('\n🧹 Cleaning previous data for this user...');
    
    // Clean farms & subcollections
    const userFarms = await getDocs(query(collection(db, 'farms'), where('ownerId', '==', uid)));
    for (const farmDoc of userFarms.docs) {
      const batches = await getDocs(collection(db, 'farms', farmDoc.id, 'batches'));
      for (const batchDoc of batches.docs) {
        const entries = await getDocs(
          collection(db, 'farms', farmDoc.id, 'batches', batchDoc.id, 'weekly_entries')
        );
        for (const entryDoc of entries.docs) {
          await deleteDoc(entryDoc.ref);
        }
        await deleteDoc(batchDoc.ref);
      }
      await deleteDoc(farmDoc.ref);
    }

    // Clean sales
    const userSales = await getDocs(query(collection(db, 'sales'), where('ownerId', '==', uid)));
    for (const saleDoc of userSales.docs) {
      await deleteDoc(saleDoc.ref);
    }

    // Clean scan_history
    const userScans = await getDocs(query(collection(db, 'scan_history'), where('ownerId', '==', uid)));
    for (const scanDoc of userScans.docs) {
      await deleteDoc(scanDoc.ref);
    }

    // Clean reminders
    const userReminders = await getDocs(query(collection(db, 'reminders'), where('ownerId', '==', uid)));
    for (const remDoc of userReminders.docs) {
      await deleteDoc(remDoc.ref);
    }

    // Clean veterinarians
    const userVets = await getDocs(query(collection(db, 'veterinarians'), where('ownerId', '==', uid)));
    for (const vetDoc of userVets.docs) {
      await deleteDoc(vetDoc.ref);
    }

    console.log('   Prior records cleaned.');
  }

  const now = new Date();
  const daysAgo = (days) => new Date(now.getTime() - days * 24 * 60 * 60 * 1000);
  const daysFromNow = (days) => new Date(now.getTime() + days * 24 * 60 * 60 * 1000);

  // 3. User Profile
  console.log('\n📝 1/7 Seeding User Profile in `users`...');
  await setDoc(doc(db, 'users', uid), {
    uid,
    displayName: options.name,
    email: options.email,
    ownerName: options.name,
    companyName: 'Green Valley Poultry Farms Ltd.',
    phoneNumber: '+919876543210',
    whatsappNumber: '+919876543210',
    companyEmail: 'contact@greenvalleypoultry.com',
    address: 'SF No. 124, Pollachi Main Road',
    city: 'Coimbatore',
    state: 'Tamil Nadu',
    country: 'India',
    pincode: '641021',
    preferredCurrency: 'INR',
    preferredWeightUnit: 'Kg',
    defaultFarmName: 'Green Valley Broiler Farm',
    defaultFarmType: 'Broiler',
    gstNumber: '33AAAAA0000A1Z5',
    farmRegistrationNumber: 'TN/CBE/2026/0891',
    companyDescription: 'Specialized in high-yield commercial broiler & layer poultry farming.',
    websiteUrl: 'https://greenvalleypoultry.example.com',
    createdAt: now.toISOString(),
    updatedAt: now.toISOString(),
  });
  console.log('   User profile configured.');

  // 4. Farms
  console.log('\n🏡 2/7 Seeding Farms...');
  const farm1Ref = await addDoc(collection(db, 'farms'), {
    name: 'Green Valley Broiler Farm',
    type: 'Broiler',
    ownerName: options.name,
    phone: '+919876543210',
    address: 'Sector 4, Sulur, Coimbatore',
    sheds: 4,
    capacity: 15000,
    notes: 'Primary commercial broiler facility with automated climate control.',
    status: 'Active',
    ownerId: uid,
    createdAt: Timestamp.fromDate(daysAgo(45)),
    updatedAt: Timestamp.fromDate(daysAgo(1)),
  });

  const farm2Ref = await addDoc(collection(db, 'farms'), {
    name: 'Golden Crest Layer Farm',
    type: 'Layer',
    ownerName: options.name,
    phone: '+919876543210',
    address: 'Village Road, Palladam, Tirupur',
    sheds: 2,
    capacity: 8000,
    notes: 'Commercial egg production flock.',
    status: 'Active',
    ownerId: uid,
    createdAt: Timestamp.fromDate(daysAgo(60)),
    updatedAt: Timestamp.fromDate(daysAgo(2)),
  });

  console.log(`   Created Farm 1: "Green Valley Broiler Farm" (${farm1Ref.id})`);
  console.log(`   Created Farm 2: "Golden Crest Layer Farm" (${farm2Ref.id})`);

  // 5. Batches & Weekly Entries
  console.log('\n🐥 3/7 Seeding Batches & Weekly Entries...');

  // Farm 1 — Batch A1 (Broiler)
  const batchA1Ref = await addDoc(collection(db, 'farms', farm1Ref.id, 'batches'), {
    farmId: farm1Ref.id,
    ownerId: uid,
    batchName: 'Batch 2026-A1 (Ross 308)',
    birdType: 'Broiler',
    breed: 'Ross 308',
    totalBirds: 5000,
    currentBirds: 4213, // 5000 - 72 mortality - 713 sold
    supplier: 'Suguna Hatcheries Ltd',
    arrivalDate: Timestamp.fromDate(daysAgo(32)),
    expectedMarketDate: Timestamp.fromDate(daysFromNow(8)),
    status: 'Active',
    notes: 'Healthy flock with excellent Feed Conversion Ratio (FCR).',
    createdAt: Timestamp.fromDate(daysAgo(32)),
    updatedAt: Timestamp.fromDate(daysAgo(1)),
  });

  const a1Entries = [
    {
      entryDate: daysAgo(28),
      feedConsumedKg: 420,
      waterConsumedLitres: 1050,
      mortalityCount: 22,
      averageWeightKg: 0.18,
      temperature: 32,
      humidity: 65,
      vaccination: "Marek's & ND-IB (Hatchery)",
      medicine: 'Electrolytes & Vitamin C',
      notes: 'Chicks settled nicely, uniform crop fill.',
    },
    {
      entryDate: daysAgo(21),
      feedConsumedKg: 980,
      waterConsumedLitres: 2450,
      mortalityCount: 18,
      averageWeightKg: 0.45,
      temperature: 29,
      humidity: 62,
      vaccination: 'Gumboro (IBD) Intermediate',
      medicine: 'Vitamins AD3E',
      notes: 'Litter dry, good feathering observed.',
    },
    {
      entryDate: daysAgo(14),
      feedConsumedKg: 1950,
      waterConsumedLitres: 4500,
      mortalityCount: 17,
      averageWeightKg: 0.98,
      temperature: 27,
      humidity: 60,
      vaccination: 'ND Lasota booster via drinking water',
      medicine: 'Probiotics',
      notes: 'High feed intake, good flock activity.',
    },
    {
      entryDate: daysAgo(7),
      feedConsumedKg: 2850,
      waterConsumedLitres: 6700,
      mortalityCount: 15,
      averageWeightKg: 1.68,
      temperature: 25,
      humidity: 58,
      vaccination: 'None',
      medicine: 'Liver Tonic + Toxi-binder',
      notes: 'Target finishing weight on schedule.',
    },
  ];

  for (const entry of a1Entries) {
    await addDoc(
      collection(db, 'farms', farm1Ref.id, 'batches', batchA1Ref.id, 'weekly_entries'),
      {
        farmId: farm1Ref.id,
        batchId: batchA1Ref.id,
        ownerId: uid,
        entryDate: Timestamp.fromDate(entry.entryDate),
        feedConsumedKg: entry.feedConsumedKg,
        waterConsumedLitres: entry.waterConsumedLitres,
        mortalityCount: entry.mortalityCount,
        averageWeightKg: entry.averageWeightKg,
        temperature: entry.temperature,
        humidity: entry.humidity,
        vaccination: entry.vaccination,
        medicine: entry.medicine,
        notes: entry.notes,
        createdAt: Timestamp.fromDate(entry.entryDate),
        updatedAt: Timestamp.fromDate(entry.entryDate),
      }
    );
  }

  // Farm 1 — Batch B2
  const batchB2Ref = await addDoc(collection(db, 'farms', farm1Ref.id, 'batches'), {
    farmId: farm1Ref.id,
    ownerId: uid,
    batchName: 'Batch 2026-B2 (Cobb 500)',
    birdType: 'Broiler',
    breed: 'Cobb 500',
    totalBirds: 4000,
    currentBirds: 3968,
    supplier: 'Venkateshwara Hatcheries',
    arrivalDate: Timestamp.fromDate(daysAgo(14)),
    expectedMarketDate: Timestamp.fromDate(daysFromNow(26)),
    status: 'Active',
    notes: 'Brooding phase flock in Shed #2.',
    createdAt: Timestamp.fromDate(daysAgo(14)),
    updatedAt: Timestamp.fromDate(daysAgo(1)),
  });

  const b2Entries = [
    {
      entryDate: daysAgo(14),
      feedConsumedKg: 350,
      waterConsumedLitres: 880,
      mortalityCount: 18,
      averageWeightKg: 0.17,
      temperature: 32,
      humidity: 65,
      vaccination: 'ND-IB live spray',
      medicine: 'Glucose + Electrolytes',
      notes: 'Day old chicks arrived active.',
    },
    {
      entryDate: daysAgo(7),
      feedConsumedKg: 820,
      waterConsumedLitres: 2050,
      mortalityCount: 14,
      averageWeightKg: 0.43,
      temperature: 29,
      humidity: 61,
      vaccination: 'IBD Georgia',
      medicine: 'Multivitamins',
      notes: 'Strong growth rate.',
    },
  ];

  for (const entry of b2Entries) {
    await addDoc(
      collection(db, 'farms', farm1Ref.id, 'batches', batchB2Ref.id, 'weekly_entries'),
      {
        farmId: farm1Ref.id,
        batchId: batchB2Ref.id,
        ownerId: uid,
        entryDate: Timestamp.fromDate(entry.entryDate),
        feedConsumedKg: entry.feedConsumedKg,
        waterConsumedLitres: entry.waterConsumedLitres,
        mortalityCount: entry.mortalityCount,
        averageWeightKg: entry.averageWeightKg,
        temperature: entry.temperature,
        humidity: entry.humidity,
        vaccination: entry.vaccination,
        medicine: entry.medicine,
        notes: entry.notes,
        createdAt: Timestamp.fromDate(entry.entryDate),
        updatedAt: Timestamp.fromDate(entry.entryDate),
      }
    );
  }

  // Farm 2 — Batch L1
  const batchL1Ref = await addDoc(collection(db, 'farms', farm2Ref.id, 'batches'), {
    farmId: farm2Ref.id,
    ownerId: uid,
    batchName: 'Batch 2026-L1 (BV300 Layer)',
    birdType: 'Layer',
    breed: 'BV300',
    totalBirds: 3500,
    currentBirds: 3479,
    supplier: 'BV Hatcheries',
    arrivalDate: Timestamp.fromDate(daysAgo(60)),
    expectedMarketDate: Timestamp.fromDate(daysFromNow(180)),
    status: 'Active',
    notes: 'Egg laying production flock.',
    createdAt: Timestamp.fromDate(daysAgo(60)),
    updatedAt: Timestamp.fromDate(daysAgo(2)),
  });

  const l1Entries = [
    {
      entryDate: daysAgo(21),
      feedConsumedKg: 620,
      waterConsumedLitres: 1550,
      mortalityCount: 8,
      averageWeightKg: 1.45,
      temperature: 26,
      humidity: 60,
      vaccination: 'ND Lasota booster',
      medicine: 'Calcium + D3 liquid',
      notes: 'Laying rate 91%. Good shell color.',
    },
    {
      entryDate: daysAgo(14),
      feedConsumedKg: 640,
      waterConsumedLitres: 1600,
      mortalityCount: 6,
      averageWeightKg: 1.48,
      temperature: 26,
      humidity: 59,
      vaccination: 'None',
      medicine: 'Mineral premix',
      notes: 'Egg production stable at 93%.',
    },
    {
      entryDate: daysAgo(7),
      feedConsumedKg: 635,
      waterConsumedLitres: 1580,
      mortalityCount: 7,
      averageWeightKg: 1.49,
      temperature: 25,
      humidity: 60,
      vaccination: 'Deworming (Albendazole)',
      medicine: 'Probiotics',
      notes: 'High uniformity in egg trays.',
    },
  ];

  for (const entry of l1Entries) {
    await addDoc(
      collection(db, 'farms', farm2Ref.id, 'batches', batchL1Ref.id, 'weekly_entries'),
      {
        farmId: farm2Ref.id,
        batchId: batchL1Ref.id,
        ownerId: uid,
        entryDate: Timestamp.fromDate(entry.entryDate),
        feedConsumedKg: entry.feedConsumedKg,
        waterConsumedLitres: entry.waterConsumedLitres,
        mortalityCount: entry.mortalityCount,
        averageWeightKg: entry.averageWeightKg,
        temperature: entry.temperature,
        humidity: entry.humidity,
        vaccination: entry.vaccination,
        medicine: entry.medicine,
        notes: entry.notes,
        createdAt: Timestamp.fromDate(entry.entryDate),
        updatedAt: Timestamp.fromDate(entry.entryDate),
      }
    );
  }

  console.log(`   Seeded 3 Batches with 9 Weekly Entries.`);

  // 6. Sales
  console.log('\n💰 4/7 Seeding Sales Records...');
  const salesData = [
    {
      farmId: farm1Ref.id,
      batchId: batchA1Ref.id,
      ownerId: uid,
      saleDate: Timestamp.fromDate(daysAgo(5)),
      birdsSold: 213,
      averageWeight: 2.1,
      pricePerKg: 135,
      totalWeight: 447.3,
      revenue: 60385.5,
      estimatedProfit: 12077.1,
      buyerName: 'Kovai Fresh Poultry Ltd',
      buyerContact: '+919443211234',
      invoiceNumber: 'INV-2026-001',
      notes: 'First lift of heavier birds for supermarket chain.',
      createdAt: Timestamp.fromDate(daysAgo(5)),
      updatedAt: Timestamp.fromDate(daysAgo(5)),
    },
    {
      farmId: farm1Ref.id,
      batchId: batchA1Ref.id,
      ownerId: uid,
      saleDate: Timestamp.fromDate(daysAgo(2)),
      birdsSold: 500,
      averageWeight: 2.2,
      pricePerKg: 138,
      totalWeight: 1100,
      revenue: 151800,
      estimatedProfit: 30360,
      buyerName: 'Metro Chicken Wholesalers',
      buyerContact: '+919842109876',
      invoiceNumber: 'INV-2026-002',
      notes: 'Bulk purchase for wholesale chicken distribution.',
      createdAt: Timestamp.fromDate(daysAgo(2)),
      updatedAt: Timestamp.fromDate(daysAgo(2)),
    },
  ];

  for (const s of salesData) {
    await addDoc(collection(db, 'sales'), s);
  }
  console.log(`   Seeded ${salesData.length} sales with total revenue ₹${(60385.5 + 151800).toLocaleString()}.`);

  // 7. AI Scan History
  console.log('\n🔬 5/7 Seeding AI Disease Scan History...');
  const scans = [
    {
      ownerId: uid,
      farmId: farm1Ref.id,
      batchId: batchA1Ref.id,
      farmName: 'Green Valley Broiler Farm',
      batchName: 'Batch 2026-A1 (Ross 308)',
      imageUrl: 'https://images.unsplash.com/photo-1548550023-2bdb3c5beed7?auto=format&fit=crop&w=600&q=80',
      result: {
        diseaseName: 'Healthy Flock',
        confidence: 96,
        severity: 'Low',
        possibleCause: 'Flock displays normal posture, clean plumage, active feeding, and bright red combs.',
        immediateAction: 'Continue current biosecurity standards and maintain fresh drinker flow.',
        treatment: 'No therapeutic treatment needed. Maintain scheduled electrolyte and vitamin regimen.',
        prevention: 'Maintain litter dryness below 25% moisture and ensure proper ventilation.',
        isolationRequired: false,
      },
      createdAt: Timestamp.fromDate(daysAgo(10)),
      updatedAt: Timestamp.fromDate(daysAgo(10)),
    },
    {
      ownerId: uid,
      farmId: farm1Ref.id,
      batchId: batchA1Ref.id,
      farmName: 'Green Valley Broiler Farm',
      batchName: 'Batch 2026-A1 (Ross 308)',
      imageUrl: 'https://images.unsplash.com/photo-1516467508483-a7212febe31a?auto=format&fit=crop&w=600&q=80',
      result: {
        diseaseName: 'Coccidiosis (Eimeria tenella)',
        confidence: 88,
        severity: 'High',
        possibleCause: 'Damp litter around water lines fostering sporulation and ingestion of Eimeria oocysts.',
        immediateAction: 'Separate lethargic birds. Rake out and replace wet bedding under drinkers immediately.',
        treatment: 'Administer Toltrazuril (Baycox 2.5%) at 7 mg/kg body weight in drinking water for 2 consecutive days.',
        prevention: 'Apply coccidiostat rotation in feeds and clean drinking nipples with chlorine flush.',
        isolationRequired: true,
      },
      createdAt: Timestamp.fromDate(daysAgo(4)),
      updatedAt: Timestamp.fromDate(daysAgo(4)),
    },
    {
      ownerId: uid,
      farmId: farm2Ref.id,
      batchId: batchL1Ref.id,
      farmName: 'Golden Crest Layer Farm',
      batchName: 'Batch 2026-L1 (BV300 Layer)',
      imageUrl: 'https://images.unsplash.com/photo-1563281577-a7be47e20db9?auto=format&fit=crop&w=600&q=80',
      result: {
        diseaseName: 'Infectious Bronchitis',
        confidence: 84,
        severity: 'Medium',
        possibleCause: 'Coronavirus transmission aggravated by chilling drafts during sudden nighttime temperature drop.',
        immediateAction: 'Raise house temperature by 2°C and inspect for air drafts in north curtains.',
        treatment: 'Supportive therapy using eucalyptus/menthol respiratory spray and Vitamin C/E in water.',
        prevention: 'Verify booster vaccination coverage with IB Ma5/4-91 strains.',
        isolationRequired: false,
      },
      createdAt: Timestamp.fromDate(daysAgo(1)),
      updatedAt: Timestamp.fromDate(daysAgo(1)),
    },
  ];

  for (const scan of scans) {
    await addDoc(collection(db, 'scan_history'), scan);
  }
  console.log(`   Seeded ${scans.length} AI scan reports.`);

  // 8. Reminders
  console.log('\n🔔 6/7 Seeding Reminders...');
  const reminders = [
    {
      ownerId: uid,
      farmId: farm1Ref.id,
      batchId: batchA1Ref.id,
      title: 'NDV Lasota Booster Vaccination',
      description: 'Administer Lasota via morning drinking water with skimmed milk stabilizer.',
      category: 'Vaccination',
      status: 'Pending',
      dueDate: Timestamp.fromDate(daysFromNow(1)),
      notificationEnabled: true,
      notifyBeforeDays: 1,
      createdAt: Timestamp.fromDate(daysAgo(3)),
      updatedAt: Timestamp.fromDate(daysAgo(3)),
    },
    {
      ownerId: uid,
      farmId: farm1Ref.id,
      title: 'Bulk Finisher Feed Delivery',
      description: 'Receive 5 MT broiler finisher feed; inspect bag batch numbers and moisture levels.',
      category: 'Feed',
      status: 'Pending',
      dueDate: Timestamp.fromDate(daysFromNow(3)),
      notificationEnabled: true,
      notifyBeforeDays: 1,
      createdAt: Timestamp.fromDate(daysAgo(2)),
      updatedAt: Timestamp.fromDate(daysAgo(2)),
    },
    {
      ownerId: uid,
      farmId: farm1Ref.id,
      batchId: batchB2Ref.id,
      title: 'Weekly Weight Sampling (Batch B2)',
      description: 'Sample 100 birds across 4 quadrants to calculate flock uniformity and mean weight.',
      category: 'Weekly Entry',
      status: 'Pending',
      dueDate: Timestamp.fromDate(daysFromNow(2)),
      notificationEnabled: true,
      notifyBeforeDays: 0,
      createdAt: Timestamp.fromDate(daysAgo(1)),
      updatedAt: Timestamp.fromDate(daysAgo(1)),
    },
    {
      ownerId: uid,
      farmId: farm1Ref.id,
      batchId: batchA1Ref.id,
      title: 'Flock Litter Moisture Check',
      description: 'Check litter under water lines; replace any caked litter with dry wood shavings.',
      category: 'Custom',
      status: 'Completed',
      dueDate: Timestamp.fromDate(daysAgo(1)),
      notificationEnabled: false,
      createdAt: Timestamp.fromDate(daysAgo(4)),
      updatedAt: Timestamp.fromDate(daysAgo(1)),
    },
  ];

  for (const r of reminders) {
    await addDoc(collection(db, 'reminders'), r);
  }
  console.log(`   Seeded ${reminders.length} task reminders.`);

  // 9. Veterinarians
  console.log('\n🩺 7/7 Seeding Veterinarians Directory...');
  const vets = [
    {
      doctorName: 'Dr. K. Ramesh, M.V.Sc (Poultry Medicine)',
      phoneNumber: '+919443355678',
      whatsappNumber: '+919443355678',
      email: 'dr.ramesh.vet@gmail.com',
      address: 'Avian Health Diagnostic Center, Trichy Road, Coimbatore',
      isEmergency: true,
      ownerId: uid,
      createdAt: Timestamp.fromDate(daysAgo(40)),
      updatedAt: Timestamp.fromDate(daysAgo(40)),
    },
    {
      doctorName: 'Dr. Priya Sundaram, Ph.D (Avian Pathology)',
      phoneNumber: '+919842144321',
      whatsappNumber: '+919842144321',
      email: 'priya.aviancare@vetconsult.org',
      address: 'District Veterinary Polyclinic, Tirupur',
      isEmergency: false,
      ownerId: uid,
      createdAt: Timestamp.fromDate(daysAgo(30)),
      updatedAt: Timestamp.fromDate(daysAgo(30)),
    },
    {
      doctorName: 'Dr. S. Vignesh, B.V.Sc (Field Nutrition Specialist)',
      phoneNumber: '+919789012345',
      whatsappNumber: '+919789012345',
      email: 'vignesh.nutrition@farmsolutions.in',
      address: 'Livestock Advisory Centre, Namakkal',
      isEmergency: false,
      ownerId: uid,
      createdAt: Timestamp.fromDate(daysAgo(20)),
      updatedAt: Timestamp.fromDate(daysAgo(20)),
    },
  ];

  for (const v of vets) {
    await addDoc(collection(db, 'veterinarians'), v);
  }
  console.log(`   Seeded ${vets.length} veterinarians in directory.`);

  await terminate(db);

  console.log('\n🎉 =================================================');
  console.log('🎉   Database Seeding Completed Successfully!       ');
  console.log('🎉 =================================================');
  console.log('\n👉 You can now log into PoultryGuard Lite with:');
  console.log(`   Email:    ${options.email}`);
  console.log(`   Password: ${options.password}`);
  console.log(`   UID:      ${uid}\n`);

  process.exit(0);
}

main().catch((err) => {
  console.error('\n❌ Seeding failed with error:', err);
  process.exit(1);
});

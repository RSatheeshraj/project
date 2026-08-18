import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { readFileSync } from 'fs';

async function run() {
  const envContent = readFileSync('.env.local', 'utf-8');
  const env = {};
  envContent.split('\n').forEach(line => {
    const match = line.match(/^([^=]+)=(.*)$/);
    if (match) {
      let val = match[2].trim();
      if (val.startsWith('"') && val.endsWith('"')) val = val.slice(1, -1);
      env[match[1].trim()] = val.replace(/\\n/g, '\n');
    }
  });

  initializeApp({
    credential: cert({
      projectId: env['NEXT_PUBLIC_FIREBASE_PROJECT_ID'],
      clientEmail: env['FIREBASE_CLIENT_EMAIL'],
      privateKey: env['FIREBASE_PRIVATE_KEY']
    })
  });
  
  const db = getFirestore();
  
  const scanHistorySnap = await db.collection('scan_history')
    .orderBy('createdAt', 'desc')
    .limit(1)
    .get();

  if (scanHistorySnap.empty) {
    throw new Error('Scan was not saved to Firestore!');
  }
  const doc = scanHistorySnap.docs[0];
  console.log('Saved document result:', doc.data().result);
  console.log('Saved document createdAt:', doc.data().createdAt?.toDate());

  console.log('E2E Validation completed successfully!');
  process.exit(0);
}

run().catch(err => {
  console.error('Validation failed:', err);
  process.exit(1);
});
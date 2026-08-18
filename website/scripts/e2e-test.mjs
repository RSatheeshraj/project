import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { readFileSync } from 'fs';

async function run() {
  console.log('1. Initializing Firebase Admin SDK...');
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
  
  console.log('2. Fetching Farm from Firestore...');
  const farmsSnap = await db.collection('farms').limit(1).get();
  if (farmsSnap.empty) throw new Error('No farms found in DB for testing.');
  const farmDoc = farmsSnap.docs[0];
  const farmId = farmDoc.id;
  const uid = farmDoc.data().ownerId;
  console.log(`Found Farm ID: ${farmId}, Owner ID: ${uid}`);

  console.log('3. Fetching Batch...');
  const batchesSnap = await db.collection(`farms/${farmId}/batches`).limit(1).get();
  if (batchesSnap.empty) throw new Error('No batches found in the first farm for testing.');
  const batchDoc = batchesSnap.docs[0];
  const batchId = batchDoc.id;
  console.log(`Found Batch ID: ${batchId}`);

  console.log('4. Creating test image...');
  const imageBase64 = '/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA=';
  const buffer = Buffer.from(imageBase64, 'base64');
  const blob = new Blob([buffer], { type: 'image/jpeg' });

  console.log('5. Simulating browser FormData upload to /api/ai-scan...');
  const formData = new FormData();
  formData.append('image', blob, 'test.jpg');
  formData.append('farmId', farmId);
  formData.append('batchId', batchId);
  formData.append('uid', uid);

  const res = await fetch('http://localhost:3000/api/ai-scan', {
    method: 'POST',
    body: formData
  });

  const text = await res.text();
  console.log(`HTTP ${res.status}`);
  let json;
  try {
    json = JSON.parse(text);
  } catch (e) {
    console.error('Raw response:', text);
    throw e;
  }
  console.log('Response JSON:', JSON.stringify(json, null, 2));

  if (!res.ok) {
    throw new Error(`API returned error: ${json.error}`);
  }

  console.log('6. Verifying saved scan_history document...');
  const scanHistorySnap = await db.collection('scan_history')
    .where('ownerId', '==', uid)
    .where('farmId', '==', farmId)
    .where('batchId', '==', batchId)
    .orderBy('createdAt', 'desc')
    .limit(1)
    .get();

  if (scanHistorySnap.empty) {
    throw new Error('Scan was not saved to Firestore!');
  }
  const scanData = scanHistorySnap.docs[0].data();
  console.log('Saved document result:', scanData.result);

  console.log('E2E Validation completed successfully!');
  process.exit(0);
}

run().catch(err => {
  console.error('Validation failed:', err);
  process.exit(1);
});
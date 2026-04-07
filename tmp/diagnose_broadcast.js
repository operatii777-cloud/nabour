const admin = require('firebase-admin');
const fs = require('fs');

// Inițializare folosind setările implicite ale mediului sau o cale către un fișier de credentiale dacă există
try {
  admin.initializeApp({
    projectId: 'nabour-4b4e4'
  });

  const db = admin.firestore();

  async function checkLastBroadcast() {
    console.log('--- Investigating last ride_broadcast document ---');
    const snapshot = await db.collection('ride_broadcasts')
      .orderBy('createdAt', 'desc')
      .limit(1)
      .get();

    if (snapshot.empty) {
      console.log('No documents found in ride_broadcasts.');
      return;
    }

    const doc = snapshot.docs[0];
    const data = doc.data();
    
    console.log(`Document ID: ${doc.id}`);
    console.log(`Created At: ${data.createdAt ? data.createdAt.toDate().toISOString() : 'N/A'}`);
    console.log(`Passenger ID: ${data.passengerId}`);
    console.log(`Allowed UIDs:`, data.allowedUids);
    console.log(`Allowed UIDs count: ${Array.isArray(data.allowedUids) ? data.allowedUids.length : 'Not an array'}`);
    console.log('----------------------------------------------------');
  }

  checkLastBroadcast();
} catch (e) {
  console.error('Error connecting to Firestore:', e);
}

const admin = require('firebase-admin');
const fs = require('fs');

// Initialize with default credentials from CLI
admin.initializeApp({
  projectId: 'nabour-4b4e4'
});

async function main() {
  const uid = 'dxv9N91CaaeKSG86R0iFJZUI0Q12';
  const db = admin.firestore();
  
  try {
    await db.collection('users').doc(uid).collection('token_wallet').doc('wallet').set({
      plan: 'unlimited'
    }, { merge: true });
    console.log('SUCCESS: Account is now unlimited.');
  } catch (err) {
    console.error('FAILED:', err);
  }
}

main();

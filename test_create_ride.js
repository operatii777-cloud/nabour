/**
 * Script de test: creează o cursă în Firestore și urmărește dacă driverul o primește.
 * Rulat cu: node test_create_ride.js
 * NU necesită voce — injectează direct în Firebase.
 */

const https = require('https');
const fs = require('fs');
const path = require('path');

// --- Config ---
const PROJECT_ID = 'nabour-4b4e4';
const PASSENGER_UID = 'fsDX4Ap7YNRo30kvMGCKzaZkdQj1'; // Lenovo
const DRIVER_UID    = 'dxv9N91CaaeKSG86R0iFJZUI0Q12'; // Xiaomi

// Coordonate Bucuresti (Piata Victoriei -> Piata Unirii)
const PICKUP_LAT  = 44.4512;
const PICKUP_LNG  = 26.0849;
const DEST_LAT    = 44.4282;
const DEST_LNG    = 26.1016;

// --- Citeste/reîmprospătează access_token Firebase CLI ---
async function getAccessToken() {
  // Încearcă mai întâi tmp_token.txt (dacă e proaspăt)
  if (fs.existsSync('tmp_token.txt')) {
    const stat = fs.statSync('tmp_token.txt');
    const ageMs = Date.now() - stat.mtimeMs;
    if (ageMs < 50 * 60 * 1000) { // < 50 minute
      return fs.readFileSync('tmp_token.txt', 'utf8').trim();
    }
  }
  // Reîmprospătează via OAuth2
  const cfgPath = path.join(process.env.USERPROFILE || process.env.HOME, '.config', 'configstore', 'firebase-tools.json');
  const cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
  const rt = cfg.tokens?.refresh_token;
  const body = `client_id=563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com&client_secret=j9iVZfS8kkCEFUPaAeJV0sAi&grant_type=refresh_token&refresh_token=${rt}`;
  const res = await httpsRequest({ hostname: 'oauth2.googleapis.com', path: '/token', method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'Content-Length': body.length } }, body);
  if (!res.body.access_token) { console.error('Token refresh failed:', res.body); process.exit(1); }
  fs.writeFileSync('tmp_token.txt', res.body.access_token, 'utf8');
  return res.body.access_token;
}

function httpsRequest(options, body) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(data) }); }
        catch { resolve({ status: res.statusCode, body: data }); }
      });
    });
    req.on('error', reject);
    if (body) req.write(typeof body === 'string' ? body : JSON.stringify(body));
    req.end();
  });
}

function firestoreValue(obj) {
  // Converteste un obiect JS în format Firestore REST
  if (typeof obj === 'string')  return { stringValue: obj };
  if (typeof obj === 'number' && Number.isInteger(obj)) return { integerValue: String(obj) };
  if (typeof obj === 'number')  return { doubleValue: obj };
  if (typeof obj === 'boolean') return { booleanValue: obj };
  if (obj === null)             return { nullValue: 'NULL_VALUE' };
  if (Array.isArray(obj)) return { arrayValue: { values: obj.map(firestoreValue) } };
  if (typeof obj === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(obj)) fields[k] = firestoreValue(v);
    return { mapValue: { fields } };
  }
  return { stringValue: String(obj) };
}

async function main() {
  const token = await getAccessToken();
  console.log('✅ Token Firebase obtinut.');

  // --- Sterge orice cursa activa anterioara a pasagerului ---
  console.log('🧹 Caut curse active vechi...');
  const queryBody = {
    structuredQuery: {
      from: [{ collectionId: 'ride_requests' }],
      where: {
        compositeFilter: {
          op: 'AND',
          filters: [
            { fieldFilter: { field: { fieldPath: 'passengerId' }, op: 'EQUAL', value: { stringValue: PASSENGER_UID } } },
            { fieldFilter: { field: { fieldPath: 'status' }, op: 'IN', value: { arrayValue: { values: [
              { stringValue: 'pending' }, { stringValue: 'searching' }, { stringValue: 'accepted' },
              { stringValue: 'driver_found' }, { stringValue: 'in_progress' }
            ]}}}}
          ]
        }
      },
      limit: 5
    }
  };

  const queryRes = await httpsRequest({
    hostname: 'firestore.googleapis.com',
    path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents:runQuery`,
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' }
  }, queryBody);

  if (queryRes.status === 401) {
    console.error('❌ Token invalid/expirat. Rulează: firebase login --reauth');
    process.exit(1);
  }

  const docs = Array.isArray(queryRes.body) ? queryRes.body.filter(r => r.document) : [];
  for (const entry of docs) {
    const docName = entry.document.name;
    const rideId = docName.split('/').pop();
    console.log(`   🗑️  Sterg cursa activa veche: ${rideId}`);
    await httpsRequest({
      hostname: 'firestore.googleapis.com',
      path: `/v1/${docName}`,
      method: 'DELETE',
      headers: { 'Authorization': `Bearer ${token}` }
    }, null);
  }

  // --- Creeaza cursa noua ---
  const rideId = `test_${Date.now()}`;
  const rideData = {
    fields: {
      passengerId:          firestoreValue(PASSENGER_UID),
      pickupLocation:       firestoreValue('Piata Victoriei, Bucuresti'),
      destination:          firestoreValue('Piata Unirii, Bucuresti'),
      pickupLatitude:       firestoreValue(PICKUP_LAT),
      pickupLongitude:      firestoreValue(PICKUP_LNG),
      destinationLatitude:  firestoreValue(DEST_LAT),
      destinationLongitude: firestoreValue(DEST_LNG),
      estimatedPrice:       firestoreValue(18.5),
      category:             firestoreValue('standard'),
      urgency:              firestoreValue('normal'),
      status:               firestoreValue('pending'),
      allowedDriverUids:    firestoreValue([DRIVER_UID]),
      createdAt:            { timestampValue: new Date().toISOString() },
      distanceKm:           firestoreValue(3.2),
      durationMinutes:      firestoreValue(12.0),
      passengerName:        firestoreValue('Test Pasager'),
    }
  };

  console.log(`\n🚕 Creez cursa: ${rideId}`);
  console.log(`   Pasager: ${PASSENGER_UID}`);
  console.log(`   Driver:  ${DRIVER_UID}`);
  console.log(`   Pickup:  Piata Victoriei (${PICKUP_LAT}, ${PICKUP_LNG})`);
  console.log(`   Dest:    Piata Unirii   (${DEST_LAT}, ${DEST_LNG})`);

  const createRes = await httpsRequest({
    hostname: 'firestore.googleapis.com',
    path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents/ride_requests?documentId=${rideId}`,
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' }
  }, rideData);

  if (createRes.status === 200 || createRes.status === 201) {
    console.log(`\n✅ Cursa creata cu succes in Firestore!`);
    console.log(`   ID: ${rideId}`);
    console.log('\n⏳ Astept 5 secunde si verific daca driverul a primit...');
  } else {
    console.error(`\n❌ Eroare la creare: HTTP ${createRes.status}`);
    console.error(JSON.stringify(createRes.body, null, 2));
    process.exit(1);
  }

  // --- Asteapta si verifica status-ul cursei ---
  await new Promise(r => setTimeout(r, 5000));

  const checkRes = await httpsRequest({
    hostname: 'firestore.googleapis.com',
    path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents/ride_requests/${rideId}`,
    method: 'GET',
    headers: { 'Authorization': `Bearer ${token}` }
  }, null);

  if (checkRes.status === 200) {
    const fields = checkRes.body.fields || {};
    const status = fields.status?.stringValue || '?';
    const driverId = fields.driverId?.stringValue || '(niciunul)';
    console.log(`\n📊 Status dupa 5s: ${status}`);
    console.log(`   Driver acceptat: ${driverId}`);

    if (status === 'pending') {
      console.log('\n⚠️  Driverul nu a acceptat inca. Verifica logcat Xiaomi.');
      console.log('   CMD: adb -s 192.168.50.183:5555 logcat -d -t 200 | grep -i "ride\\|dispatch\\|ghost\\|pending"');
    } else if (status === 'accepted' || status === 'driver_found') {
      console.log('\n🎉 SUCCES! Driverul a primit si acceptat cursa!');
    }
  } else {
    console.log(`Verificare status: HTTP ${checkRes.status}`);
  }

  console.log(`\n🔗 Ride ID pentru cleanup: ${rideId}`);
  console.log(`   Sterge manual: DELETE ride_requests/${rideId}`);
}

main().catch(e => { console.error('Fatal:', e.message); process.exit(1); });

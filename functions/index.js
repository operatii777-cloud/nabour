/**
 * FriendsRide Cloud Functions — Main Entry Point
 *
 * Exports:
 *   - FCM notifications (sendDriverNotification, sendPassengerNotification, sendChatNotification)
 *   - Driver matching (onRideCreated, checkOfferTimeouts, onRideStatusChanged)
 *   - Emergency alerts (handleEmergencyAlert)
 *   - Delivery API (syncMenu, createOrder, updateOrderStatus, getOrder, getMenu)
 */

// Re-export delivery API functions
const deliveryApi = require('./delivery-api/index.js');
exports.syncMenu = deliveryApi.syncMenu;
exports.createOrder = deliveryApi.createOrder;
exports.updateOrderStatus = deliveryApi.updateOrderStatus;
exports.getOrder = deliveryApi.getOrder;
exports.getMenu = deliveryApi.getMenu;

/**
 * FriendsRide Cloud Functions
 * - FCM push notifications (driver, passenger, chat)
 * - Driver matching on ride creation
 * - Emergency alert handling
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const messaging = admin.messaging();

// ─── HELPERS ─────────────────────────────────────────────────────────────────

/**
 * Send FCM notification to a user by their Firestore userId.
 * Reads fcmToken from users/{userId}.
 */
async function sendToUser(userId, { title, body, data = {} }) {
  const userDoc = await db.collection('users').doc(userId).get();
  const token = userDoc.data()?.fcmToken;
  if (!token) {
    console.log(`[FCM] No token for user ${userId}`);
    return;
  }
  const message = {
    token,
    notification: { title, body },
    data: Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v)])
    ),
    android: {
      priority: 'high',
      notification: { channelId: 'friendsride_default', sound: 'default' },
    },
    apns: {
      payload: { aps: { sound: 'default', badge: 1 } },
    },
  };
  try {
    await messaging.send(message);
    console.log(`[FCM] Sent to user ${userId}: ${title}`);
  } catch (err) {
    console.error(`[FCM] Error sending to ${userId}:`, err.message);
  }
}

/**
 * Distance in km between two lat/lng points (Haversine).
 */
function haversineKm(lat1, lng1, lat2, lng2) {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// ─── CALLABLE: sendDriverNotification ────────────────────────────────────────

exports.sendDriverNotification = functions.https.onCall(async (data, context) => {
  const { driverId, rideId, type, title, body, distanceKm } = data;
  if (!driverId || !rideId) throw new functions.https.HttpsError('invalid-argument', 'driverId and rideId required');

  await sendToUser(driverId, {
    title: title || 'Notificare cursă',
    body: body || 'Ai o actualizare despre cursă.',
    data: { type: type || 'ride_update', rideId, distanceKm: distanceKm?.toString() || '0' },
  });
  return { success: true };
});

// ─── CALLABLE: sendPassengerNotification ─────────────────────────────────────

exports.sendPassengerNotification = functions.https.onCall(async (data, context) => {
  const { passengerId, rideId, type, title, body } = data;
  if (!passengerId || !rideId) throw new functions.https.HttpsError('invalid-argument', 'passengerId and rideId required');

  await sendToUser(passengerId, {
    title: title || 'Actualizare cursă',
    body: body || 'Cursă actualizată.',
    data: { type: type || 'ride_update', rideId },
  });
  return { success: true };
});

// ─── CALLABLE: sendChatNotification ──────────────────────────────────────────

exports.sendChatNotification = functions.https.onCall(async (data, context) => {
  const { token, rideId, senderName, messageText, title, body, senderUid, isPrivateChat } = data;
  if (!token) throw new functions.https.HttpsError('invalid-argument', 'token required');

  const chatId = rideId || '';
  const priv = !!isPrivateChat;
  const msgType = priv ? 'private_chat_message' : 'chat_message';

  const message = {
    token,
    notification: { title: title || senderName, body: body || messageText },
    data: {
      type: msgType,
      rideId: String(chatId),
      chatId: String(chatId),
      senderName: String(senderName || ''),
      senderUid: String(senderUid || ''),
      isPrivateChat: priv ? '1' : '0',
    },
    android: {
      priority: 'high',
      notification: { channelId: 'friendsride_default', sound: 'default' },
    },
    apns: { payload: { aps: { sound: 'default' } } },
  };

  try {
    await messaging.send(message);
    return { success: true };
  } catch (err) {
    throw new functions.https.HttpsError('internal', err.message);
  }
});

// ─── FIRESTORE TRIGGER: onNeighborhoodChatMessage — notificare chat cartier ──

exports.onNeighborhoodChatMessage = functions.firestore
  .document('neighborhood_chats/{roomId}/messages/{msgId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data) return;

    const roomId = context.params.roomId;
    const senderUid = data.uid || '';
    const senderName = data.displayName || 'Vecin';
    const text = data.text || '';
    const preview = text.length > 80 ? text.substring(0, 80) + '…' : text;

    // Trim folosim FCM topics — toți abonații la topic-ul camerei primesc notificarea.
    // Sender-ul e exclus pe partea de client (ignoră dacă senderUid == currentUser.uid).
    const topic = `neighborhood_${roomId}`;

    const message = {
      topic,
      notification: {
        title: `${senderName} 🏘️`,
        body: preview,
      },
      data: {
        type: 'neighborhood_chat',
        roomId: String(roomId),
        senderUid: String(senderUid),
        senderName: String(senderName),
      },
      android: {
        priority: 'high',
        notification: { channelId: 'neighborhood_chat', sound: 'default' },
      },
      apns: {
        payload: { aps: { sound: 'default', badge: 1 } },
      },
    };

    try {
      await messaging.send(message);
      console.log(`[FCM] Neighborhood chat sent to topic ${topic}: "${preview}"`);
    } catch (err) {
      console.error('[FCM] Neighborhood chat error:', err.message);
    }
  });

// ─── FIRESTORE TRIGGER: onRideCreated — driver matching ──────────────────────

exports.onRideCreated = functions.firestore
  .document('rides/{rideId}')
  .onCreate(async (snap, context) => {
    const rideId = context.params.rideId;
    const ride = snap.data();

    // Only match rides that are in 'searching' status
    if (ride.status !== 'searching') return null;

    const pickupLat = ride.startLatitude ?? ride.pickupLatitude;
    const pickupLng = ride.startLongitude ?? ride.pickupLongitude;
    const category = ride.category ?? 'standard';

    if (!pickupLat || !pickupLng) {
      console.log(`[Matching] Ride ${rideId} has no pickup coordinates`);
      return null;
    }

    console.log(`[Matching] New ride ${rideId} at ${pickupLat},${pickupLng} category=${category}`);

    // Find online drivers within 10 km bounding box
    const radiusKm = 10;
    const latDelta = radiusKm / 111;
    const lngDelta = radiusKm / (111 * Math.cos((pickupLat * Math.PI) / 180));

    const driversSnap = await db
      .collection('drivers')
      .where('isOnline', '==', true)
      .where('isAvailable', '==', true)
      .where('currentLatitude', '>=', pickupLat - latDelta)
      .where('currentLatitude', '<=', pickupLat + latDelta)
      .get();

    if (driversSnap.empty) {
      console.log(`[Matching] No online drivers found for ride ${rideId}`);
      await snap.ref.update({ status: 'no_drivers', noDriversAt: admin.firestore.FieldValue.serverTimestamp() });
      // Notify passenger
      if (ride.passengerId) {
        await sendToUser(ride.passengerId, {
          title: 'Niciun șofer disponibil',
          body: 'Nu am găsit un șofer în zona ta. Încearcă din nou.',
          data: { type: 'no_driver', rideId },
        });
      }
      return null;
    }

    // Filter by lng and sort by distance
    const drivers = driversSnap.docs
      .map(doc => ({ id: doc.id, ...doc.data() }))
      .filter(d => Math.abs(d.currentLongitude - pickupLng) <= lngDelta)
      .map(d => ({
        ...d,
        distanceKm: haversineKm(pickupLat, pickupLng, d.currentLatitude, d.currentLongitude),
      }))
      .sort((a, b) => a.distanceKm - b.distanceKm);

    if (drivers.length === 0) {
      console.log(`[Matching] No drivers within radius for ride ${rideId}`);
      return null;
    }

    // Offer to nearest driver
    const nearest = drivers[0];
    console.log(`[Matching] Offering ride ${rideId} to driver ${nearest.id} (${nearest.distanceKm.toFixed(2)} km)`);

    await snap.ref.update({
      offeredToDriver: nearest.id,
      offeredAt: admin.firestore.FieldValue.serverTimestamp(),
      offerExpiresAt: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 30 * 1000) // 30 second window
      ),
    });

    await sendToUser(nearest.id, {
      title: '🚗 Nouă ofertă de cursă',
      body: `Cursă la ${nearest.distanceKm.toFixed(1)} km distanță. Acceptă în 30 secunde!`,
      data: {
        type: 'ride_assignment',
        rideId,
        distanceKm: nearest.distanceKm.toFixed(1),
        pickupAddress: ride.startAddress || ride.pickupAddress || '',
        destination: ride.destination || '',
      },
    });

    return null;
  });

// ─── FIRESTORE TRIGGER: onRideStatusChanged ───────────────────────────────────

exports.onRideStatusChanged = functions.firestore
  .document('rides/{rideId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const rideId = context.params.rideId;

    if (before.status === after.status) return null;

    const passengerId = after.passengerId;
    const driverId = after.driverId;

    const statusMessages = {
      accepted: {
        toPassenger: { title: '✅ Șofer găsit!', body: 'Șoferul tău se îndreaptă spre tine.' },
      },
      arrived: {
        toPassenger: { title: '📍 Șoferul a ajuns!', body: 'Șoferul tău te așteaptă la locul de îmbarcare.' },
      },
      in_progress: {
        toPassenger: { title: '🚗 Cursă începută', body: 'Călătoria ta a început. Drum bun!' },
      },
      completed: {
        toPassenger: { title: '🏁 Cursă finalizată', body: 'Ai ajuns! Nu uita să lași o recenzie.' },
        toDriver: { title: '💰 Cursă finalizată', body: 'Cursa s-a terminat. Câștigul a fost adăugat.' },
      },
      cancelled: {
        toPassenger: { title: '❌ Cursă anulată', body: 'Cursa a fost anulată.' },
        toDriver: { title: '❌ Cursă anulată', body: 'Pasagerul a anulat cursa.' },
      },
    };

    const msgs = statusMessages[after.status];
    if (!msgs) return null;

    const tasks = [];
    if (msgs.toPassenger && passengerId) {
      tasks.push(sendToUser(passengerId, { ...msgs.toPassenger, data: { type: 'ride_update', rideId, status: after.status } }));
    }
    if (msgs.toDriver && driverId) {
      tasks.push(sendToUser(driverId, { ...msgs.toDriver, data: { type: 'ride_update', rideId, status: after.status } }));
    }

    await Promise.all(tasks);
    return null;
  });

// ─── FIRESTORE TRIGGER: onDriverOfferTimeout ─────────────────────────────────

exports.checkOfferTimeouts = functions.pubsub
  .schedule('every 1 minutes')
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();

    // Find rides where offer expired but still searching
    const expiredSnap = await db
      .collection('rides')
      .where('status', '==', 'searching')
      .where('offeredToDriver', '!=', null)
      .where('offerExpiresAt', '<=', now)
      .get();

    for (const doc of expiredSnap.docs) {
      const ride = doc.data();
      const timedOutDriver = ride.offeredToDriver;
      console.log(`[Matching] Offer timed out for ride ${doc.id}, driver ${timedOutDriver}`);

      // Add to declined list and try next driver
      const declinedDrivers = [...(ride.declinedDrivers || []), timedOutDriver];

      await doc.ref.update({
        offeredToDriver: null,
        offerExpiresAt: null,
        declinedDrivers,
      });

      // Notify driver of timeout
      if (timedOutDriver) {
        await sendToUser(timedOutDriver, {
          title: '⏱ Ofertă expirată',
          body: 'Timpul pentru acceptarea cursei a expirat.',
          data: { type: 'ride_timeout', rideId: doc.id },
        });
      }

      // Re-trigger matching by finding next available driver
      const pickupLat = ride.startLatitude ?? ride.pickupLatitude;
      const pickupLng = ride.startLongitude ?? ride.pickupLongitude;
      if (!pickupLat || !pickupLng) continue;

      const radiusKm = 10;
      const latDelta = radiusKm / 111;
      const lngDelta = radiusKm / (111 * Math.cos((pickupLat * Math.PI) / 180));

      const driversSnap = await db
        .collection('drivers')
        .where('isOnline', '==', true)
        .where('isAvailable', '==', true)
        .where('currentLatitude', '>=', pickupLat - latDelta)
        .where('currentLatitude', '<=', pickupLat + latDelta)
        .get();

      const nextDrivers = driversSnap.docs
        .map(d => ({ id: d.id, ...d.data() }))
        .filter(d =>
          !declinedDrivers.includes(d.id) &&
          Math.abs(d.currentLongitude - pickupLng) <= lngDelta
        )
        .map(d => ({
          ...d,
          distanceKm: haversineKm(pickupLat, pickupLng, d.currentLatitude, d.currentLongitude),
        }))
        .sort((a, b) => a.distanceKm - b.distanceKm);

      if (nextDrivers.length === 0) {
        await doc.ref.update({
          status: 'no_drivers',
          noDriversAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        if (ride.passengerId) {
          await sendToUser(ride.passengerId, {
            title: 'Niciun șofer disponibil',
            body: 'Nu am găsit un șofer disponibil. Încearcă din nou.',
            data: { type: 'no_driver', rideId: doc.id },
          });
        }
        continue;
      }

      const next = nextDrivers[0];
      await doc.ref.update({
        offeredToDriver: next.id,
        offeredAt: admin.firestore.FieldValue.serverTimestamp(),
        offerExpiresAt: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 30 * 1000)
        ),
      });

      await sendToUser(next.id, {
        title: '🚗 Nouă ofertă de cursă',
        body: `Cursă la ${next.distanceKm.toFixed(1)} km distanță. Acceptă în 30 secunde!`,
        data: {
          type: 'ride_assignment',
          rideId: doc.id,
          distanceKm: next.distanceKm.toFixed(1),
          pickupAddress: ride.startAddress || ride.pickupAddress || '',
          destination: ride.destination || '',
        },
      });
    }

    return null;
  });

// ─── CALLABLE: handleEmergencyAlert ──────────────────────────────────────────

exports.handleEmergencyAlert = functions.firestore
  .document('emergency_alerts/{alertId}')
  .onCreate(async (snap, context) => {
    const alert = snap.data();
    console.log(`[Emergency] Alert from user ${alert.userId} at ${alert.latitude},${alert.longitude}`);

    // Notify all admin users
    const adminsSnap = await db
      .collection('users')
      .where('role', '==', 'admin')
      .get();

    for (const admin of adminsSnap.docs) {
      await sendToUser(admin.id, {
        title: '🆘 ALERTĂ DE URGENȚĂ',
        body: `${alert.userName || 'Utilizator'} are nevoie de ajutor!`,
        data: {
          type: 'emergency',
          alertId: context.params.alertId,
          rideId: alert.rideId || '',
          latitude: alert.latitude?.toString() || '',
          longitude: alert.longitude?.toString() || '',
        },
      });
    }

    return null;
  });

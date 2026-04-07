/**
 * Cloud Functions pentru Delivery API
 * 
 * Aceste funcții expun API endpoints pentru integrarea restaurante externe
 * cu FriendsRide Delivery
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Middleware pentru validare API Key
 */
async function validateApiKey(req, res, next) {
  const apiKey = req.headers.authorization?.replace('Bearer ', '');
  
  if (!apiKey) {
    return res.status(401).json({
      error: {
        code: 'MISSING_API_KEY',
        message: 'API key is required',
      },
    });
  }

  try {
    // Hash API key and find in Firestore
    const crypto = require('crypto');
    const hashedKey = crypto.createHash('sha256').update(apiKey).digest('hex');
    
    const apiKeyQuery = await db.collection('restaurant_api_keys')
      .where('hashedKey', '==', hashedKey)
      .where('isActive', '==', true)
      .limit(1)
      .get();

    if (apiKeyQuery.empty) {
      return res.status(401).json({
        error: {
          code: 'INVALID_API_KEY',
          message: 'API key is invalid or expired',
        },
      });
    }

    const apiKeyDoc = apiKeyQuery.docs[0];
    const restaurantId = apiKeyDoc.data().restaurantId;

    // Attach restaurantId to request
    req.restaurantId = restaurantId;
    req.apiKeyDoc = apiKeyDoc;

    // Update lastUsedAt
    await apiKeyDoc.ref.update({
      lastUsedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    next();
  } catch (error) {
    console.error('Error validating API key:', error);
    return res.status(500).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Internal server error',
      },
    });
  }
}

/**
 * CORS middleware
 */
function corsHandler(req, res, next) {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  next();
}

/**
 * POST /api/delivery/restaurants/{restaurantId}/menu/sync
 * Sincronizează meniul restaurantului
 */
exports.syncMenu = functions.https.onRequest(async (req, res) => {
  corsHandler(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).json({ error: 'Method not allowed' });
    }

    await validateApiKey(req, res, async () => {
      try {
        const { restaurantId } = req.params;
        const { products } = req.body;

        if (!products || !Array.isArray(products)) {
          return res.status(400).json({
            error: {
              code: 'INVALID_REQUEST',
              message: 'Products array is required',
            },
          });
        }

        // Validate restaurant ownership
        if (req.restaurantId !== restaurantId) {
          return res.status(403).json({
            error: {
              code: 'FORBIDDEN',
              message: 'Access denied',
            },
          });
        }

        const batch = db.batch();
        let syncedCount = 0;

        for (const product of products) {
          const productRef = db.collection('products').doc(product.id || db.collection('products').doc().id);
          
          batch.set(productRef, {
            restaurantId: restaurantId,
            name: product.name,
            description: product.description || '',
            price: product.price,
            category: product.category || 'Other',
            imageUrl: product.imageUrl || null,
            isAvailable: product.isAvailable !== false,
            allergens: product.allergens || [],
            availableModifications: product.availableModifications || [],
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            createdAt: product.createdAt 
              ? admin.firestore.Timestamp.fromDate(new Date(product.createdAt))
              : admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });

          syncedCount++;
        }

        await batch.commit();

        return res.status(200).json({
          success: true,
          syncedProducts: syncedCount,
          message: 'Menu synced successfully',
        });
      } catch (error) {
        console.error('Error syncing menu:', error);
        return res.status(500).json({
          error: {
            code: 'INTERNAL_ERROR',
            message: error.message,
          },
        });
      }
    });
  });
});

/**
 * POST /api/delivery/orders
 * Creează o comandă de delivery
 */
exports.createOrder = functions.https.onRequest(async (req, res) => {
  corsHandler(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).json({ error: 'Method not allowed' });
    }

    await validateApiKey(req, res, async () => {
      try {
        const {
          restaurantId,
          items,
          deliveryAddress,
          paymentMethod,
          customerPhone,
          customerName,
          notes,
        } = req.body;

        // Validate required fields
        if (!restaurantId || !items || !deliveryAddress || !paymentMethod) {
          return res.status(400).json({
            error: {
              code: 'INVALID_REQUEST',
              message: 'Missing required fields',
            },
          });
        }

        // Validate restaurant ownership
        if (req.restaurantId !== restaurantId) {
          return res.status(403).json({
            error: {
              code: 'FORBIDDEN',
              message: 'Access denied',
            },
          });
        }

        // Calculate totals
        let subtotal = 0;
        for (const item of items) {
          subtotal += (item.totalPrice || item.unitPrice * item.quantity);
        }

        const restaurantDoc = await db.collection('restaurants').doc(restaurantId).get();
        const restaurantData = restaurantDoc.data();
        const deliveryFee = restaurantData?.deliveryFee || 5.0;
        const serviceFee = Math.min(subtotal * 0.10, 3.0);
        const total = subtotal + deliveryFee + serviceFee;

        // Create order
        const orderRef = db.collection('delivery_orders').doc();
        const orderId = orderRef.id;

        const orderData = {
          id: orderId,
          customerId: null, // External orders don't have customerId
          restaurantId: restaurantId,
          status: 'pending',
          items: items,
          subtotal: subtotal,
          deliveryFee: deliveryFee,
          serviceFee: serviceFee,
          total: total,
          deliveryAddress: {
            id: '',
            label: 'Livrare',
            address: deliveryAddress.address,
            coordinates: admin.firestore.GeoPoint(
              deliveryAddress.latitude,
              deliveryAddress.longitude
            ),
          },
          restaurantAddress: restaurantData?.address || {},
          paymentMethod: paymentMethod,
          metadata: {
            source: 'api',
            customerPhone: customerPhone,
            customerName: customerName,
            notes: notes,
          },
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        await orderRef.set(orderData);

        // Calculate estimated delivery time
        const estimatedDeliveryTime = restaurantData?.estimatedDeliveryTime || 30;

        return res.status(201).json({
          success: true,
          orderId: orderId,
          status: 'pending',
          estimatedDeliveryTime: estimatedDeliveryTime,
          total: total,
        });
      } catch (error) {
        console.error('Error creating order:', error);
        return res.status(500).json({
          error: {
            code: 'INTERNAL_ERROR',
            message: error.message,
          },
        });
      }
    });
  });
});

/**
 * PUT /api/delivery/orders/{orderId}/status
 * Actualizează statusul unei comenzi
 */
exports.updateOrderStatus = functions.https.onRequest(async (req, res) => {
  corsHandler(req, res, async () => {
    if (req.method !== 'PUT') {
      return res.status(405).json({ error: 'Method not allowed' });
    }

    await validateApiKey(req, res, async () => {
      try {
        const { orderId } = req.params;
        const { status, estimatedTime } = req.body;

        if (!status) {
          return res.status(400).json({
            error: {
              code: 'INVALID_REQUEST',
              message: 'Status is required',
            },
          });
        }

        const orderRef = db.collection('delivery_orders').doc(orderId);
        const orderDoc = await orderRef.get();

        if (!orderDoc.exists) {
          return res.status(404).json({
            error: {
              code: 'ORDER_NOT_FOUND',
              message: 'Order not found',
            },
          });
        }

        const orderData = orderDoc.data();

        // Validate restaurant ownership
        if (orderData.restaurantId !== req.restaurantId) {
          return res.status(403).json({
            error: {
              code: 'FORBIDDEN',
              message: 'Access denied',
            },
          });
        }

        // Update order status
        await orderRef.update({
          status: status,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          ...(estimatedTime && {
            estimatedDeliveryTime: admin.firestore.Timestamp.fromDate(
              new Date(Date.now() + estimatedTime * 60000)
            ),
          }),
        });

        return res.status(200).json({
          success: true,
          orderId: orderId,
          status: status,
          updatedAt: new Date().toISOString(),
        });
      } catch (error) {
        console.error('Error updating order status:', error);
        return res.status(500).json({
          error: {
            code: 'INTERNAL_ERROR',
            message: error.message,
          },
        });
      }
    });
  });
});

/**
 * GET /api/delivery/orders/{orderId}
 * Obține detalii despre o comandă
 */
exports.getOrder = functions.https.onRequest(async (req, res) => {
  corsHandler(req, res, async () => {
    if (req.method !== 'GET') {
      return res.status(405).json({ error: 'Method not allowed' });
    }

    await validateApiKey(req, res, async () => {
      try {
        const { orderId } = req.params;

        const orderDoc = await db.collection('delivery_orders').doc(orderId).get();

        if (!orderDoc.exists) {
          return res.status(404).json({
            error: {
              code: 'ORDER_NOT_FOUND',
              message: 'Order not found',
            },
          });
        }

        const orderData = orderDoc.data();

        // Validate restaurant ownership
        if (orderData.restaurantId !== req.restaurantId) {
          return res.status(403).json({
            error: {
              code: 'FORBIDDEN',
              message: 'Access denied',
            },
          });
        }

        return res.status(200).json({
          orderId: orderDoc.id,
          ...orderData,
          createdAt: orderData.createdAt?.toDate().toISOString(),
          updatedAt: orderData.updatedAt?.toDate().toISOString(),
        });
      } catch (error) {
        console.error('Error getting order:', error);
        return res.status(500).json({
          error: {
            code: 'INTERNAL_ERROR',
            message: error.message,
          },
        });
      }
    });
  });
});

/**
 * GET /api/delivery/restaurants/{restaurantId}/menu
 * Obține meniul restaurantului
 */
exports.getMenu = functions.https.onRequest(async (req, res) => {
  corsHandler(req, res, async () => {
    if (req.method !== 'GET') {
      return res.status(405).json({ error: 'Method not allowed' });
    }

    await validateApiKey(req, res, async () => {
      try {
        const { restaurantId } = req.params;

        // Validate restaurant ownership
        if (req.restaurantId !== restaurantId) {
          return res.status(403).json({
            error: {
              code: 'FORBIDDEN',
              message: 'Access denied',
            },
          });
        }

        const productsSnapshot = await db.collection('products')
          .where('restaurantId', '==', restaurantId)
          .where('isAvailable', '==', true)
          .get();

        const products = productsSnapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data(),
          createdAt: doc.data().createdAt?.toDate().toISOString(),
          updatedAt: doc.data().updatedAt?.toDate().toISOString(),
        }));

        return res.status(200).json({
          restaurantId: restaurantId,
          products: products,
        });
      } catch (error) {
        console.error('Error getting menu:', error);
        return res.status(500).json({
          error: {
            code: 'INTERNAL_ERROR',
            message: error.message,
          },
        });
      }
    });
  });
});


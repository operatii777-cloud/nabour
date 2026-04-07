/**
 * Token Transfer & Payment Request Cloud Functions
 *
 * Implements:
 *   - createTokenDirectTransfer   (immediate, no acceptance required)
 *   - createTokenPaymentRequest   (request from payer, requires acceptance)
 *   - respondToTokenPaymentRequest (accept | decline)
 *   - cancelTokenPaymentRequest   (initiator cancels a pending request)
 *   - expireTokenPaymentRequests  (scheduled — marks overdue pending requests expired)
 *
 * All balance mutations use atomic Firestore transactions via Admin SDK.
 * All Callables require firebase-functions/v2 with App Check enforcement
 * configured at the project level (no client writes to wallet/ledger).
 */

import * as admin from "firebase-admin";
import { randomUUID } from "node:crypto";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";

const db = () => admin.firestore();

// ─── Constants ─────────────────────────────────────────────────────────────

const MIN_AMOUNT_MINOR = 1;
const MAX_AMOUNT_MINOR = 1_000_000;
const MAX_NOTE_LENGTH = 200;
const PAYMENT_REQUEST_TTL_HOURS = 72;

// ─── Helpers ───────────────────────────────────────────────────────────────

function assertAuth(uid: string | undefined): asserts uid is string {
  if (!uid) throw new HttpsError("unauthenticated", "UNAUTHENTICATED");
}

function validateAmount(amount: unknown): number {
  const n = Number(amount);
  if (!Number.isInteger(n) || n < MIN_AMOUNT_MINOR || n > MAX_AMOUNT_MINOR) {
    throw new HttpsError(
      "invalid-argument",
      `INVALID_AMOUNT: must be integer between ${MIN_AMOUNT_MINOR} and ${MAX_AMOUNT_MINOR}`
    );
  }
  return n;
}

function sanitizeNote(note: unknown): string | undefined {
  if (note == null) return undefined;
  const s = String(note).slice(0, MAX_NOTE_LENGTH).trim();
  return s.length > 0 ? s : undefined;
}

async function assertUserExists(uid: string): Promise<void> {
  const snap = await db().collection("users").doc(uid).get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "COUNTERPARTY_NOT_FOUND");
  }
}

async function getWallet(
  txn: admin.firestore.Transaction,
  userId: string
): Promise<{ ref: admin.firestore.DocumentReference; balanceMinor: number; status: string }> {
  const ref = db().collection("token_wallets").doc(userId);
  const snap = await txn.get(ref);
  if (!snap.exists) {
    throw new HttpsError("not-found", `COUNTERPARTY_NOT_FOUND: wallet missing for ${userId}`);
  }
  const data = snap.data()!;
  const status = (data.status as string) ?? "active";
  if (status === "frozen") {
    throw new HttpsError("failed-precondition", "WALLET_FROZEN");
  }
  if (status === "closed") {
    throw new HttpsError("failed-precondition", "WALLET_FROZEN");
  }
  return {
    ref,
    balanceMinor: (data.balanceMinor as number) ?? 0,
    status,
  };
}

function writeLedgerEntries(
  txn: admin.firestore.Transaction,
  opts: {
    correlationGroupId: string;
    fromUserId: string;
    toUserId: string;
    amountMinor: number;
    referenceType: "direct_transfer" | "payment_request";
    referenceId: string;
    fromBalanceAfter: number;
    toBalanceAfter: number;
  }
): void {
  const now = admin.firestore.FieldValue.serverTimestamp();
  const debitType =
    opts.referenceType === "direct_transfer"
      ? "direct_transfer_debit"
      : "payment_request_debit";
  const creditType =
    opts.referenceType === "direct_transfer"
      ? "direct_transfer_credit"
      : "payment_request_credit";

  const debitRef = db().collection("token_ledger").doc();
  txn.set(debitRef, {
    userId: opts.fromUserId,
    deltaMinor: -opts.amountMinor,
    type: debitType,
    counterpartyUserId: opts.toUserId,
    referenceType: opts.referenceType,
    referenceId: opts.referenceId,
    correlationGroupId: opts.correlationGroupId,
    balanceAfterMinor: opts.fromBalanceAfter,
    createdAt: now,
  });

  const creditRef = db().collection("token_ledger").doc();
  txn.set(creditRef, {
    userId: opts.toUserId,
    deltaMinor: opts.amountMinor,
    type: creditType,
    counterpartyUserId: opts.fromUserId,
    referenceType: opts.referenceType,
    referenceId: opts.referenceId,
    correlationGroupId: opts.correlationGroupId,
    balanceAfterMinor: opts.toBalanceAfter,
    createdAt: now,
  });
}

// ─── sendFcmNotification (best-effort, non-blocking) ───────────────────────

async function sendFcm(
  recipientUid: string,
  payload: Record<string, string>
): Promise<void> {
  try {
    const tokenSnap = await db()
      .collection("users")
      .doc(recipientUid)
      .collection("fcm_tokens")
      .orderBy("updatedAt", "desc")
      .limit(1)
      .get();
    if (tokenSnap.empty) return;
    const token = tokenSnap.docs[0].data().token as string | undefined;
    if (!token) return;
    await admin.messaging().send({
      token,
      data: payload,
    });
  } catch {
    // Non-fatal: swallow FCM errors
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 1. createTokenDirectTransfer
// ═══════════════════════════════════════════════════════════════════════════

export const createTokenDirectTransfer = onCall(async (request) => {
  const uid = request.auth?.uid;
  assertAuth(uid);

  const { toUserId, amountMinor: rawAmount, note: rawNote, clientRequestId } =
    (request.data ?? {}) as Record<string, unknown>;

  if (!clientRequestId || typeof clientRequestId !== "string") {
    throw new HttpsError("invalid-argument", "clientRequestId is required");
  }
  if (!toUserId || typeof toUserId !== "string") {
    throw new HttpsError("invalid-argument", "toUserId is required");
  }
  if (uid === toUserId) {
    throw new HttpsError("invalid-argument", "SELF_TRANSFER");
  }

  const amountMinor = validateAmount(rawAmount);
  const note = sanitizeNote(rawNote);

  // Idempotency check: if a completed transfer with same clientRequestId exists, return it
  const idempotencyQuery = await db()
    .collection("token_direct_transfers")
    .where("fromUserId", "==", uid)
    .where("clientRequestId", "==", clientRequestId)
    .limit(1)
    .get();

  if (!idempotencyQuery.empty) {
    const existing = idempotencyQuery.docs[0];
    const d = existing.data();
    if (d.status === "completed") {
      return {
        transferId: existing.id,
        status: "completed",
        ledgerCorrelationId: d.ledgerCorrelationId ?? null,
        idempotent: true,
      };
    }
    // If status is failed, fall through to retry
  }

  await assertUserExists(toUserId);

  const correlationGroupId = randomUUID();
  const transferRef = db().collection("token_direct_transfers").doc();
  const transferId = transferRef.id;
  const now = admin.firestore.FieldValue.serverTimestamp();

  try {
    await db().runTransaction(async (txn) => {
      const fromWallet = await getWallet(txn, uid);
      const toWallet = await getWallet(txn, toUserId);

      if (fromWallet.balanceMinor < amountMinor) {
        throw new HttpsError("failed-precondition", "INSUFFICIENT_BALANCE");
      }

      const fromBalanceAfter = fromWallet.balanceMinor - amountMinor;
      const toBalanceAfter = toWallet.balanceMinor + amountMinor;

      txn.update(fromWallet.ref, {
        balanceMinor: fromBalanceAfter,
        updatedAt: now,
        version: admin.firestore.FieldValue.increment(1),
      });
      txn.update(toWallet.ref, {
        balanceMinor: toBalanceAfter,
        updatedAt: now,
        version: admin.firestore.FieldValue.increment(1),
      });

      txn.set(transferRef, {
        fromUserId: uid,
        toUserId,
        amountMinor,
        ...(note != null ? { note } : {}),
        status: "completed",
        ledgerCorrelationId: correlationGroupId,
        clientRequestId,
        createdAt: now,
      });

      writeLedgerEntries(txn, {
        correlationGroupId,
        fromUserId: uid,
        toUserId,
        amountMinor,
        referenceType: "direct_transfer",
        referenceId: transferId,
        fromBalanceAfter,
        toBalanceAfter,
      });
    });
  } catch (err) {
    if (err instanceof HttpsError) {
      // Record failed transfer document (outside transaction, best-effort)
      await db()
        .collection("token_direct_transfers")
        .doc(transferId)
        .set({
          fromUserId: uid,
          toUserId,
          amountMinor,
          ...(note != null ? { note } : {}),
          status: "failed",
          failureCode: err.message,
          clientRequestId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        })
        .catch(() => undefined);
      throw err;
    }
    throw new HttpsError("internal", "Transaction failed");
  }

  // Best-effort FCM notification to recipient
  sendFcm(toUserId, {
    type: "direct_transfer_received",
    transferId,
  });

  return { transferId, status: "completed", ledgerCorrelationId: correlationGroupId };
});

// ═══════════════════════════════════════════════════════════════════════════
// 2. createTokenPaymentRequest
// ═══════════════════════════════════════════════════════════════════════════

export const createTokenPaymentRequest = onCall(async (request) => {
  const uid = request.auth?.uid;
  assertAuth(uid);

  const { payerId: rawPayerId, amountMinor: rawAmount, note: rawNote } =
    (request.data ?? {}) as Record<string, unknown>;

  if (!rawPayerId || typeof rawPayerId !== "string") {
    throw new HttpsError("invalid-argument", "payerId is required");
  }
  if (uid === rawPayerId) {
    throw new HttpsError("invalid-argument", "SELF_REQUEST");
  }

  const payerId = rawPayerId;
  const amountMinor = validateAmount(rawAmount);
  const note = sanitizeNote(rawNote);

  await assertUserExists(payerId);

  const now = admin.firestore.Timestamp.now();
  const expiresAt = admin.firestore.Timestamp.fromDate(
    new Date(now.toMillis() + PAYMENT_REQUEST_TTL_HOURS * 60 * 60 * 1000)
  );

  const ref = db().collection("token_payment_requests").doc();
  await ref.set({
    payerId,
    payeeId: uid,
    initiatorId: uid,
    amountMinor,
    ...(note != null ? { note } : {}),
    status: "pending",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt,
  });

  sendFcm(payerId, {
    type: "payment_request_pending",
    requestId: ref.id,
  });

  return { requestId: ref.id };
});

// ═══════════════════════════════════════════════════════════════════════════
// 3. respondToTokenPaymentRequest
// ═══════════════════════════════════════════════════════════════════════════

export const respondToTokenPaymentRequest = onCall(async (request) => {
  const uid = request.auth?.uid;
  assertAuth(uid);

  const {
    requestId: rawRequestId,
    action,
    declineReason: rawReason,
  } = (request.data ?? {}) as Record<string, unknown>;

  if (!rawRequestId || typeof rawRequestId !== "string") {
    throw new HttpsError("invalid-argument", "requestId is required");
  }
  if (action !== "accept" && action !== "decline") {
    throw new HttpsError("invalid-argument", "action must be accept or decline");
  }

  const requestId = rawRequestId;
  const declineReason = sanitizeNote(rawReason);
  const reqRef = db().collection("token_payment_requests").doc(requestId);

  if (action === "decline") {
    // No money movement — simple status update in a transaction for consistency
    await db().runTransaction(async (txn) => {
      const reqSnap = await txn.get(reqRef);
      if (!reqSnap.exists) {
        throw new HttpsError("not-found", "REQUEST_NOT_FOUND");
      }
      const reqData = reqSnap.data()!;
      if (reqData.payerId !== uid) {
        throw new HttpsError("permission-denied", "FORBIDDEN");
      }
      if (reqData.status !== "pending") {
        if (reqData.status === "declined") {
          return; // idempotent
        }
        throw new HttpsError("failed-precondition", "REQUEST_NOT_PENDING");
      }
      const now = admin.firestore.FieldValue.serverTimestamp();
      txn.update(reqRef, {
        status: "declined",
        resolvedAt: now,
        updatedAt: now,
        ...(declineReason != null ? { declineReason } : {}),
      });
    });

    // Notify payee
    const reqSnap = await reqRef.get();
    if (reqSnap.exists) {
      sendFcm(reqSnap.data()!.payeeId as string, {
        type: "payment_request_declined",
        requestId,
      });
    }
    return { requestId, status: "declined" };
  }

  // action === 'accept'
  const correlationGroupId = randomUUID();

  let payeeId: string | undefined;
  try {
    await db().runTransaction(async (txn) => {
      const reqSnap = await txn.get(reqRef);
      if (!reqSnap.exists) {
        throw new HttpsError("not-found", "REQUEST_NOT_FOUND");
      }
      const reqData = reqSnap.data()!;

      if (reqData.payerId !== uid) {
        throw new HttpsError("permission-denied", "FORBIDDEN");
      }

      // Idempotency: already accepted
      if (reqData.status === "accepted") {
        return;
      }

      if (reqData.status !== "pending") {
        throw new HttpsError("failed-precondition", "REQUEST_NOT_PENDING");
      }

      const expiresAt = reqData.expiresAt as admin.firestore.Timestamp;
      if (expiresAt.toMillis() < Date.now()) {
        throw new HttpsError("failed-precondition", "REQUEST_EXPIRED");
      }

      payeeId = reqData.payeeId as string;
      const amountMinor = reqData.amountMinor as number;

      const payerWallet = await getWallet(txn, uid);
      const payeeWallet = await getWallet(txn, payeeId);

      if (payerWallet.balanceMinor < amountMinor) {
        throw new HttpsError("failed-precondition", "INSUFFICIENT_BALANCE");
      }

      const payerBalanceAfter = payerWallet.balanceMinor - amountMinor;
      const payeeBalanceAfter = payeeWallet.balanceMinor + amountMinor;
      const now = admin.firestore.FieldValue.serverTimestamp();

      txn.update(payerWallet.ref, {
        balanceMinor: payerBalanceAfter,
        updatedAt: now,
        version: admin.firestore.FieldValue.increment(1),
      });
      txn.update(payeeWallet.ref, {
        balanceMinor: payeeBalanceAfter,
        updatedAt: now,
        version: admin.firestore.FieldValue.increment(1),
      });
      txn.update(reqRef, {
        status: "accepted",
        resolvedAt: now,
        updatedAt: now,
        ledgerCorrelationId: correlationGroupId,
      });

      writeLedgerEntries(txn, {
        correlationGroupId,
        fromUserId: uid,       // payer is debited
        toUserId: payeeId,
        amountMinor,
        referenceType: "payment_request",
        referenceId: requestId,
        fromBalanceAfter: payerBalanceAfter,
        toBalanceAfter: payeeBalanceAfter,
      });
    });
  } catch (err) {
    if (err instanceof HttpsError) throw err;
    throw new HttpsError("internal", "Transaction failed");
  }

  if (payeeId) {
    sendFcm(payeeId, {
      type: "payment_request_accepted",
      requestId,
    });
  }
  return { requestId, status: "accepted", ledgerCorrelationId: correlationGroupId };
});

// ═══════════════════════════════════════════════════════════════════════════
// 4. cancelTokenPaymentRequest
// ═══════════════════════════════════════════════════════════════════════════

export const cancelTokenPaymentRequest = onCall(async (request) => {
  const uid = request.auth?.uid;
  assertAuth(uid);

  const { requestId: rawRequestId } = (request.data ?? {}) as Record<string, unknown>;
  if (!rawRequestId || typeof rawRequestId !== "string") {
    throw new HttpsError("invalid-argument", "requestId is required");
  }
  const requestId = rawRequestId;
  const reqRef = db().collection("token_payment_requests").doc(requestId);

  let payerId: string | undefined;
  await db().runTransaction(async (txn) => {
    const reqSnap = await txn.get(reqRef);
    if (!reqSnap.exists) {
      throw new HttpsError("not-found", "REQUEST_NOT_FOUND");
    }
    const reqData = reqSnap.data()!;
    if (reqData.initiatorId !== uid) {
      throw new HttpsError("permission-denied", "FORBIDDEN");
    }
    if (reqData.status !== "pending") {
      if (reqData.status === "cancelled") {
        return; // idempotent
      }
      throw new HttpsError("failed-precondition", "REQUEST_NOT_PENDING");
    }
    payerId = reqData.payerId as string;
    const now = admin.firestore.FieldValue.serverTimestamp();
    txn.update(reqRef, {
      status: "cancelled",
      resolvedAt: now,
      updatedAt: now,
    });
  });

  if (payerId) {
    sendFcm(payerId, {
      type: "payment_request_cancelled",
      requestId,
    });
  }
  return { requestId, status: "cancelled" };
});

// ═══════════════════════════════════════════════════════════════════════════
// 5. expireTokenPaymentRequests (Scheduled — every hour)
// ═══════════════════════════════════════════════════════════════════════════

export const expireTokenPaymentRequests = onSchedule(
  { schedule: "every 60 minutes", region: "europe-west1" },
  async () => {
    const now = admin.firestore.Timestamp.now();
    const BATCH_SIZE = 400;

    let processed = 0;
    let hasMore = true;
    let lastDoc: admin.firestore.QueryDocumentSnapshot | undefined;

    while (hasMore) {
      let query = db()
        .collection("token_payment_requests")
        .where("status", "==", "pending")
        .where("expiresAt", "<", now)
        .orderBy("expiresAt", "asc")
        .limit(BATCH_SIZE);

      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const snap = await query.get();
      if (snap.empty) {
        hasMore = false;
        break;
      }

      const batch = db().batch();
      const serverNow = admin.firestore.FieldValue.serverTimestamp();
      for (const doc of snap.docs) {
        batch.update(doc.ref, {
          status: "expired",
          resolvedAt: serverNow,
          updatedAt: serverNow,
        });
      }
      await batch.commit();
      processed += snap.docs.length;
      lastDoc = snap.docs[snap.docs.length - 1];
      hasMore = snap.docs.length === BATCH_SIZE;
    }

    console.log(`expireTokenPaymentRequests: expired ${processed} requests`);
  }
);

/**
 * Nabour Cloud Functions — portofel tokeni, claim cartier, proxy Gemini.
 *
 * Deploy: firebase deploy --only functions
 * IAM build errors: vezi functions/DEPLOY.md și grant-build-permissions.sh
 *
 * Parametru (dev / până la integrare plăți):
 *   firebase functions:config:set wallet.allow_unverified="true"   (v1 config)
 * Sau în v2 params, după deploy:
 *   firebase functions:secrets:set GEMINI_API_KEY
 *
 * Param v2:
 *   firebase params:set ALLOW_UNVERIFIED_WALLET_CREDIT true
 * (sau din consola Firebase — Parameters)
 */
export {
  createTokenDirectTransfer,
  createTokenPaymentRequest,
  respondToTokenPaymentRequest,
  cancelTokenPaymentRequest,
  expireTokenPaymentRequests,
} from "./token_transfers";
import * as admin from "firebase-admin";
import * as functionsV1 from "firebase-functions/v1";
import { randomBytes } from "node:crypto";
import { latLngToCell } from "h3-js";
import { defineString } from "firebase-functions/params";
import { setGlobalOptions } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onDocumentCreated, onDocumentWritten } from "firebase-functions/v2/firestore";

admin.initializeApp();

setGlobalOptions({ region: "europe-west1" });

const PLAN_ALLOWANCE: Record<string, number> = {
  free: 1000,
  basic: 10000,
  pro: 50000,
  unlimited: 999999999,
};

function nextMonthFirst(d = new Date()): Date {
  return new Date(d.getFullYear(), d.getMonth() + 1, 1);
}

const STAFF_SUBSCRIPTION_EMAILS = defineString("STAFF_SUBSCRIPTION_EMAILS", {
  default: "operatii.777@gmail.com",
});

function isStaffSubscriptionEmail(email: string | undefined): boolean {
  if (!email) return false;
  const e = email.trim().toLowerCase();
  const list = STAFF_SUBSCRIPTION_EMAILS.value()
    .split(",")
    .map((s) => s.trim().toLowerCase())
    .filter(Boolean);
  return list.includes(e);
}

/** Aliniat cu lista din regulile Firestore + override prin `app_config/trial`. */
const TRIAL_EXEMPT_EMAILS_BUILTIN_CSV =
  "operatii.777@gmail.com,operatii.77@gmail.com,operatii.77777@gmail.com";

const TRIAL_DAYS_MS = 7 * 24 * 60 * 60 * 1000;

function parseTrialExemptBuiltinEmails(): string[] {
  return TRIAL_EXEMPT_EMAILS_BUILTIN_CSV.split(",")
    .map((s) => s.trim().toLowerCase())
    .filter(Boolean);
}

async function loadTrialExemptFromAppConfig(): Promise<{
  emails: string[];
  uids: string[];
}> {
  try {
    const snap = await admin.firestore().doc("app_config/trial").get();
    if (!snap.exists) return { emails: [], uids: [] };
    const d = snap.data() ?? {};
    const emails = ((d.exemptEmails as unknown[]) ?? [])
      .map((x) => String(x).trim().toLowerCase())
      .filter(Boolean);
    const uids = ((d.exemptUids as unknown[]) ?? [])
      .map((x) => String(x))
      .filter(Boolean);
    return { emails, uids };
  } catch {
    return { emails: [], uids: [] };
  }
}

async function isUserTrialExempt(user: admin.auth.UserRecord): Promise<boolean> {
  const emailNorm = user.email?.trim().toLowerCase();
  if (emailNorm && parseTrialExemptBuiltinEmails().includes(emailNorm)) {
    return true;
  }
  const cfg = await loadTrialExemptFromAppConfig();
  if (emailNorm && cfg.emails.includes(emailNorm)) return true;
  if (cfg.uids.includes(user.uid)) return true;
  return false;
}

async function writeUserTrialAnchor(user: admin.auth.UserRecord): Promise<void> {
  const uid = user.uid;
  const ref = admin.firestore().doc(`users/${uid}`);
  const exempt = await isUserTrialExempt(user);
  if (exempt) {
    await ref.set(
      {
        trialExempt: true,
        trialEndsAt: admin.firestore.Timestamp.fromDate(
          new Date("2099-12-31T23:59:59.000Z")
        ),
        trialAnchorSource: "cloud_function",
      },
      { merge: true }
    );
    return;
  }
  const createdMs = user.metadata.creationTime
    ? new Date(user.metadata.creationTime).getTime()
    : Date.now();
  const trialEnds = new Date(createdMs + TRIAL_DAYS_MS);
  await ref.set(
    {
      trialExempt: false,
      trialEndsAt: admin.firestore.Timestamp.fromDate(trialEnds),
      trialAnchorSource: "cloud_function",
    },
    { merge: true }
  );
}

/** Sincronizează `trialEndsAt` / `trialExempt` din metadata Auth (utilizatori existenți). */
export const nabourEnsureUserTrialAnchor = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Autentificare necesară.");
  }
  const uid = request.auth.uid;
  let user: admin.auth.UserRecord;
  try {
    user = await admin.auth().getUser(uid);
  } catch {
    throw new HttpsError("not-found", "Utilizator inexistent.");
  }
  const ref = admin.firestore().doc(`users/${uid}`);
  const snap = await ref.get();
  const d = snap.data();
  const anchored = Boolean(
    d &&
      d.trialEndsAt &&
      d.trialAnchorSource === "cloud_function"
  );
  if (anchored) {
    return { ok: true as const, skipped: true as const };
  }
  await writeUserTrialAnchor(user);
  return { ok: true as const, skipped: false as const };
});

export const nabourAuthOnUserCreate = functionsV1
  .region("europe-west1")
  .auth.user()
  .onCreate(async (user) => {
    try {
      await writeUserTrialAnchor(user);
    } catch (e) {
      console.error("nabourAuthOnUserCreate trial anchor failed", e);
    }
  });

/**
 * Indexare spațială H3 (Uber): același identificator ca pe client prin callable
 * (sursă unică de adevăr — fără grilă pătrată locală).
 * Rezoluția 6 ≈ 3,2 km latură medie hexagon (~echivalent vechiul pas ~5 km „conceptual”).
 * Viitor: rezoluție dinamică urban/rural prin param sau heuristică.
 */
const NABOUR_H3_RES = 6;

function neighborhoodCellFromLatLng(lat: number, lng: number): string {
  return latLngToCell(lat, lng, NABOUR_H3_RES);
}

// Implicit permisiv: gol / neluat în seamă = același lucru cu „true” (dev & Mystery Box etc.).
// Blochează explicit doar cu: false | 0 | no | off (ex. producție după integrare plăți).
// În producție: firebase params:set ALLOW_UNVERIFIED_WALLET_CREDIT false
const ALLOW_UNVERIFIED = defineString("ALLOW_UNVERIFIED_WALLET_CREDIT", { default: "true" });

function isWalletCreditFromAppAllowed(): boolean {
  const v = (ALLOW_UNVERIFIED.value() ?? "").trim().toLowerCase();
  if (v === "false" || v === "0" || v === "no" || v === "off") return false;
  return true;
}
const GEMINI_API_KEY = defineString("GEMINI_API_KEY", { default: "" });

/** Reset lunar server-side (înlocuiește scrierile client pe wallet). */
export const nabourMaintainTokenWallet = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Autentificare necesară.");
  }
  const uid = request.auth.uid;
  const ref = admin.firestore().doc(`users/${uid}/token_wallet/wallet`);
  const snap = await ref.get();
  if (!snap.exists) {
    return { ok: true, resetDue: false };
  }
  const d = snap.data()!;
  const plan = (d.plan as string) || "free";
  const resetAtTs = d.resetAt as admin.firestore.Timestamp | undefined;
  if (!resetAtTs) {
    return { ok: true, resetDue: false };
  }
  const resetAt = resetAtTs.toDate();
  if (new Date() < resetAt) {
    return { ok: true, resetDue: false };
  }

  const allowance = PLAN_ALLOWANCE[plan] ?? PLAN_ALLOWANCE.free;
  const now = new Date();
  const nextReset = nextMonthFirst(now);

  // Plan nelimitat: nu umplem soldul lunar cu 999M și nu inflăm totalEarned.
  if (plan === "unlimited") {
    await ref.update({
      resetAt: admin.firestore.Timestamp.fromDate(nextReset),
      lastResetAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await admin
      .firestore()
      .collection(`users/${uid}/token_transactions`)
      .add({
        uid,
        amount: 0,
        type: "monthly_reset",
        description: "Reset lunar — unlimited (cotă nelimitată, sold nemodificat)",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    return { ok: true, resetDue: true };
  }

  await ref.update({
    balance: allowance,
    totalEarned: admin.firestore.FieldValue.increment(allowance),
    resetAt: admin.firestore.Timestamp.fromDate(nextReset),
    lastResetAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await admin
    .firestore()
    .collection(`users/${uid}/token_transactions`)
    .add({
      uid,
      amount: allowance,
      type: "monthly_reset",
      description: `Reset lunar — ${plan} (${allowance} tokeni)`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

  return { ok: true, resetDue: true };
});

/**
 * Top-up / upgrade — DEZACTIVAT în producție până la verificare plată (IAP/webhook).
 * Setează parametrul ALLOW_UNVERIFIED_WALLET_CREDIT=true doar în dev/staging.
 */
/** Prețuri în TOKENI pentru achiziția manuală a planurilor (Transferable Tokens). */
const PLAN_TOKEN_PRICE: Record<string, number> = {
  basic: 1000,
  pro: 5000,
  unlimited: 15000,
};

/** Achiziție plan folosind soldul din portofelul TRANSFERABIL. */
export const nabourPurchasePlanWithTokens = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Autentificare necesară.");
  }
  const uid = request.auth.uid;
  const plan = String(request.data?.plan ?? "");
  const cost = PLAN_TOKEN_PRICE[plan];

  if (!cost) {
    throw new HttpsError("invalid-argument", "Plan invalid sau preț nedeclarat.");
  }

  const db = admin.firestore();
  const transferableWalletRef = db.doc(`token_wallets/${uid}`);
  const usageWalletRef = db.doc(`users/${uid}/token_wallet/wallet`);
  const ledgerRef = db.collection("token_ledger").doc();

  await db.runTransaction(async (txn) => {
    // 1. Verificăm soldul transferabil
    const tSnap = await txn.get(transferableWalletRef);
    if (!tSnap.exists || (tSnap.data()?.balanceMinor ?? 0) < cost) {
      throw new HttpsError(
        "failed-precondition",
        `Sold transferabil insuficient. Necesar: ${cost} tokeni.`
      );
    }

    // 2. Verificăm wallet-ul de utilizare
    const uSnap = await txn.get(usageWalletRef);
    if (!uSnap.exists) {
      throw new HttpsError("failed-precondition", "Wallet utilizare negăsit.");
    }

    const now = new Date();
    const nextReset = nextMonthFirst(now);

    // 3. Deducem din portofelul transferabil
    txn.update(transferableWalletRef, {
      balanceMinor: admin.firestore.FieldValue.increment(-cost),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      version: admin.firestore.FieldValue.increment(1),
    });

    // 4. Actualizăm planul de utilizare
    const allowance = PLAN_ALLOWANCE[plan] ?? 1000;
    txn.update(usageWalletRef, {
      plan: plan,
      balance: allowance, // Resetăm soldul la noua cotă imediat
      totalEarned: admin.firestore.FieldValue.increment(allowance),
      resetAt: admin.firestore.Timestamp.fromDate(nextReset),
      lastResetAt: admin.firestore.FieldValue.serverTimestamp(),
      autoRenew: false, // Dezactivăm reînnoirea automată (plată manuală)
    });

    // 5. Ledger entry pentru audit
    txn.set(ledgerRef, {
      userId: uid,
      deltaMinor: -cost,
      type: "plan_purchase",
      counterpartyUserId: "SYSTEM_SUBSCRIPTION",
      referenceType: "plan_upgrade",
      referenceId: plan,
      correlationGroupId: randomBytes(16).toString("hex"),
      balanceAfterMinor: (tSnap.data()?.balanceMinor ?? 0) - cost,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 6. Tranzacție în istoricul de utilizare
    const uTxRef = db.collection(`users/${uid}/token_transactions`).doc();
    txn.set(uTxRef, {
      uid,
      amount: allowance,
      type: "monthly_reset",
      description: `Activare plan ${plan} prin tokeni transferabili (-${cost} P2P)`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { ok: true, plan };
});

export const nabourWalletCredit = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Autentificare necesară.");
  }
  if (!isWalletCreditFromAppAllowed()) {
    throw new HttpsError(
      "failed-precondition",
      "Creditarea din app este blocată până la integrarea plăților."
    );
  }

  const uid = request.auth.uid;
  const action = request.data?.action as string;
  const isTransferable = Boolean(request.data?.isTransferable);
  const db = admin.firestore();

  if (action === "topup") {
    const amount = Number(request.data?.amount);
    if (!Number.isFinite(amount) || amount <= 0 || amount > 1000000) {
      throw new HttpsError("invalid-argument", "Sumă invalidă.");
    }
    const description = String(request.data?.description ?? "Cumpărare tokeni");

    if (isTransferable) {
      // ── Credit portofel TRANSFERABIL ──
      const walletRef = db.doc(`token_wallets/${uid}`);
      const ledgerRef = db.collection("token_ledger").doc();
      const correlationGroupId = randomBytes(16).toString("hex");

      await db.runTransaction(async (txn) => {
        const snap = await txn.get(walletRef);
        const now = admin.firestore.FieldValue.serverTimestamp();
        let balanceAfter = amount;

        if (!snap.exists) {
          txn.set(walletRef, {
            balanceMinor: amount,
            status: "active",
            createdAt: now,
            updatedAt: now,
            version: 1,
            autoProvisioned: true,
          });
        } else {
          balanceAfter = (snap.data()?.balanceMinor ?? 0) + amount;
          txn.update(walletRef, {
            balanceMinor: admin.firestore.FieldValue.increment(amount),
            updatedAt: now,
            version: admin.firestore.FieldValue.increment(1),
          });
        }

        // Ledger entry (credit tip 'topup_transferable')
        txn.set(ledgerRef, {
          userId: uid,
          deltaMinor: amount,
          type: "topup_credit",
          counterpartyUserId: "SYSTEM_SHOP",
          referenceType: "direct_topup",
          referenceId: "SHOP_" + Date.now(),
          correlationGroupId,
          balanceAfterMinor: balanceAfter,
          createdAt: now,
        });
      });
    } else {
      // ── Credit portofel USAGE (abonament) ──
      const ref = db.doc(`users/${uid}/token_wallet/wallet`);
      await ref.update({
        balance: admin.firestore.FieldValue.increment(amount),
        totalEarned: admin.firestore.FieldValue.increment(amount),
      });
      await db.collection(`users/${uid}/token_transactions`).add({
        uid,
        amount,
        type: "purchase",
        description,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    return { ok: true, isTransferable };
  }

  if (action === "upgrade") {
    const plan = String(request.data?.plan ?? "");
    if (!PLAN_ALLOWANCE[plan]) {
      throw new HttpsError("invalid-argument", "Plan invalid.");
    }
    const ref = db.doc(`users/${uid}/token_wallet/wallet`);
    const w = await ref.get();
    if (!w.exists) {
      throw new HttpsError("failed-precondition", "Wallet inexistent.");
    }
    const newAllowance = PLAN_ALLOWANCE[plan];

    if (plan === "unlimited") {
      await ref.update({
        plan: "unlimited",
        freeMonthlyAllowance: newAllowance,
      });
      await db.collection(`users/${uid}/token_transactions`).add({
        uid,
        amount: 0,
        type: "purchase",
        description: "Upgrade la unlimited (fără bonus numeric — plan nelimitat)",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return { ok: true };
    }

    const oldPlan = (w.data()!.plan as string) || "free";
    const oldAllowance = PLAN_ALLOWANCE[oldPlan] ?? PLAN_ALLOWANCE.free;
    const bonus = Math.max(0, Math.min(newAllowance - oldAllowance, newAllowance));

    const updates: Record<string, unknown> = {
      plan,
      freeMonthlyAllowance: newAllowance,
    };
    if (bonus > 0) {
      updates.balance = admin.firestore.FieldValue.increment(bonus);
      updates.totalEarned = admin.firestore.FieldValue.increment(bonus);
    }
    await ref.update(updates as Record<string, unknown>);

    if (bonus > 0) {
      await db.collection(`users/${uid}/token_transactions`).add({
        uid,
        amount: bonus,
        type: "purchase",
        description: `Upgrade la ${plan} (+${bonus} tokeni)`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    return { ok: true };
  }

  throw new HttpsError("invalid-argument", "Acțiune necunoscută.");
});

const MYSTERY_BOX_REWARD = 50;

/** Cod scurt afișat clientului / în QR; fără 0,O,1,I ca să fie ușor de citit la casă. */
function generateMysteryRedemptionCode(): string {
  const alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  const buf = randomBytes(12);
  let out = "";
  for (let i = 0; i < 8; i++) {
    out += alphabet[buf[i]! % alphabet.length];
  }
  return out;
}

function normalizeMysteryRedemptionCode(raw: string): string {
  return String(raw ?? "")
    .trim()
    .toUpperCase()
    .replace(/[\s\-_]/g, "");
}

type MysteryClaimTxFail = {
  ok: false;
  code:
    | "no_offer"
    | "inactive"
    | "already"
    | "soldout"
    | "no_wallet"
    | "no_redemption_code";
};

type MysteryClaimTxOk = {
  ok: true;
  remaining: number | null;
  total: number | null;
  claimed: number;
  redemptionCode: string;
};

/**
 * Mystery Box: o deschidere/zi per businessId, plafon pe ofertă (mysteryBoxTotal), +tokeni în același transaction.
 */
export const nabourMysteryBoxClaim = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Autentificare necesară.");
  }
  if (!isWalletCreditFromAppAllowed()) {
    throw new HttpsError(
      "failed-precondition",
      "Creditarea din app este blocată până la integrarea plăților."
    );
  }

  const offerId = String(request.data?.offerId ?? "").trim();
  if (!offerId) {
    throw new HttpsError("invalid-argument", "offerId lipsă.");
  }

  const uid = request.auth.uid;
  const db = admin.firestore();
  const now = new Date();
  const y = now.getFullYear();
  const m = now.getMonth() + 1;
  const dNow = now.getDate();

  const result = await db.runTransaction(
    async (
      tx
    ): Promise<MysteryClaimTxOk | MysteryClaimTxFail> => {
      const offerRef = db.doc(`business_offers/${offerId}`);
      const offerSnap = await tx.get(offerRef);
      if (!offerSnap.exists) {
        return { ok: false, code: "no_offer" };
      }
      const o = offerSnap.data()!;
      if (o.isActive === false) {
        return { ok: false, code: "inactive" };
      }

      const businessId = String(o.businessId ?? "");
      if (!businessId) {
        return { ok: false, code: "no_offer" };
      }

      const openedDocId = `${businessId}_${y}_${m}_${dNow}`;
      const openedRef = db.doc(
        `users/${uid}/opened_mystery_boxes/${openedDocId}`
      );
      const openedSnap = await tx.get(openedRef);
      if (openedSnap.exists) {
        return { ok: false, code: "already" };
      }

      const totalRaw = o.mysteryBoxTotal;
      const totalCap =
        typeof totalRaw === "number" && totalRaw > 0
          ? Math.floor(totalRaw)
          : 0;
      const claimed =
        typeof o.mysteryBoxClaimed === "number"
          ? Math.floor(o.mysteryBoxClaimed)
          : 0;

      if (totalCap > 0 && claimed >= totalCap) {
        return { ok: false, code: "soldout" };
      }

      const walletRef = db.doc(`users/${uid}/token_wallet/wallet`);
      const walletSnap = await tx.get(walletRef);
      if (!walletSnap.exists) {
        return { ok: false, code: "no_wallet" };
      }

      let redemptionCode = "";
      for (let attempt = 0; attempt < 24; attempt++) {
        const cand = generateMysteryRedemptionCode();
        const rRef = db.doc(`mystery_box_redemptions/${cand}`);
        const rSnap = await tx.get(rRef);
        if (!rSnap.exists) {
          redemptionCode = cand;
          break;
        }
      }
      if (!redemptionCode) {
        return { ok: false, code: "no_redemption_code" };
      }

      const expiresAt = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
      const redemptionRef = db.doc(
        `mystery_box_redemptions/${redemptionCode}`
      );

      tx.update(offerRef, {
        mysteryBoxClaimed: admin.firestore.FieldValue.increment(1),
      });

      tx.set(openedRef, {
        businessId,
        businessName: String(o.businessName ?? ""),
        offerId,
        redemptionCode,
        openedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.update(walletRef, {
        balance: admin.firestore.FieldValue.increment(MYSTERY_BOX_REWARD),
        totalEarned: admin.firestore.FieldValue.increment(MYSTERY_BOX_REWARD),
      });

      const txnRef = db.collection(`users/${uid}/token_transactions`).doc();
      tx.set(txnRef, {
        uid,
        amount: MYSTERY_BOX_REWARD,
        type: "purchase",
        description: `Mystery Box: ${String(o.businessName ?? "")}`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      tx.set(redemptionRef, {
        code: redemptionCode,
        offerId,
        businessId,
        userId: uid,
        businessName: String(o.businessName ?? ""),
        offerTitle: String(o.title ?? ""),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
      });

      const newClaimed = claimed + 1;
      const remaining = totalCap > 0 ? totalCap - newClaimed : null;
      return {
        ok: true,
        remaining,
        total: totalCap > 0 ? totalCap : null,
        claimed: newClaimed,
        redemptionCode,
      };
    }
  );

  if (!result.ok) {
    switch (result.code) {
      case "no_offer":
        throw new HttpsError("not-found", "Oferta nu mai există.");
      case "inactive":
        throw new HttpsError(
          "failed-precondition",
          "Oferta nu mai este activă."
        );
      case "already":
        throw new HttpsError(
          "already-exists",
          "Ai deschis deja o cutie azi la acest magazin."
        );
      case "soldout":
        throw new HttpsError(
          "resource-exhausted",
          "Toate cutiile pentru această ofertă au fost deja deschise."
        );
      case "no_wallet":
        throw new HttpsError("failed-precondition", "Wallet inexistent.");
      case "no_redemption_code":
        throw new HttpsError(
          "resource-exhausted",
          "Nu am putut genera codul de reducere. Încearcă din nou."
        );
      default:
        throw new HttpsError("internal", "Eroare la deschiderea cutiei.");
    }
  }

  return result;
});

/**
 * Comerciant: validează codul Mystery Box (tastat sau scanat din QR). Marchează codul ca folosit.
 */
export const nabourMysteryBoxMerchantValidate = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Autentificare necesară.");
  }

  const code = normalizeMysteryRedemptionCode(
    String(request.data?.code ?? "")
  );
  if (code.length < 6) {
    throw new HttpsError("invalid-argument", "Cod invalid.");
  }

  const merchantUid = request.auth.uid;
  const db = admin.firestore();

  const bizSnap = await db
    .collection("business_profiles")
    .where("userId", "==", merchantUid)
    .limit(1)
    .get();
  if (bizSnap.empty) {
    throw new HttpsError(
      "permission-denied",
      "Doar conturile cu profil business pot valida coduri."
    );
  }
  const businessId = bizSnap.docs[0].id;

  const ref = db.doc(`mystery_box_redemptions/${code}`);

  type TxOut =
    | { kind: "ok"; offerTitle: string; offerId: string }
    | { kind: "not_found" }
    | { kind: "wrong_business" }
    | { kind: "already" }
    | { kind: "expired" };

  const out = await db.runTransaction(async (tx): Promise<TxOut> => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      return { kind: "not_found" };
    }
    const d = snap.data()!;
    if (String(d.businessId ?? "") !== businessId) {
      return { kind: "wrong_business" };
    }
    if (d.consumedAt != null) {
      return { kind: "already" };
    }
    const exp = d.expiresAt as admin.firestore.Timestamp | undefined;
    if (exp != null && exp.toMillis() < Date.now()) {
      return { kind: "expired" };
    }
    tx.update(ref, {
      consumedAt: admin.firestore.FieldValue.serverTimestamp(),
      consumedByUid: merchantUid,
    });
    return {
      kind: "ok",
      offerTitle: String(d.offerTitle ?? ""),
      offerId: String(d.offerId ?? ""),
    };
  });

  if (out.kind === "not_found") {
    throw new HttpsError("not-found", "Codul nu există.");
  }
  if (out.kind === "wrong_business") {
    throw new HttpsError(
      "permission-denied",
      "Acest cod nu aparține locației tale."
    );
  }
  if (out.kind === "already") {
    throw new HttpsError("already-exists", "Codul a fost deja folosit.");
  }
  if (out.kind === "expired") {
    throw new HttpsError("failed-precondition", "Codul a expirat.");
  }
  return {
    ok: true,
    offerTitle: out.offerTitle,
    offerId: out.offerId,
  };
});

// ── Mystery Box comunitar (orice user, după locație) ─────────────────────────

const COMMUNITY_MYSTERY_STAKE = 50;
const COMMUNITY_MYSTERY_MAX_ACTIVE_PER_USER = 20;
const COMMUNITY_MYSTERY_LIST_LIMIT = 400;
const COMMUNITY_MYSTERY_NEARBY_MAX_KM = 8;
const CLAIM_PROXIMITY_KM_COMMUNITY = 0.1;

function haversineKm(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number
): number {
  const R = 6371;
  const r1 = (lat1 * Math.PI) / 180;
  const r2 = (lat2 * Math.PI) / 180;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(r1) * Math.cos(r2) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

async function sendCommunityMysteryFcm(
  userId: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<void> {
  const userDoc = await admin.firestore().doc(`users/${userId}`).get();
  const token = userDoc.data()?.fcmToken as string | undefined;
  if (!token) {
    return;
  }
  try {
    await admin.messaging().send({
      token,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
      android: { priority: "high" },
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
    });
  } catch (e) {
    console.error("[FCM] community_mystery", e);
  }
}

/** Plasează o cutie comunitară: plătitorul „blochează” [COMMUNITY_MYSTERY_STAKE] tokeni. */
export const nabourCommunityMysteryBoxPlace = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Autentificare necesară.");
  }
  const uid = request.auth.uid;
  const lat = request.data?.lat;
  const lng = request.data?.lng;
  if (typeof lat !== "number" || typeof lng !== "number") {
    throw new HttpsError("invalid-argument", "lat/lng lipsesc.");
  }
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    throw new HttpsError("invalid-argument", "Coordonate invalide.");
  }
  const messageRaw = String(request.data?.message ?? "").trim();
  const message =
    messageRaw.length > 120 ? messageRaw.slice(0, 120) : messageRaw;

  const db = admin.firestore();

  const activeSnap = await db
    .collection("community_mystery_boxes")
    .where("placerUid", "==", uid)
    .where("status", "==", "active")
    .get();
  if (activeSnap.size >= COMMUNITY_MYSTERY_MAX_ACTIVE_PER_USER) {
    throw new HttpsError(
      "resource-exhausted",
      `Ai deja ${COMMUNITY_MYSTERY_MAX_ACTIVE_PER_USER} cutii active. Deschide-le sau așteaptă să expire (dacă adăugăm expirare).`
    );
  }

  const walletRef = db.doc(`users/${uid}/token_wallet/wallet`);
  const boxRef = db.collection("community_mystery_boxes").doc();

  await db.runTransaction(async (tx) => {
    const wSnap = await tx.get(walletRef);
    if (!wSnap.exists) {
      throw new HttpsError("failed-precondition", "Wallet inexistent.");
    }
    const w = wSnap.data()!;
    const plan = String(w.plan ?? "free");
    const balance = Math.floor(Number(w.balance ?? 0));
    if (plan !== "unlimited" && balance < COMMUNITY_MYSTERY_STAKE) {
      throw new HttpsError(
        "failed-precondition",
        `Ai nevoie de ${COMMUNITY_MYSTERY_STAKE} tokeni pentru a plasa cutia.`
      );
    }
    if (plan === "unlimited") {
      tx.update(walletRef, {
        totalSpent: admin.firestore.FieldValue.increment(COMMUNITY_MYSTERY_STAKE),
      });
    } else {
      tx.update(walletRef, {
        balance: admin.firestore.FieldValue.increment(-COMMUNITY_MYSTERY_STAKE),
        totalSpent: admin.firestore.FieldValue.increment(COMMUNITY_MYSTERY_STAKE),
      });
    }
    const tRef = db.collection(`users/${uid}/token_transactions`).doc();
    tx.set(tRef, {
      uid,
      amount: -COMMUNITY_MYSTERY_STAKE,
      type: "purchase",
      description: "Plasare Mystery Box comunitar",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.set(boxRef, {
      placerUid: uid,
      message,
      latitude: lat,
      longitude: lng,
      geoCell: neighborhoodCellFromLatLng(lat, lng),
      rewardTokens: COMMUNITY_MYSTERY_STAKE,
      status: "active",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { ok: true, boxId: boxRef.id };
});

/** Cutii active în rază (server filtrează după distanță). */
export const nabourCommunityMysteryBoxesNearby = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Autentificare necesară.");
  }
  const lat = request.data?.lat;
  const lng = request.data?.lng;
  const radiusKm = Math.min(
    25,
    Math.max(0.5, Number(request.data?.radiusKm ?? 5))
  );
  if (typeof lat !== "number" || typeof lng !== "number") {
    throw new HttpsError("invalid-argument", "lat/lng lipsesc.");
  }

  const db = admin.firestore();
  const snap = await db
    .collection("community_mystery_boxes")
    .where("status", "==", "active")
    .limit(COMMUNITY_MYSTERY_LIST_LIMIT)
    .get();

  const out: Array<Record<string, unknown>> = [];
  for (const doc of snap.docs) {
    const d = doc.data();
    const plat = Number(d.latitude ?? 0);
    const plng = Number(d.longitude ?? 0);
    const dist = haversineKm(lat, lng, plat, plng);
    if (dist <= Math.min(radiusKm, COMMUNITY_MYSTERY_NEARBY_MAX_KM)) {
      out.push({
        id: doc.id,
        latitude: plat,
        longitude: plng,
        message: String(d.message ?? ""),
        placerUid: String(d.placerUid ?? ""),
        rewardTokens: Math.floor(Number(d.rewardTokens ?? COMMUNITY_MYSTERY_STAKE)),
      });
    }
  }
  out.sort((a, b) => {
    const da = haversineKm(
      lat,
      lng,
      Number(a.latitude),
      Number(a.longitude)
    );
    const db_ = haversineKm(
      lat,
      lng,
      Number(b.latitude),
      Number(b.longitude)
    );
    return da - db_;
  });

  return { ok: true, boxes: out.slice(0, 100) };
});

/** Deschide cutia comunitară: verificare distanță, un deschizător, +tokeni pentru deschizător, notificare plasator. */
export const nabourCommunityMysteryBoxClaim = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Autentificare necesară.");
  }
  if (!isWalletCreditFromAppAllowed()) {
    throw new HttpsError(
      "failed-precondition",
      "Creditarea din app este blocată până la integrarea plăților."
    );
  }

  const uid = request.auth.uid;
  const boxId = String(request.data?.boxId ?? "").trim();
  const claimLat = request.data?.claimLat;
  const claimLng = request.data?.claimLng;
  if (!boxId) {
    throw new HttpsError("invalid-argument", "boxId lipsă.");
  }
  if (typeof claimLat !== "number" || typeof claimLng !== "number") {
    throw new HttpsError("invalid-argument", "claimLat/claimLng lipsesc.");
  }

  const db = admin.firestore();
  const boxRef = db.doc(`community_mystery_boxes/${boxId}`);

  type TxR =
    | { ok: true; placerUid: string; reward: number }
    | { ok: false; reason: string };

  const txResult = await db.runTransaction(async (tx): Promise<TxR> => {
    const bSnap = await tx.get(boxRef);
    if (!bSnap.exists) {
      return { ok: false, reason: "missing" };
    }
    const b = bSnap.data()!;
    if (String(b.status ?? "") !== "active") {
      return { ok: false, reason: "gone" };
    }
    const placer = String(b.placerUid ?? "");
    if (!placer || placer === uid) {
      return { ok: false, reason: "own" };
    }
    const plat = Number(b.latitude ?? 0);
    const plng = Number(b.longitude ?? 0);
    if (haversineKm(claimLat, claimLng, plat, plng) > CLAIM_PROXIMITY_KM_COMMUNITY) {
      return { ok: false, reason: "far" };
    }
    const reward = Math.floor(
      Number(b.rewardTokens ?? COMMUNITY_MYSTERY_STAKE)
    );
    const walletRef = db.doc(`users/${uid}/token_wallet/wallet`);
    const wSnap = await tx.get(walletRef);
    if (!wSnap.exists) {
      return { ok: false, reason: "no_wallet" };
    }
    tx.update(boxRef, {
      status: "claimed",
      claimedByUid: uid,
      claimedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.update(walletRef, {
      balance: admin.firestore.FieldValue.increment(reward),
      totalEarned: admin.firestore.FieldValue.increment(reward),
    });
    const txnRef = db.collection(`users/${uid}/token_transactions`).doc();
    tx.set(txnRef, {
      uid,
      amount: reward,
      type: "purchase",
      description: `Mystery Box comunitar (${boxId.slice(0, 8)}…)`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    const notifRef = db
      .collection(`users/${placer}/community_mystery_notifications`)
      .doc();
    tx.set(notifRef, {
      type: "opened",
      boxId,
      openerUid: uid,
      rewardTokens: reward,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { ok: true, placerUid: placer, reward };
  });

  if (!txResult.ok) {
    switch (txResult.reason) {
      case "missing":
        throw new HttpsError("not-found", "Cutia nu mai există.");
      case "gone":
        throw new HttpsError(
          "failed-precondition",
          "Cutia a fost deja deschisă."
        );
      case "own":
        throw new HttpsError(
          "invalid-argument",
          "Nu poți deschide propria cutie comunitară."
        );
      case "far":
        throw new HttpsError(
          "failed-precondition",
          "Ești prea departe de cutie (max. ~100 m)."
        );
      case "no_wallet":
        throw new HttpsError("failed-precondition", "Wallet inexistent.");
      default:
        throw new HttpsError("internal", "Eroare la deschidere.");
    }
  }

  const placerUid = txResult.placerUid;
  await sendCommunityMysteryFcm(
    placerUid,
    "Mystery Box comunitar deschis!",
    "Cineva tocmai a deschis una dintre cutiile tale plasate pe hartă.",
    {
      type: "community_mystery_opened",
      boxId,
      openerUid: uid,
    }
  );

  return { ok: true, reward: txResult.reward };
});

/** Retrage o cutie comunitară încă activă: rambursare garanție, status cancelled. */
export const nabourCommunityMysteryBoxRemove = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Autentificare necesară.");
  }
  const uid = request.auth.uid;
  const boxId = String(request.data?.boxId ?? "").trim();
  if (!boxId) {
    throw new HttpsError("invalid-argument", "boxId lipsă.");
  }
  const db = admin.firestore();
  const boxRef = db.doc(`community_mystery_boxes/${boxId}`);

  await db.runTransaction(async (tx) => {
    const bSnap = await tx.get(boxRef);
    if (!bSnap.exists) {
      throw new HttpsError("not-found", "Cutia nu există.");
    }
    const b = bSnap.data()!;
    if (String(b.placerUid ?? "") !== uid) {
      throw new HttpsError("permission-denied", "Nu poți retrage cutiile altcuiva.");
    }
    if (String(b.status ?? "") !== "active") {
      throw new HttpsError(
        "failed-precondition",
        "Poți retrage doar cutiile încă nedeschise."
      );
    }
    const walletRef = db.doc(`users/${uid}/token_wallet/wallet`);
    const wSnap = await tx.get(walletRef);
    if (!wSnap.exists) {
      throw new HttpsError("failed-precondition", "Wallet inexistent.");
    }
    const w = wSnap.data()!;
    const plan = String(w.plan ?? "free");
    const stake = COMMUNITY_MYSTERY_STAKE;
    if (plan === "unlimited") {
      tx.update(walletRef, {
        totalSpent: admin.firestore.FieldValue.increment(-stake),
      });
    } else {
      tx.update(walletRef, {
        balance: admin.firestore.FieldValue.increment(stake),
        totalSpent: admin.firestore.FieldValue.increment(-stake),
      });
    }
    const tRef = db.collection(`users/${uid}/token_transactions`).doc();
    tx.set(tRef, {
      uid,
      amount: stake,
      type: "purchase",
      description: "Retragere cutie comunitară (rambursare garanție)",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.update(boxRef, {
      status: "cancelled",
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      cancelledByUid: uid,
    });
  });

  return { ok: true };
});

/** Retrage toate cutiile comunitare active ale utilizatorului (aceeași logică ca la una singură). */
export const nabourCommunityMysteryBoxRemoveAllActive = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Autentificare necesară.");
  }
  const uid = request.auth.uid;
  const db = admin.firestore();
  const snap = await db
    .collection("community_mystery_boxes")
    .where("placerUid", "==", uid)
    .where("status", "==", "active")
    .get();

  let removed = 0;
  for (const doc of snap.docs) {
    const boxRef = doc.ref;
    await db.runTransaction(async (tx) => {
      const bSnap = await tx.get(boxRef);
      if (!bSnap.exists) {
        return;
      }
      const b = bSnap.data()!;
      if (String(b.placerUid ?? "") !== uid) {
        return;
      }
      if (String(b.status ?? "") !== "active") {
        return;
      }
      const walletRef = db.doc(`users/${uid}/token_wallet/wallet`);
      const wSnap = await tx.get(walletRef);
      if (!wSnap.exists) {
        throw new HttpsError("failed-precondition", "Wallet inexistent.");
      }
      const w = wSnap.data()!;
      const plan = String(w.plan ?? "free");
      const stake = COMMUNITY_MYSTERY_STAKE;
      if (plan === "unlimited") {
        tx.update(walletRef, {
          totalSpent: admin.firestore.FieldValue.increment(-stake),
        });
      } else {
        tx.update(walletRef, {
          balance: admin.firestore.FieldValue.increment(stake),
          totalSpent: admin.firestore.FieldValue.increment(-stake),
        });
      }
      const tRef = db.collection(`users/${uid}/token_transactions`).doc();
      tx.set(tRef, {
        uid,
        amount: stake,
        type: "purchase",
        description: "Retragere cutie comunitară (rambursare garanție)",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      tx.update(boxRef, {
        status: "cancelled",
        cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        cancelledByUid: uid,
      });
    });
    removed += 1;
  }

  return { ok: true, removed };
});

/**
 * Aplică un abonament pe propriul wallet (free / basic / pro / unlimited).
 * Doar adresele din parametrul STAFF_SUBSCRIPTION_EMAILS (implicit operatii.777@gmail.com).
 * Firebase Console → Functions → Parameters: STAFF_SUBSCRIPTION_EMAILS = "a@x.com,b@y.com"
 */
export const nabourStaffApplySubscription = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Autentificare necesară.");
  }
  const email = request.auth.token.email as string | undefined;
  if (!isStaffSubscriptionEmail(email)) {
    throw new HttpsError(
      "permission-denied",
      "Doar conturi staff pot aplica acest abonament."
    );
  }

  const plan = String(request.data?.plan ?? "");
  if (!PLAN_ALLOWANCE[plan]) {
    throw new HttpsError("invalid-argument", "Plan invalid.");
  }

  const uid = request.auth.uid;
  const allowance = PLAN_ALLOWANCE[plan];
  const ref = admin.firestore().doc(`users/${uid}/token_wallet/wallet`);
  const snap = await ref.get();
  const nextReset = admin.firestore.Timestamp.fromDate(nextMonthFirst());

  if (!snap.exists) {
    await ref.set({
      balance: plan === "unlimited" ? 0 : allowance,
      totalEarned: plan === "unlimited" ? 0 : allowance,
      totalSpent: 0,
      plan,
      freeMonthlyAllowance: allowance,
      resetAt: nextReset,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await admin.firestore().collection(`users/${uid}/token_transactions`).add({
      uid,
      amount: plan === "unlimited" ? 0 : allowance,
      type: "bonus",
      description: `Wallet inițial staff — ${plan}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { ok: true, created: true };
  }

  if (plan === "unlimited") {
    await ref.set(
      {
        plan: "unlimited",
        freeMonthlyAllowance: allowance,
      },
      { merge: true }
    );
  } else {
    const curBal = Number(snap.data()?.balance ?? 0);
    const topUp = Math.max(0, allowance - curBal);
    const patch: Record<string, unknown> = {
      plan,
      freeMonthlyAllowance: allowance,
    };
    if (topUp > 0) {
      patch.balance = admin.firestore.FieldValue.increment(topUp);
      patch.totalEarned = admin.firestore.FieldValue.increment(topUp);
    }
    await ref.set(patch, { merge: true });
    if (topUp > 0) {
      await admin.firestore().collection(`users/${uid}/token_transactions`).add({
        uid,
        amount: topUp,
        type: "bonus",
        description: `Staff: aliniere sold la ${plan} (+${topUp})`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }

  await admin.firestore().collection(`users/${uid}/token_transactions`).add({
    uid,
    amount: 0,
    type: "admin_adjust",
    description: `Staff: abonament setat la ${plan}`,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { ok: true };
});

/**
 * Setează claim-ul `nb_room` la indexul H3 al locației (string celulă, ex. "8928308280fffff").
 * Clientul trebuie să folosească același `roomId` returnat aici pentru Firestore + FCM.
 */
export const nabourSyncNeighborhoodRoom = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Autentificare necesară.");
  }
  const lat = request.data?.lat;
  const lng = request.data?.lng;
  if (typeof lat !== "number" || typeof lng !== "number") {
    throw new HttpsError("invalid-argument", "lat/lng lipsesc sau nu sunt numerice.");
  }
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    throw new HttpsError("invalid-argument", "Coordonate în afara domeniului.");
  }
  const room = neighborhoodCellFromLatLng(lat, lng);
  const user = await admin.auth().getUser(request.auth.uid);
  const prev = (user.customClaims ?? {}) as Record<string, unknown>;
  await admin.auth().setCustomUserClaims(request.auth.uid, {
    ...prev,
    nb_room: room,
  });
  return { roomId: room, h3Resolution: NABOUR_H3_RES };
});

/**
 * Mesaj text trimis vecinilor selectați în radar (notificări push FCM per destinatar).
 */
export const nabourSendRadarGroupMessage = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Autentificare necesară.");
  }
  const senderUid = request.auth.uid;
  const rawRecipients = request.data?.recipientUids;
  const messageRaw = String(request.data?.message ?? "").trim();
  if (!Array.isArray(rawRecipients)) {
    throw new HttpsError("invalid-argument", "recipientUids invalid.");
  }
  if (messageRaw.length < 1 || messageRaw.length > 500) {
    throw new HttpsError(
      "invalid-argument",
      "Mesajul trebuie să aibă între 1 și 500 caractere."
    );
  }
  const maxRecipients = 50;
  const recipientSet = new Set<string>();
  for (const u of rawRecipients) {
    if (typeof u !== "string" || u.length < 3) continue;
    if (u === senderUid) continue;
    recipientSet.add(u);
  }
  if (recipientSet.size === 0) {
    throw new HttpsError("invalid-argument", "Niciun destinatar valid.");
  }
  if (recipientSet.size > maxRecipients) {
    throw new HttpsError(
      "invalid-argument",
      `Maximum ${maxRecipients} destinatari odată.`
    );
  }
  const db = admin.firestore();
  const senderDoc = await db.doc(`users/${senderUid}`).get();
  const senderName = String(senderDoc.data()?.displayName ?? "Un vecin");
  const senderAvatar = String(senderDoc.data()?.avatar ?? "🙂");

  const bodyShort =
    messageRaw.length > 120 ? messageRaw.slice(0, 120) + "…" : messageRaw;
  let sent = 0;
  const recipients = [...recipientSet];

  for (const uid of recipients) {
    const userDoc = await db.doc(`users/${uid}`).get();
    const token = userDoc.data()?.fcmToken as string | undefined;
    if (!token) continue;
    try {
      await admin.messaging().send({
        token,
        notification: {
          title: `Mesaj radar de la ${senderName}`,
          body: bodyShort,
        },
        data: {
          type: "radar_group_message",
          senderUid,
          senderName,
          senderAvatar,
          message: messageRaw.slice(0, 500),
        },
        android: { priority: "high" },
        apns: { payload: { aps: { sound: "default" } } },
      });
      sent++;
    } catch (e) {
      console.error("[FCM] radar_group", uid, e);
    }
  }

  try {
    await db.collection("radar_group_broadcasts").add({
      senderUid,
      recipientCount: recipients.length,
      fcmDelivered: sent,
      messagePreview: messageRaw.slice(0, 80),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (e) {
    console.error("[radar_group_broadcasts] audit", e);
  }

  return { ok: true, attempted: recipients.length, sent };
});

/** Proxy Gemini — cheia rămâne pe server. Setează parametrul GEMINI_API_KEY în Firebase. */
export const nabourGeminiProxy = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Autentificare necesară.");
  }
  const apiKey = GEMINI_API_KEY.value();
  if (!apiKey) {
    throw new HttpsError(
      "failed-precondition",
      "GEMINI_API_KEY nu e setat pe Functions. Configurează parametrul în Firebase Console."
    );
  }
  const prompt = String(request.data?.prompt ?? "");
  if (prompt.length < 1 || prompt.length > 14000) {
    throw new HttpsError("invalid-argument", "Prompt invalid.");
  }

  const url =
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=" +
    encodeURIComponent(apiKey);

  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
    }),
  });

  const body = (await res.json()) as Record<string, unknown>;
  if (!res.ok) {
    throw new HttpsError(
      "internal",
      `Gemini HTTP ${res.status}: ${JSON.stringify(body).slice(0, 500)}`
    );
  }

  try {
    const candidates = body.candidates as Array<Record<string, unknown>>;
    const content = candidates[0]?.content as Record<string, unknown> | undefined;
    const parts = content?.parts as Array<Record<string, unknown>> | undefined;
    const text = String(parts?.[0]?.text ?? "");
    return { text };
  } catch {
    throw new HttpsError("internal", "Răspuns Gemini neașteptat.");
  }
});

/** La fiecare zonă nouă Explorări, incrementăm contorul public pe profil (clasament prieteni). */
export const nabourOnScratchTileCreated = onDocumentCreated(
  "users/{userId}/scratch_map_tiles/{tileId}",
  async (event) => {
    const uid = event.params.userId;
    await admin.firestore().doc(`users/${uid}`).set(
      {
        scratchTileCount: admin.firestore.FieldValue.increment(1),
        scratchTilesUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }
);

/** Dacă profilul marchează ghostMode, ascundem imediat punctul din Firestore vizibil (apărare în adâncime). */
export const nabourStripVisibleWhenGhost = onDocumentWritten(
  "users/{userId}",
  async (event) => {
    const after = event.data?.after?.data();
    if (after?.ghostMode !== true) {
      return;
    }
    const userId = event.params.userId;
    await admin.firestore().doc(`user_visible_locations/${userId}`).set(
      { isVisible: false },
      { merge: true }
    );
  }
);

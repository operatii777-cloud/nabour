# Plan: transfer și solicitare tokeni între utilizatori

Document complet de referință (fișier unic în repo): produs, Firestore, Cloud Functions, reguli, indexuri, client Flutter, notificări, teste.

---

## 1. Rezumat executiv

| Flux | Nume tehnic | Acceptare de la celălalt? | Când se mută soldul |
|------|-------------|---------------------------|---------------------|
| Trimitere tokeni către alt user | **transfer direct** — colecție `token_direct_transfers` | **Nu** | Imediat după confirmarea expeditorului (tranzacție atomică) |
| Solicitare tokeni de la alt user | **cerere de plată** — colecție `token_payment_requests` | **Da**, doar **plătitorul** (`payerId`) apasă Accept | La **Accept** de către plătitor |

**Sold:** sursa adevărului = `token_wallets/{userId}`. Balanța se modifică **numai** din backend (Functions + Admin SDK), nu din client.

---

## 2. Principii tehnice

1. **Atomicitate:** debit + credit (+ update cerere dacă e cazul) + intrări ledger în același flux tranzacțional când e posibil în limitele Firestore (max ~500 writes / tranzacție; aici 3–4 documente tipic).
2. **Idempotency:** pentru transfer direct, `clientRequestId` unic per încercare client; pentru accept cerere, citire `status == pending` în tranzacție înainte de debit.
3. **Separare colecții:** transferuri imediate vs cereri — reguli și query-uri mai clare.
4. **Audit:** `token_ledger` append-only; fiecare mișcare legată de `referenceType`, `referenceId`, `correlationGroupId`.
5. **Securitate:** App Check pe Callable; rate limiting; fără write la `balance` din reguli client.

---

## 3. Convenție de nume (implementare)

| Concept | Nume |
|---------|------|
| Portofel | `token_wallets/{userId}` |
| Transfer fără acceptare | `token_direct_transfers/{transferId}` |
| Solicitare cu acceptare | `token_payment_requests/{requestId}` |
| Jurnal | `token_ledger/{entryId}` |
| Callable transfer | `createTokenDirectTransfer` |
| Callable cerere nouă | `createTokenPaymentRequest` |
| Callable răspuns | `respondToTokenPaymentRequest` |
| Callable anulare | `cancelTokenPaymentRequest` |
| Job expirare | `expireTokenPaymentRequests` |

**Sugestie modele Dart:** `TokenWallet`, `TokenDirectTransfer`, `DirectTransferStatus`, `TokenPaymentRequest`, `PaymentRequestStatus`, `TokenLedgerEntry`.

---

## 4. Schema `token_wallets/{userId}`

| Câmp | Tip | Descriere |
|------|-----|-----------|
| `balanceMinor` | int | Unitate minimă (recomandat); ex. 100 minor = 1 token afișat |
| `updatedAt` | Timestamp | |
| `version` | int | Opțional, increment la fiecare update |
| `status` | string | `active` \| `frozen` \| `closed` |

**Reguli Firestore:** `read` dacă `request.auth.uid == userId`; `write` interzis clienților (doar Functions).

---

## 5. Schema `token_direct_transfers/{transferId}`

| Câmp | Obligatoriu | Descriere |
|------|-------------|-----------|
| `fromUserId` | da | Trebuie să fie `auth.uid` la apel |
| `toUserId` | da | Destinatar |
| `amountMinor` | da | > 0 |
| `note` | nu | Max lungime (ex. 200); filtrare conținut server-side |
| `createdAt` | da | |
| `status` | da | `completed` \| `failed` |
| `failureCode` | nu | Dacă `failed` (ex. după validări care nu au atins wallet) |
| `ledgerCorrelationId` | nu | UUID comun celor 2 linii ledger |
| `clientRequestId` | recomandat | UUID client — idempotency |

**Invariant:** `fromUserId != toUserId`.

**Observație UX:** documentul poate fi scris doar după succes tranzacție, sau creat `failed` la eșec fără mutare sold — alegeți o singură politică.

---

## 6. Schema `token_payment_requests/{requestId}`

| Câmp | Obligatoriu | Descriere |
|------|-------------|-----------|
| `payerId` | da | Cel care trebuie să accepte și de la care se scad tokenii |
| `payeeId` | da | Beneficiarul |
| `initiatorId` | da | În flux standard = `payeeId` (cel care cere) |
| `amountMinor` | da | > 0 |
| `note` | nu | Max ~200 |
| `status` | da | Vezi §7 |
| `createdAt`, `updatedAt` | da | |
| `expiresAt` | da | Ex. `createdAt + 72h` |
| `resolvedAt` | nu | La terminare |
| `declineReason` | nu | La refuz |
| `ledgerCorrelationId` | nu | După accept |
| `ledgerEntryIds` | array, nu | Id-uri în ledger |

**Invariant:** `payerId != payeeId`; `initiatorId == payeeId` pentru „cere de la X”.

---

## 7. FSM — doar `token_payment_requests`

| Stare | Semnificație |
|-------|----------------|
| `pending` | Așteaptă plătitorul |
| `accepted` | Sold mutat; ledger scris |
| `declined` | Plătitorul a refuzat |
| `cancelled` | Solicitantul a anulat |
| `expired` | TTL depășit |

**Tranziții**

- `pending` → `accepted`: doar `auth.uid == payerId`; în tranzacție verificați `pending` și `now < expiresAt`.
- `pending` → `declined`: doar `payerId`.
- `pending` → `cancelled`: doar `initiatorId`.
- `pending` → `expired`: job sau batch.

**Idempotency:** dacă documentul e deja `accepted`, al doilea apel `accept` returnează succes fără a modifica soldul din nou.

**Sold insuficient la accept:** recomandat păstrare `pending` + eroare `INSUFFICIENT_BALANCE` către client.

---

## 8. Schema `token_ledger/{entryId}`

| Câmp | Descriere |
|------|-----------|
| `userId` | Cont afectat |
| `deltaMinor` | Pozitiv intrare, negativ ieșire (sau folosiți doar `amountMinor` + `direction`) |
| `type` | `direct_transfer_debit`, `direct_transfer_credit`, `payment_request_debit`, `payment_request_credit` |
| `counterpartyUserId` | Cealaltă parte |
| `referenceType` | `direct_transfer` \| `payment_request` |
| `referenceId` | `transferId` sau `requestId` |
| `correlationGroupId` | Același pentru perechea debit+credit |
| `balanceAfterMinor` | Opțional |
| `createdAt` | |

**Convenție:** două documente per operație reușită.

---

## 9. Specificație Cloud Functions

### 9.1 `createTokenDirectTransfer`

- **Autorizare:** `fromUserId = auth.uid`.
- **Body:** `{ toUserId, amountMinor, note?, clientRequestId }` — `clientRequestId` obligatoriu pentru idempotency.
- **Pași:** validare sumă (min/max), destinatar existent și activ, `toUserId != uid`. Căutare idempotentă după index sau query controlat pe `fromUserId` + `clientRequestId` (necesită index compus dacă folosiți query). Tranzacție: read wallets, verificare `balanceMinor >= amountMinor`, update ambele wallet-uri, write transfer `completed`, write 2× ledger.
- **Răspuns:** `{ transferId, status, ledgerCorrelationId }`.
- **Erori:** `UNAUTHENTICATED`, `INVALID_AMOUNT`, `SELF_TRANSFER`, `COUNTERPARTY_NOT_FOUND`, `INSUFFICIENT_BALANCE`, `WALLET_FROZEN`, `RATE_LIMITED`.

### 9.2 `createTokenPaymentRequest`

- **Autorizare:** `auth.uid` devine `payeeId` și `initiatorId`.
- **Body:** `{ payerId, amountMinor, note? }`, `payerId != auth.uid`.
- **Efect:** create doc `pending`, `expiresAt`; FCM către `payerId`.
- **Răspuns:** `{ requestId }`.

### 9.3 `respondToTokenPaymentRequest`

- **Body:** `{ requestId, action: 'accept'|'decline', declineReason? }`.
- **Autorizare:** `auth.uid == payerId`.
- **decline:** update status + `resolvedAt`.
- **accept:** tranzacție: re-read request `pending`; verificare expirare; wallet debit/credit; ledger; `accepted` + `resolvedAt`.

### 9.4 `cancelTokenPaymentRequest`

- **Condiție:** `auth.uid == initiatorId`, `status == pending`.

### 9.5 `expireTokenPaymentRequests` (Scheduled)

- Query `status == pending` AND `expiresAt < now` (în batch-uri) → `expired`.

---

## 10. Indexuri Firestore (`firestore.indexes.json`)

1. `token_payment_requests`: câmpuri `payerId` (ASC), `status` (ASC), `createdAt` (DESC).
2. `token_payment_requests`: `payeeId` (ASC), `status` (ASC), `createdAt` (DESC).
3. `token_payment_requests`: `status` (ASC), `expiresAt` (ASC).
4. `token_direct_transfers`: `fromUserId` (ASC), `createdAt` (DESC); separat `toUserId` (ASC), `createdAt` (DESC).
5. `token_direct_transfers` (idempotency): `fromUserId` (ASC), `clientRequestId` (ASC) — unicitate logică în cod sau regulă de unicitate emisă de aplicație.
6. `token_ledger`: `userId` (ASC), `createdAt` (DESC).

---

## 11. Security Rules — outline

```
token_wallets/{uid}: allow read: if request.auth.uid == uid; allow write: if false;
token_direct_transfers/{id}: allow read: if resource.data.fromUserId == request.auth.uid
  || resource.data.toUserId == request.auth.uid; allow write: if false;
token_payment_requests/{id}: allow read: if resource.data.payerId == request.auth.uid
  || resource.data.payeeId == request.auth.uid; allow write: if false;
token_ledger/{id}: allow read: if resource.data.userId == request.auth.uid; allow write: if false;
```

Ajustați sintaxa exactă la versiunea rules. Toate mutările financiare prin Callable.

---

## 12. Coduri eroare API (contract stabil)

`UNAUTHENTICATED`, `INVALID_AMOUNT`, `SELF_TRANSFER`, `SELF_REQUEST`, `COUNTERPARTY_NOT_FOUND`, `REQUEST_NOT_FOUND`, `REQUEST_NOT_PENDING`, `REQUEST_EXPIRED`, `FORBIDDEN`, `INSUFFICIENT_BALANCE`, `WALLET_FROZEN`, `RATE_LIMITED`, `ALREADY_RESOLVED`, `DUPLICATE_CLIENT_REQUEST` (sau mapare la răspuns idempotent).

---

## 13. UI Flutter — detaliu

### Transfer direct

1. Buton „Trimite tokeni” (ecran portofel / profil).
2. Selectare destinatar (aceleași mecanisme ca prietenii / căutare user).
3. Input sumă + validare `MIN`/`MAX` local (oglindă server).
4. Notă opțională.
5. Dialog confirmare: expeditor, destinatar, sumă.
6. Generează `clientRequestId` (UUID); păstrează-l până la răspuns succes (retry același id).
7. Apelează Callable; succes → mesaj + refresh sold + istoric; eroare → mapare cod.

### Cerere de plată

1. „Cere tokeni” → alegere plătitor → sumă → notă → confirmare.
2. Callable `createTokenPaymentRequest`.
3. Ecran status: pending; buton „Anulează cererea” dacă încă pending.

### Inbox plătitor

- Stream/query: `payerId == currentUid`, `status == pending`, sort `createdAt` desc.
- Card: avatar + nume solicitant, sumă, countdown `expiresAt`, snippet notă.
- Detaliu: Accept / Refuz; la refuz opțional motiv scurt.

### Istoric

- Combinație: transferuri unde `fromUserId` sau `toUserId` == eu; cereri `accepted|declined|cancelled|expired` unde sunt participant.
- Etichete clare: „Trimis”, „Primit”, „Cerere trimisă”, „Cerere primită”, „Acceptat”, etc.

### Deep link / routing

- Parametru `requestId` din notificare → deschide `PaymentRequestDetailScreen` cu verificare că userul e `payerId` sau `payeeId`.

### Accesibilitate și claritate

- Pe ecranele cu bani: afișați explicit „Tu plătești” vs „Tu primești”.

---

## 14. Notificări FCM

| Eveniment | Destinatar | Câmpuri payload (minim) |
|-----------|------------|-------------------------|
| Transfer direct finalizat | `toUserId` | `type=direct_transfer_received`, `transferId` |
| Cerere nouă | `payerId` | `type=payment_request_pending`, `requestId` |
| Cerere acceptată | `payeeId` | `type=payment_request_accepted`, `requestId` |
| Cerere refuzată | `payeeId` | `type=payment_request_declined`, `requestId` |
| Cerere anulată | `payerId` | `type=payment_request_cancelled`, `requestId` |
| Cerere expirată | opțional ambele | `type=payment_request_expired`, `requestId` |

Handler Flutter: rutare după `type` + `requestId` / `transferId`.

---

## 15. Parametri configurabili (remote config sau const Functions)

- `MIN_AMOUNT_MINOR`, `MAX_AMOUNT_MINOR`
- Max cereri pending per utilizator
- Max transferuri / oră / zi (per user)
- `PAYMENT_REQUEST_TTL_HOURS` (ex. 72)
- Politică creare wallet: la înregistrare Cloud Function trigger vs lazy la prima operațiune

---

## 16. Testare (checklist)

- [ ] Transfer: `balance == amount` exact
- [ ] Transfer: retry același `clientRequestId` → un singur debit
- [ ] Cerere: două Accept simultane → o singură mișcare
- [ ] Refuz / anulare / expirare: sold nemodificat
- [ ] Destinatar sau plătitor inexistent / cont înghețat
- [ ] Reguli: client nu poate scrie în wallet-ul altcuiva
- [ ] Indexuri: query inbox și istoric fără erori

---

## 17. Ordine recomandată de livrare

1. `token_wallets` + trigger/init + reguli + (opțional) afișare sold în app doar read.
2. `createTokenDirectTransfer` + ledger + ecran trimite + istoric minim.
3. `token_payment_requests` + create + respond + cancel + UI inbox + detaliu.
4. Job expirare + notificări + deep link.
5. Hardening: rate limits, App Check, mesaje localizate, analytics evenimente (`direct_transfer_completed`, `payment_request_accepted`, …).

---

## 18. Glosar

- **Transfer direct:** mutare imediată; fără pas de acceptare pentru destinatar.
- **Cerere de plată:** solicitare; mutare doar după **Accept** de la `payerId`.
- **Plătitor (`payerId`):** user sursă a fondurilor la accept cerere.
- **Beneficiar (`payeeId`):** user destinație.
- **Solicitant:** în modul cerere, este `payeeId` / `initiatorId`.

---

## 19. Note de reconciliere (opțional viitor)

Job offline sau script admin: sumă `ledger` pe `userId` vs `balanceMinor` în `token_wallets` pentru detectare drift.

---

*Ultima actualizare document: completare inițială pentru implementare transfer/solicitare tokeni.*

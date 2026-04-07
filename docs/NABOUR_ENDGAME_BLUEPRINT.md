# Nabour: End-Game Architectural Blueprint

## Viziunea Sistemului

Nabour evoluează de la o aplicație reactivă de ride-hailing la un **ecosistem digital hiper-local, auto-reglat și descentralizat parțial**. Arhitectura este proiectată pentru scalabilitate masivă, costuri marginale apropiate de zero în stare de repaus, confidențialitate matematică (Zero-Knowledge) și latență insesizabilă la margine (Edge AI / Offline Mesh).

---

## 1. Maparea Tranziției (Current vs. Target State)

| Pilon Blueprint | Stare Curentă (Baza Stabilă) | Stare Țintă (End-Game) |
| :--- | :--- | :--- |
| **Telemetrie** | RTDB (`telemetry/locations`, `active_rides`), throttle de timp/distanță. | Micro-Broker MQTT dedicat, compresie Protobuf/Delta over WebSockets. |
| **Spațial (H3)** | Rezoluție fixă, partiționare pe claim `nb_room` (Cloud Functions). | Rezoluție H3 adaptivă, interogare dinamică radială (`kRing`). |
| **Stare & Date** | Firestore CRUD predominant. | Event Sourcing (`append-only` ledger), proiecții asincrone CQRS, CRDTs. |
| **AI / NLP** | Proxy Gemini pe server (`europe-west1`) pentru funcții de bază. | SLM On-Device (Zero-latency intent classification) + Gemini LLM Agent de negociere. |
| **Piață & Preț** | Costuri token statice (ex. `TokenCost.forType`), reguli codate dur. | Automated Market Maker (AMM), preț dinamic descentralizat pe baza densității H3. |
| **Securitate** | App Check activ, ruleset strict pe Firestore/RTDB, liste de contacte. | ZK-SNARKs pentru dovada proximității, criptare E2EE derivată din celula H3. |
| **Offline/Mesh** | Coadă locală + `OfflineManager.forceSync`, `AutonomousAppCoordinator` la resume/online; fără mesh peer-to-peer. | Gossip Protocol (BLE/WebRTC) pentru cereri și chat pe rază scurtă offline. |

---

## 2. Cei 5 Piloni Arhitecturali Supremi

### I. Stratul Spațial și Telemetrie (Nervous System)

* **H3 Adaptiv și `kRing`:** Eliminarea „camerelor” statice; utilizatorul este centrul unui univers continuu, interogând dinamic inelele adiacente.
* **Decuplare Totală:** Baza de date tranzacțională nu va fi niciodată atinsă de date efemere de poziționare.

### II. Sursa Adevărului: Ledger & Event Sourcing (Starea Imuabilă)

* **Portofel Imutabil:** `token_transactions` devine un event store absolut. Soldul curent este strict o proiecție calculată. Nicio operațiune update/delete pe balanță.
* **Reconciliere Offline:** Utilizarea CRDT-urilor pentru mesagerie și intenții, permițând funcționarea parțială în medii fără semnal.

### III. Inteligență Artificială Hibridă (Edge + Cloud)

* **Edge NLP:** Modele rulate nativ pe dispozitiv pentru procesarea imediată a comenzilor vocale de navigare și vizibilitate (fără cost API).
* **Cloud LLM:** Rezervat pentru mediere avansată, traducere contextuală în timp real și sumarizarea evenimentelor din cartier.

### IV. Motorul Economic (The Market)

* **Heatmapping Predictiv:** Anticiparea cererii și direcționarea proactivă a ofertei.
* **Contracte Locale (Micro-Economie):** Nodurile business (ex. cafenele) pot emite stimulente auto-executabile prin tokeni pentru șoferii activi într-o anumită celulă H3.

### V. Securitate și Izolare Totală (Zero-Trust)

* **Proximitate Fără Cunoaștere (Zero-Knowledge):** Demonstrarea apartenenței la o celulă geografică fără a expune serverului coordonatele GPS exacte.
* **E2EE Geografic:** Transmisii criptate simetric unde cheile sunt valabile doar pentru participanții validați ai unei arii restrânse.

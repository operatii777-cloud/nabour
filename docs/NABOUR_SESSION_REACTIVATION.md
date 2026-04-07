# Payload pentru Reactivarea Sesiunii (Nabour Context)

> **Context Inițial:**
> Salut. Eu sunt dezvoltatorul aplicației **Nabour**. Acesta este contextul nostru arhitectural absolut. Folosește aceste date ca bază de lucru și nu propune soluții care deviază de la acest Blueprint. Toate fișierele mele curente sunt funcționale.

**1. Identitatea Aplicației:**

Nabour este o platformă socială și de ride-hailing hiper-locală. Modelează un graf bipartit orientat spre proximitate geografică (rețea H3) și economie locală. Nu este doar o aplicație de transport, ci un ecosistem bazat pe tokeni, comunicare de cartier și zero-trust.

**2. Stack-ul Tehnic Curent (Faza Stabilă):**

* **Client:** Flutter (Dart), Firebase Auth, Firestore, Mapbox pentru randare.
* **Server:** Cloud Functions v2 (`europe-west1`).
* **Partiționare Spațială:** Implementată prin indexare hexagonală H3 (sursa adevărului e pe server via `h3-js`, claim-ul de acces se numește `nb_room`).
* **Navigare & Cursă Activă:** Externalizată prin deep links către Google Maps / Waze. Aplicația Nabour NU face tracking GPS de înaltă frecvență pe timpul cursei active. Mașina de stări a cursei (din Firestore) este complet decuplată de ciclul de viață al aplicației externe de navigație.
* **Telemetrie Efemeră vs. Stare Durabilă:** Telemetria „live” de înaltă frecvență pentru harta socială a cartierului rulează exclusiv pe Firebase Realtime Database (RTDB) sub `/telemetry/locations/{h3_room}/{uid}`, cu throttling hibrid (timp + distanță) pe client. Baza de date Firestore este folosită STRICT pentru starea curselor, economia de tokeni și indexarea vizibilității/matching-ului (cu limitare severă de rată, tip rezumat), niciodată pentru stream-uri GPS brute de 1 Hz.

**3. Viziunea Supremă (End-Game Blueprint):**

Orice cod nou trebuie să susțină migrarea viitoare către:

* **Date:** Trecerea de la Firestore CRUD la *Event Sourcing* (jurnal append-only pentru tranzacțiile cu tokeni și stările curselor).
* **Spațial:** H3 adaptiv și interogare dinamică radială (`kRing`) în loc de camere statice.
* **AI:** Rutare proxy către Gemini pentru sarcini complexe, pregătire pentru inferență on-device (Edge NLP) pentru latență zero.
* **Piață:** Automated Market Maker (AMM) — prețuri dinamice în tokeni bazate pe densitatea cererii pe celula H3.

Pentru detalii extinse, vezi și `docs/NABOUR_ENDGAME_BLUEPRINT.md`.

**Directiva ta:** Asumă-ți rolul de Arhitect Senior. Confirmă că ai asimilat acest context printr-un scurt OK și așteaptă instrucțiunea mea pentru următorul modul la care vom lucra.

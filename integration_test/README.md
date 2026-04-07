# 🧪 Teste de Integrare FriendsRide Voice AI

Acest folder conține teste de integrare complete pentru sistemul AI vocal al aplicației FriendsRide.

## 📋 Teste Disponibile

### 🚗 `e2e_ride_flow_test.dart` ← **Test End-to-End principal**

Validează **întregul flux de la rostirea adresei de către client până la găsirea unui șofer disponibil și afișarea datelor necesare** fără a depinde de rețea sau hardware audio real.

#### Grupe de teste incluse:

1. **🧠 GeminiVoiceEngine — procesare locală determinism** (11 teste)
   - Extragerea destinațiilor cunoscute: "gara", "aeroport", "centru", etc.
   - Confirmări pozitive: "da", "bine", "confirm", "perfect"
   - Confirmare șofer în starea `awaitingDriverAcceptance`
   - Refuz / anulare: "nu"
   - Salut → greeting

2. **🚗 RideFlowManager — tranziții de stare E2E** (8 teste)
   - Etapa 1: clientul spune adresa → UI umplut, stare avansată
   - Etapa 2: clientul confirmă → stare de căutare/confirmare
   - Etapa 3: TTS înregistrat pe tot parcursul fluxului
   - Etapa 4: istoricul conversației conține mesajele client+AI
   - Etapa 5: destinația și prețul estimat sunt disponibile
   - Etapa 6: anulare flow (refuz) → stare resetată
   - Etapa 7: corectarea destinației

3. **📊 Date afișate clientului** (4 teste)
   - `lastSpokenMessage` non-empty după adresă
   - `onFillAddressInUI` primește destinația corectă
   - Istoricul conține mesajele AI despre cursă
   - Flux complet happy-path: adresă → confirmare → verificare date

4. **⏱️ Performanța procesării AI** (3 teste)
   - Procesarea locală a adresei: < 500ms
   - Procesarea confirmării: < 200ms
   - 5 adrese diferite procesate: < 2000ms total

#### Caracteristici tehnice:
- **`_SilentTts`** — stub TTS care înregistrează mesajele fără audio real
- **`_FlowHarness`** — harness cu callback-uri capturate pentru verificare
- **VoiceOrchestrator** real (singleton) — eșuează graţios în test (STT în try/catch)
- Fără dependință de rețea (procesare locală Gemini)
- Fără Firebase real (callback `onCreateRideRequest` mock)

### 🎤 `voice_flow_integration_test.dart`
Test de integrare complet pentru fluxul AI vocal, care simulează un utilizator real de la pornirea interacțiunii vocale până la finalizarea comenzii.

#### Teste Incluse:

1. **🚀 Flux complet de comandă a unei curse cu măsurarea timpilor**
   - Pornirea interacțiunii vocale
   - Procesarea destinației
   - Căutarea șoferilor și prezentarea ofertei
   - Finalizarea comenzii
   - Măsurarea performanței temporale pentru fiecare etapă

2. **❌ Anularea comenzii la mijlocul fluxului**
   - Testează capacitatea sistemului de a anula o comandă în curs

3. **🔄 Corectarea destinației**
   - Verifică capacitatea utilizatorului de a corecta o destinație greșită

4. **⚙️ Setările modulului de voce**
   - Activarea/dezactivarea ascultării continue
   - Activarea/dezactivarea detectării "salut"

5. **🔄 Resetarea sistemului vocal**
   - Verifică funcționalitatea de resetare a sistemului

6. **📱 Navigarea în meniul de setări vocale**
   - Testează navigarea în setările vocale

7. **🎯 Performanța generală a sistemului**
   - Măsoară timpul de inițializare
   - Măsoară timpul de răspuns la prima comandă

## 🚀 Cum să Rulezi Testele

### Prerequisituri
- Flutter SDK instalat
- Emulator Android/iOS pornit sau dispozitiv fizic conectat
- Dependințele instalate (`flutter pub get`)

### Rularea Testelor

#### 1. Test E2E Flux Complet (recomandat)
```bash
# Rulează testul end-to-end principal
flutter test integration_test/e2e_ride_flow_test.dart
```

#### 2. Test Individual
```bash
# Rulează testul de integrare UI
flutter test integration_test/voice_flow_integration_test.dart
```

#### 3. Toate Testele de Integrare
```bash
# Rulează toate testele de integrare
flutter test integration_test/
```

#### 4. Rulare pe Dispozitiv/Emulator
```bash
# Rulează pe un dispozitiv specific
flutter test integration_test/e2e_ride_flow_test.dart --device-id <device_id>
```

### Verificarea Dispozitivelor Disponibile
```bash
flutter devices
```

## 📊 Interpretarea Rezultatelor

### ✅ Teste de Succes
- Toate etapele fluxului sunt completate cu succes
- Timpii de răspuns sunt în limitele acceptabile
- UI-ul se comportă conform așteptărilor

### ⚠️ Teste cu Avertismente
- Unele funcționalități pot fi în dezvoltare
- Timpii de răspuns pot fi mai mari decât optimul

### ❌ Teste Eșuate
- Probleme de integrare între componente
- Erori de configurare
- Funcționalități lipsă

## 🔧 Configurare și Debugging

### Logging
Testele folosesc `debugPrint` pentru a afișa informații detaliate în consolă:
- Timpii de răspuns pentru fiecare etapă
- Stările sistemului în timpul testării
- Confirmările pentru fiecare etapă completată

### Timeouts
- Testele au timeout-uri configurate pentru a evita blocarea
- Pentru operațiuni lente (căutare șoferi), se folosesc timeout-uri mai mari

### Dependințe
Testele depind de:
- `PassengerVoiceController` - pentru controlul sistemului vocal
- `RideFlowManager` - pentru logica de business
- `VoiceOrchestrator` - pentru coordonarea STT/TTS
- `GeminiVoiceEngine` - pentru procesarea AI

## 📈 Metrici de Performanță

### Timpii Acceptabili
- **Pornire overlay**: < 1000ms
- **Procesare destinație**: < 2000ms
- **Căutare șoferi**: < 5000ms
- **Finalizare comandă**: < 3000ms
- **Inițializare sistem**: < 5000ms
- **Prima comandă**: < 3000ms

### Optimizări
- Testele sunt proiectate să identifice bottleneck-urile
- Măsurarea timpilor ajută la optimizarea performanței
- Logging-ul detaliat permite identificarea problemelor

## 🐛 Troubleshooting

### Probleme Comune
1. **Testul nu pornește**: Verifică că emulatorul/dispozitivul este pornit
2. **Timeout-uri**: Mărește timeout-urile pentru dispozitive lente
3. **Erori de Provider**: Verifică că `PassengerVoiceController` este configurat corect

### Debugging
- Folosește `flutter test --verbose` pentru output detaliat
- Verifică logurile din consolă pentru informații despre progres
- Testează componentele individual înainte de testele de integrare

## 🔮 Dezvoltări Viitoare

- Teste pentru scenarii de eroare
- Teste de stres pentru performanță
- Teste pentru funcționalități noi
- Integrare cu CI/CD pipeline
- Rapoarte de performanță automate

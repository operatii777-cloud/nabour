#!/usr/bin/env bash
# ============================================================
# run_e2e_two_devices.sh
# Test E2E pe doua dispozitive fizice simultan
#
# Xiaomi (2201116TG) = cont sofer
# Lenovo (TB-J616F)  = cont pasager
#
# Rulare: bash run_e2e_two_devices.sh
# ============================================================

set -euo pipefail

DRIVER_DEVICE="IRXK5HT4YTGIQ4UO"   # Xiaomi - sofer
PASSENGER_DEVICE="HA1S0HMF"          # Lenovo - pasager

DRIVER_TEST="integration_test/e2e_two_device_driver.dart"
PASSENGER_TEST="integration_test/e2e_two_device_passenger.dart"

LOG_DIR="e2e_logs"
DRIVER_LOG="$LOG_DIR/sofer_$(date +%Y%m%d_%H%M%S).log"
PASSENGER_LOG="$LOG_DIR/pasager_$(date +%Y%m%d_%H%M%S).log"

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN}================================================${NC}"
echo -e "${CYAN}  TEST E2E - DOUA DISPOZITIVE FIZICE${NC}"
echo -e "${CYAN}================================================${NC}"
echo ""
echo -e "  Sofer  (Xiaomi): ${YELLOW}$DRIVER_DEVICE${NC}"
echo -e "  Pasager (Lenovo): ${YELLOW}$PASSENGER_DEVICE${NC}"
echo ""

# Verifica daca dispozitivele sunt conectate
echo "Verific dispozitivele conectate..."
CONNECTED=$(adb devices | grep -v "List of devices" | grep "device$" | awk '{print $1}')

if ! echo "$CONNECTED" | grep -q "$DRIVER_DEVICE"; then
    echo -e "${RED}EROARE: Xiaomi ($DRIVER_DEVICE) nu este conectat!${NC}"
    exit 1
fi

if ! echo "$CONNECTED" | grep -q "$PASSENGER_DEVICE"; then
    echo -e "${RED}EROARE: Lenovo ($PASSENGER_DEVICE) nu este conectat!${NC}"
    exit 1
fi

echo -e "${GREEN}Ambele dispozitive sunt conectate.${NC}"
echo ""

# Creeaza folderul de loguri
mkdir -p "$LOG_DIR"

# Verifica ca aplicatia e instalata si utilizatorii sunt logati
echo "Verific statusul de autentificare..."

DRIVER_AUTH=$(adb -s "$DRIVER_DEVICE" shell pm list packages 2>/dev/null | grep "com.florin.nabour" || true)
PASSENGER_AUTH=$(adb -s "$PASSENGER_DEVICE" shell pm list packages 2>/dev/null | grep "com.florin.nabour" || true)

if [ -z "$DRIVER_AUTH" ]; then
    echo -e "${RED}EROARE: App nabour nu este instalata pe Xiaomi!${NC}"
    echo "Ruleaza: flutter build apk && adb -s $DRIVER_DEVICE install build/app/outputs/flutter-apk/app-debug.apk"
    exit 1
fi

if [ -z "$PASSENGER_AUTH" ]; then
    echo -e "${RED}EROARE: App nabour nu este instalata pe Lenovo!${NC}"
    echo "Ruleaza: flutter build apk && adb -s $PASSENGER_DEVICE install build/app/outputs/flutter-apk/app-debug.apk"
    exit 1
fi

echo ""
echo -e "${CYAN}--- PORNESC TESTELE ---${NC}"
echo ""
echo "Log sofer:   $DRIVER_LOG"
echo "Log pasager: $PASSENGER_LOG"
echo ""

# Porneste testul SOFERULUI pe Xiaomi (primul, ca sa fie gata sa vada broadcast-ul)
echo -e "${YELLOW}[1/2] Pornesc testul soferului pe Xiaomi...${NC}"
flutter test "$DRIVER_TEST" \
    --device-id "$DRIVER_DEVICE" \
    --reporter expanded \
    2>&1 | tee "$DRIVER_LOG" &
DRIVER_PID=$!

echo "  PID sofer: $DRIVER_PID"
echo ""

# Asteapta putin ca soferul sa se initializeze si sa inceapa sa asculte
echo "Astept 5 secunde pentru initializarea soferului..."
sleep 5

# Porneste testul PASAGERULUI pe Lenovo
echo -e "${YELLOW}[2/2] Pornesc testul pasagerului pe Lenovo...${NC}"
flutter test "$PASSENGER_TEST" \
    --device-id "$PASSENGER_DEVICE" \
    --reporter expanded \
    2>&1 | tee "$PASSENGER_LOG" &
PASSENGER_PID=$!

echo "  PID pasager: $PASSENGER_PID"
echo ""
echo -e "${CYAN}Ambele teste ruleaza simultan. Urmareste logurile de mai sus...${NC}"
echo ""

# Asteapta ambele procese sa se termine
DRIVER_EXIT=0
PASSENGER_EXIT=0

wait $DRIVER_PID || DRIVER_EXIT=$?
echo ""
echo -e "Testul soferului terminat cu codul: ${DRIVER_EXIT}"

wait $PASSENGER_PID || PASSENGER_EXIT=$?
echo -e "Testul pasagerului terminat cu codul: ${PASSENGER_EXIT}"

echo ""
echo -e "${CYAN}================================================${NC}"
echo -e "${CYAN}  REZULTATE FINALE${NC}"
echo -e "${CYAN}================================================${NC}"
echo ""

if [ $DRIVER_EXIT -eq 0 ]; then
    echo -e "  Sofer  (Xiaomi):  ${GREEN}TRECUT${NC}"
else
    echo -e "  Sofer  (Xiaomi):  ${RED}PICAT (exit $DRIVER_EXIT)${NC}"
fi

if [ $PASSENGER_EXIT -eq 0 ]; then
    echo -e "  Pasager (Lenovo): ${GREEN}TRECUT${NC}"
else
    echo -e "  Pasager (Lenovo): ${RED}PICAT (exit $PASSENGER_EXIT)${NC}"
fi

echo ""
echo "Loguri complete:"
echo "  $DRIVER_LOG"
echo "  $PASSENGER_LOG"
echo ""

# Curata documentele de test din Firestore (optional)
echo "Nota: Broadcasturile de test (isE2eTest=true) raman in Firestore."
echo "Le poti sterge manual din Firebase Console > ride_broadcasts"
echo ""

if [ $DRIVER_EXIT -ne 0 ] || [ $PASSENGER_EXIT -ne 0 ]; then
    exit 1
fi

exit 0

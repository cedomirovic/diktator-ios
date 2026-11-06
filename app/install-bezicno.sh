#!/bin/zsh
# Bežična instalacija ličnog (Debug) builda na iPhone.
#
#   app/install-bezicno.sh                 # podrazumevani uređaj
#   app/install-bezicno.sh <UDID>          # drugi uređaj
#
# Uslovi: telefon je uparen u Xcode-u, uključen je „Connect via network“,
# telefon je na istoj Wi-Fi mreži i otključan. Kabl nije potreban.
#
# Instalira se Debug šema (lični build): URL linkovi za diktat i sesija bez
# isteka rade. Za App Store build koristi app/objavi-testflight.sh.
set -euo pipefail

SKRIPT="$(cd "$(dirname "$0")" && pwd)"
KOREN="$(dirname "$SKRIPT")"
UREDJAJ="${1:-00008130-0012213E3A61001C}"
BUNDLE="com.cedomirovic.diktator.ios"
IZLAZ="$KOREN/build/ota"

echo "== Diktator iOS: bežična instalacija =="
if ! xcrun devicectl device info details --device "$UREDJAJ" >/dev/null 2>&1; then
  echo "Greška: uređaj $UREDJAJ nije dostupan." >&2
  echo "Proveri da je telefon otključan, na istoj Wi-Fi mreži i uparen u" >&2
  echo "Xcode-u (Window → Devices and Simulators → Connect via network)." >&2
  exit 1
fi
echo "Uređaj je dostupan preko mreže."

echo "== Gradnja (Debug, za uređaj) =="
xcodebuild \
  -project "$SKRIPT/DiktatorIOS.xcodeproj" \
  -scheme DiktatorIOS \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$IZLAZ" \
  -allowProvisioningUpdates \
  build

APP="$IZLAZ/Build/Products/Debug-iphoneos/DiktatorIOS.app"
if [[ ! -d "$APP" ]]; then
  echo "Greška: nema $APP" >&2
  exit 1
fi

echo "== Instalacija preko mreže =="
xcrun devicectl device install app --device "$UREDJAJ" "$APP"

echo "== Pokretanje =="
xcrun devicectl device process launch --device "$UREDJAJ" "$BUNDLE" || true

echo
echo "Gotovo. Ako se aplikacija ne otvori, otključaj telefon i tapni ikonu."
echo "Besplatan nalog: profil traje 7 dana, pa ponovi ovu skriptu pre isteka."

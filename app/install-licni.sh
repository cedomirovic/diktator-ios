#!/bin/zsh
# Bežična instalacija privremene kopije sa besplatnim timom.
#
#   app/install-licni.sh                 # podrazumevani iPhone
#   app/install-licni.sh <UDID>          # drugi uređaj
#
# Pravi se kopija sa bundle ID-jevima `com.cedomirovic.diktator.ios.licni` i
# `...licni.keyboard`, jer pravi ID-jevi pripadaju plaćenom timu i besplatni
# `LHQ4Q44425` ne može da ih registruje. Izvori su isti kao u `app/`, samo se
# projekat generiše u `build/licni` iz `app/project-licni.yml`.
#
# Posle instalacije, ako iOS prvi put traži potvrdu profila:
#   Podešavanja → Opšte → VPN i upravljanje uređajem → Developer App → Trust.
#
# Profil traje 7 dana; posle toga ponovi ovu skriptu.
set -euo pipefail

SKRIPT="$(cd "$(dirname "$0")" && pwd)"
KOREN="$(dirname "$SKRIPT")"
UREDJAJ="${1:-00008130-0012213E3A61001C}"
BUNDLE="com.cedomirovic.diktator.ios.licni"
TIM="${DIKTATOR_TIM:-LHQ4Q44425}"
IZLAZ="$KOREN/build/licni"

echo "== Diktator iOS: lična kopija preko mreže =="
echo "Tim: $TIM"
if ! xcrun devicectl device info details --device "$UREDJAJ" >/dev/null 2>&1; then
  echo "Greška: uređaj $UREDJAJ nije dostupan." >&2
  echo "Proveri da je telefon otključan, na istoj Wi-Fi mreži i uparen u" >&2
  echo "Xcode-u (Window → Devices and Simulators → Connect via network)." >&2
  exit 1
fi
echo "Uređaj je dostupan preko mreže."

echo "== Generisanje projekta =="
mkdir -p "$IZLAZ"
cp "$SKRIPT/project-licni.yml" "$IZLAZ/project.yml"
(cd "$IZLAZ" && xcodegen generate)

echo "== Gradnja (Debug, za uređaj) =="
xcodebuild \
  -project "$IZLAZ/DiktatorLicni.xcodeproj" \
  -scheme DiktatorLicni \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$IZLAZ/ota" \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$TIM" \
  build

APP="$IZLAZ/ota/Build/Products/Debug-iphoneos/DiktatorLicni.app"
if [[ ! -d "$APP" ]]; then
  echo "Greška: nema $APP" >&2
  exit 1
fi

echo "== Instalacija preko mreže =="
xcrun devicectl device install app --device "$UREDJAJ" "$APP"

echo "== Pokretanje =="
xcrun devicectl device process launch --device "$UREDJAJ" "$BUNDLE" || true

echo
echo "Gotovo. Ako se aplikacija ne otvori, prvo odobri profil:"
echo "  Podešavanja → Opšte → VPN i upravljanje uređajem → Developer App → Trust"
echo "Zatim dodaj tastaturu: Podešavanja → Opšte → Tastatura → Tastature."

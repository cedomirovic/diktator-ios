#!/bin/zsh
# Arhivira Release build i šalje ga u App Store Connect (TestFlight).
#
# Pre prvog pokretanja:
#   1. Plaćeni Apple Developer Program mora biti aktivan i ugovori prihvaćeni
#      u App Store Connect-u.
#   2. U Xcode-u: Settings → Accounts → tvoj tim → Manage Certificates →
#      "+" → Apple Distribution. Xcode zatim napravi App Store profil.
#   3. U App Store Connect-u napravi app record sa bundle ID-em
#      com.cedomirovic.diktator.ios (vidi docs/app-store.md).
#
# Pokretanje:
#   app/objavi-testflight.sh                 # koristi nalog iz Xcode-a
#   ASC_KEY_PATH=... ASC_KEY_ID=... ASC_ISSUER_ID=... app/objavi-testflight.sh
#
# API ključ (preporučeno za CI): App Store Connect → Users and Access →
# Integrations → App Store Connect API → "+", uloga "App Manager". Sačuvaj
# .p8 fajl van repoa i prosledi putanju kroz ASC_KEY_PATH.

set -euo pipefail

SKRIPT="$(cd "$(dirname "$0")" && pwd)"
KOREN="$(dirname "$SKRIPT")"
PROJEKAT="$SKRIPT/DiktatorIOS.xcodeproj"
ARHIVA="$KOREN/build/DiktatorIOS.xcarchive"
IZVOZ="$KOREN/build/izvoz"

echo "== Diktator iOS: priprema za App Store Connect =="

if ! command -v xcodebuild >/dev/null; then
  echo "Greška: xcodebuild nije pronađen. Instaliraj Xcode." >&2
  exit 1
fi

VERZIJA="$(grep -m1 'MARKETING_VERSION' "$SKRIPT/project.yml" | sed 's/.*"\(.*\)".*/\1/')"
BUILD="$(grep -m1 'CURRENT_PROJECT_VERSION' "$SKRIPT/project.yml" | sed 's/.*"\(.*\)".*/\1/')"
echo "Verzija: $VERZIJA ($BUILD)"

if ! security find-identity -v -p codesigning 2>/dev/null | grep -q "Apple Distribution"; then
  echo
  echo "Upozorenje: nema „Apple Distribution“ sertifikata." >&2
  echo "Otvori Xcode → Settings → Accounts → Manage Certificates → + →" >&2
  echo "Apple Distribution, pa pokreni skriptu ponovo." >&2
  echo "Ako nastaviš, arhiva će verovatno ostati potpisana razvojnim profilom" >&2
  echo "i App Store Connect će je odbiti." >&2
  echo
  if [[ "${NASTAVI_BEZ_SERTIFIKATA:-0}" != "1" ]]; then
    exit 2
  fi
fi

if [[ ! -f "$SKRIPT/DiktatorIOS/PrivacyInfo.xcprivacy" ]]; then
  echo "Greška: nedostaje app/DiktatorIOS/PrivacyInfo.xcprivacy." >&2
  exit 1
fi
if [[ ! -f "$SKRIPT/DiktatorKeyboard/PrivacyInfo.xcprivacy" ]]; then
  echo "Greška: nedostaje app/DiktatorKeyboard/PrivacyInfo.xcprivacy." >&2
  exit 1
fi

echo "== Arhiviranje (Release) =="
rm -rf "$ARHIVA" "$IZVOZ"
xcodebuild \
  -project "$PROJEKAT" \
  -scheme DiktatorIOS \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARHIVA" \
  -allowProvisioningUpdates \
  archive

APP="$ARHIVA/Products/Applications/Diktator.app"
for PUTANJA in \
  "$APP/PrivacyInfo.xcprivacy" \
  "$APP/PlugIns/DiktatorKeyboard.appex/PrivacyInfo.xcprivacy"; do
  if [[ ! -f "$PUTANJA" ]]; then
    echo "Greška: u arhivi nema $PUTANJA" >&2
    exit 1
  fi
done
echo "Privacy manifest je u arhivi (aplikacija i tastatura)."

echo "== Izvoz i slanje u App Store Connect =="
if [[ -n "${ASC_KEY_PATH:-}" && -n "${ASC_KEY_ID:-}" && -n "${ASC_ISSUER_ID:-}" ]]; then
  echo "Autentifikacija: App Store Connect API ključ $ASC_KEY_ID"
  xcodebuild \
    -exportArchive \
    -archivePath "$ARHIVA" \
    -exportOptionsPlist "$SKRIPT/ExportOptions.plist" \
    -exportPath "$IZVOZ" \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$ASC_KEY_PATH" \
    -authenticationKeyID "$ASC_KEY_ID" \
    -authenticationKeyIssuerID "$ASC_ISSUER_ID"
else
  echo "Autentifikacija: nalog prijavljen u Xcode-u"
  xcodebuild \
    -exportArchive \
    -archivePath "$ARHIVA" \
    -exportOptionsPlist "$SKRIPT/ExportOptions.plist" \
    -exportPath "$IZVOZ" \
    -allowProvisioningUpdates
fi

echo
echo "Gotovo: $VERZIJA ($BUILD) je poslat u App Store Connect."
echo "Otvori https://appstoreconnect.apple.com → Diktator → TestFlight i sačekaj"
echo "obradu (obično 5–15 minuta), pa dodaj build u grupu testera."
echo
echo "Podsetnik: metadata, screenshots i Review Notes su u docs/app-store.md."

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
#   app/objavi-testflight.sh                 # tim iz project.yml
#   DIKTATOR_TIM=ABCDE12345 app/objavi-testflight.sh
#   ASC_KEY_PATH=... ASC_KEY_ID=... ASC_ISSUER_ID=... app/objavi-testflight.sh
#
# `DIKTATOR_TIM` menja tim samo za ovaj build. Kada pređeš na plaćeni
# Developer Program, upiši novi tim u project.yml i ExportOptions.plist (ili
# pokreni `app/proveri-potpis.sh` da vidiš šta je trenutno na Mac-u).
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
TIM="${DIKTATOR_TIM:-$(grep -m1 'DEVELOPMENT_TEAM' "$SKRIPT/project.yml" | sed 's/.*: *//' | tr -d '"')}"
echo "Verzija: $VERZIJA ($BUILD)"
echo "Tim: $TIM"

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

echo "== Arhiviranje (AppStore) =="
rm -rf "$ARHIVA" "$IZVOZ"
xcodebuild \
  -project "$PROJEKAT" \
  -scheme DiktatorIOS-AppStore \
  -configuration AppStore \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARHIVA" \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$TIM" \
  CODE_SIGN_IDENTITY="Apple Distribution" \
  archive

APP="$(find "$ARHIVA/Products/Applications" -maxdepth 1 -name '*.app' | head -1)"
if [[ -z "$APP" ]]; then
  echo "Greška: u arhivi nema .app bundle-a." >&2
  exit 1
fi
for PUTANJA in \
  "$APP/PrivacyInfo.xcprivacy" \
  "$APP/PlugIns/DiktatorKeyboard.appex/PrivacyInfo.xcprivacy"; do
  if [[ ! -f "$PUTANJA" ]]; then
    echo "Greška: u arhivi nema $PUTANJA" >&2
    exit 1
  fi
done
echo "Privacy manifest je u arhivi (aplikacija i tastatura)."

POTPIS="$(codesign -dv "$APP" 2>&1 | awk -F= '/^Authority=/{print $2; exit}')"
echo "Potpis arhive: ${POTPIS:-nepoznat}"
if [[ "$POTPIS" == *"Apple Development"* ]]; then
  echo "Greška: arhiva je potpisana razvojnim sertifikatom, a App Store traži" >&2
  echo "„Apple Distribution“. Proveri tim i sertifikat: app/proveri-potpis.sh" >&2
  exit 3
fi

echo "== Izvoz i slanje u App Store Connect =="
OPCIJE="$KOREN/build/ExportOptions-$TIM.plist"
cp "$SKRIPT/ExportOptions.plist" "$OPCIJE"
/usr/libexec/PlistBuddy -c "Set :teamID $TIM" "$OPCIJE" >/dev/null
if [[ -n "${ASC_KEY_PATH:-}" && -n "${ASC_KEY_ID:-}" && -n "${ASC_ISSUER_ID:-}" ]]; then
  echo "Autentifikacija: App Store Connect API ključ $ASC_KEY_ID"
  xcodebuild \
    -exportArchive \
    -archivePath "$ARHIVA" \
    -exportOptionsPlist "$OPCIJE" \
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
    -exportOptionsPlist "$OPCIJE" \
    -exportPath "$IZVOZ" \
    -allowProvisioningUpdates
fi

echo
echo "Gotovo: $VERZIJA ($BUILD) je poslat u App Store Connect."
echo "Otvori https://appstoreconnect.apple.com → Diktator → TestFlight i sačekaj"
echo "obradu (obično 5–15 minuta), pa dodaj build u grupu testera."
echo
echo "Podsetnik: metadata, screenshots i Review Notes su u docs/app-store.md."

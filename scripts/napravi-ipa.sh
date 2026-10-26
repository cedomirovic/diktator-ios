#!/bin/bash
# Pravi nepotpisan IPA za AltStore/SideStore. Potpisivanje radi AltStore
# tvojim besplatnim Apple ID-jem; ako to ne uspe, koristi Xcode direktno.
set -euo pipefail
cd "$(dirname "$0")/.."

PROJEKAT="app/DiktatorIOS.xcodeproj"
SEMA="DiktatorIOS"
DERIVED="build/ipa"
APP="$DERIVED/Build/Products/Release-iphoneos/DiktatorIOS.app"
IPA="build/DiktatorIOS.ipa"

# Ako je xcode-select još na Command Line Tools, koristi Xcode.app direktno.
if ! xcodebuild -version >/dev/null 2>&1; then
  if [ -x /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild ]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
  fi
fi

if ! xcodebuild -version >/dev/null 2>&1; then
  echo "Nedostaje Xcode. Instaliraj Xcode 27.1 ili noviji i pokreni:" >&2
  echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
  echo "  sudo xcodebuild -license accept" >&2
  exit 1
fi

if [ ! -f app/vendor-ios/whisper/lib/libwhisper.a ]; then
  echo "Nedostaje whisper.cpp za iOS — pripremam ga (traje 5–10 min)…"
  bash app/pripremi-whisper-ios.sh
fi

if [ ! -d "$PROJEKAT" ]; then
  if ! command -v xcodegen >/dev/null 2>&1; then
    echo "Nedostaje app/DiktatorIOS.xcodeproj i xcodegen." >&2
    echo "Instaliraj xcodegen: brew install xcodegen" >&2
    exit 1
  fi
  (cd app && xcodegen generate)
fi

rm -rf "$DERIVED" build/Payload "$IPA"
mkdir -p build/Payload

xcodebuild \
  -project "$PROJEKAT" \
  -scheme "$SEMA" \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build

if [ ! -d "$APP" ]; then
  echo "Greška: $APP nije napravljen." >&2
  exit 1
fi

cp -R "$APP" build/Payload/
(cd build && zip -r DiktatorIOS.ipa Payload >/dev/null)
shasum -a 256 "$IPA"

echo
echo "napravljeno: $(pwd)/$IPA"
echo "Otvori IPA u AltStore/SideStore i instaliraj na iPhone."

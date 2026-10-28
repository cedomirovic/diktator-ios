#!/bin/zsh
# Pravi snimke ekrana za App Store iz iOS simulatora.
#
#   app/uzmi-snimke.sh                 # iPhone 17 Pro Max (6.9") i iPad Pro 13"
#   app/uzmi-snimke.sh "iPhone 17 Pro Max"
#
# Snimke idu u docs/slike/app-store/. Rezolucije koje App Store Connect traži:
#   iPhone 6.9"  1320 × 2868
#   iPad 13"     2064 × 2752
#
# Napomena: snimak custom tastature u drugoj aplikaciji simulator ne može da
# napravi skriptom (tastatura se dodaje ručno u Settings). Taj kadar snimi na
# telefonu ili u simulatoru ručno.

set -euo pipefail

SKRIPT="$(cd "$(dirname "$0")" && pwd)"
KOREN="$(dirname "$SKRIPT")"
IZLAZ="$KOREN/docs/slike/app-store"
DERIVED="$KOREN/build/sim-snimke"

uredjaji=("${@}")
if [[ ${#uredjaji[@]} -eq 0 ]]; then
  uredjaji=("iPhone 17 Pro Max" "iPad Pro 13-inch (M5)")
fi

mkdir -p "$IZLAZ"

for IME in "${uredjaji[@]}"; do
  UDID="$(xcrun simctl list devices available | grep -F "$IME (" | head -1 | sed 's/.*(\([0-9A-F-]*\)).*/\1/')"
  if [[ -z "$UDID" ]]; then
    echo "Greška: simulator „$IME“ nije instaliran." >&2
    exit 1
  fi

  echo "== $IME ($UDID) =="
  xcrun simctl boot "$UDID" 2>/dev/null || true
  xcrun simctl bootstatus "$UDID" -b >/dev/null

  xcodebuild \
    -project "$SKRIPT/DiktatorIOS.xcodeproj" \
    -scheme DiktatorIOS \
    -configuration Debug \
    -destination "platform=iOS Simulator,id=$UDID" \
    -derivedDataPath "$DERIVED" \
    build >/dev/null

  APP="$DERIVED/Build/Products/Debug-iphonesimulator/DiktatorIOS.app"
  xcrun simctl install "$UDID" "$APP"
  xcrun simctl launch "$UDID" com.cedomirovic.diktator.ios >/dev/null
  # Prvo pokretanje na iPad-u ume da potraje; bez ovoga snimak bude prazan.
  sleep 9

  PREFIKS="$(echo "$IME" | tr ' ' '-' | tr -d '()')"
  for TAB in 0 3 1 4; do
    # URL scheme bi prikazao „Open in Diktator?“ dijalog, pa tab biramo
    # argumentom pri pokretanju (vidi AppStanje.init).
    xcrun simctl terminate "$UDID" com.cedomirovic.diktator.ios 2>/dev/null || true
    xcrun simctl launch "$UDID" com.cedomirovic.diktator.ios -DiktatorTab "$TAB" >/dev/null
    sleep 4
    xcrun simctl io "$UDID" screenshot "$IZLAZ/$PREFIKS-$TAB.png"
    echo "  $IZLAZ/$PREFIKS-$TAB.png"
  done

  xcrun simctl shutdown "$UDID" 2>/dev/null || true
done

echo
echo "Gotovo. Proveri rezolucije:"
for F in "$IZLAZ"/*.png; do
  echo "  $(basename "$F"): $(sips -g pixelWidth -g pixelHeight "$F" | tail -2 | awk '{print $2}' | paste -sd '×' -)"
done

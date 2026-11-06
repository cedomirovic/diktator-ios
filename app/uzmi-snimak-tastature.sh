#!/bin/zsh
# Pravi snimak tastature Diktator u „drugoj“ aplikaciji.
#
#   app/uzmi-snimak-tastature.sh                  # iPhone 17 Pro Max
#   app/uzmi-snimak-tastature.sh <UDID> <izlaz>
#
# Zašto ovako: u simulatoru se custom tastatura ne može uključiti skriptom
# (Settings → Keyboards traži dodir), pa App Store traži ručni kadar. Zato se
# pravi mala probna aplikacija koja u sebe ugrađuje pravi
# KeyboardViewController iz `app/DiktatorKeyboard`. Snimak prikazuje stvarni
# kod tastature, a ne crtež.
#
# Probna aplikacija se ne gradi u okviru Diktatora i ne ide u App Store.
set -euo pipefail

SKRIPT="$(cd "$(dirname "$0")" && pwd)"
KOREN="$(dirname "$SKRIPT")"
UDID="${1:-530E54D0-7B7A-4711-9C71-13E1BC5A702F}"
IZLAZ="${2:-$KOREN/docs/slike/app-store/tastatura.png}"
RAD="$KOREN/build/pregled-tastature"

SDK="$(xcrun --sdk iphonesimulator --show-sdk-path)"
APP="$RAD/PregledTastature.app"

rm -rf "$RAD"
mkdir -p "$APP"

# Pravi se kopija tastature sa uključenim Full Access-om (u probnoj
# aplikaciji nema sistemske tastature, pa dozvola ne postoji).
python3 - "$SKRIPT/DiktatorKeyboard/KeyboardViewController.swift" "$RAD/KeyboardViewController.swift" <<'PY'
import io, sys
izvor, cilj = sys.argv[1], sys.argv[2]
s = io.open(izvor, encoding="utf-8").read()
staro = "    private var sesijaAktivna = false"
novo = """    private var sesijaAktivna = ProcessInfo.processInfo.arguments.contains("-Sesija")
    /// U probnoj aplikaciji nema sistemske tastature, pa je Full Access uvek dat.
    override var hasFullAccess: Bool { true }"""
assert staro in s
io.open(cilj, "w", encoding="utf-8").write(s.replace(staro, novo, 1))
PY

xcrun swiftc \
  -sdk "$SDK" \
  -target arm64-apple-ios17.0-simulator \
  -swift-version 5 \
  "$SKRIPT/alati/pregled-tastature/PregledApp.swift" \
  "$RAD/KeyboardViewController.swift" \
  "$SKRIPT/DiktatorKeyboard/Prevod.swift" \
  -o "$APP/PregledTastature"

cat > "$APP/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>PregledTastature</string>
	<key>CFBundleIdentifier</key>
	<string>com.cedomirovic.pregledtastature</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>PregledTastature</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>CFBundleSupportedPlatforms</key>
	<array>
		<string>iPhoneSimulator</string>
	</array>
	<key>DTPlatformName</key>
	<string>iphonesimulator</string>
	<key>MinimumOSVersion</key>
	<string>17.0</string>
	<key>UIDeviceFamily</key>
	<array>
		<integer>1</integer>
	</array>
	<key>UILaunchScreen</key>
	<dict/>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
	</array>
</dict>
</plist>
PLIST

# Prevodi tastature, da snimak bude na jeziku sistema.
cp -R "$SKRIPT/DiktatorKeyboard/en.lproj" "$APP/"
cp -R "$SKRIPT/DiktatorKeyboard/sr.lproj" "$APP/"

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl terminate "$UDID" com.cedomirovic.pregledtastature 2>/dev/null || true
xcrun simctl uninstall "$UDID" com.cedomirovic.pregledtastature 2>/dev/null || true
xcrun simctl install "$UDID" "$APP"
xcrun simctl launch "$UDID" com.cedomirovic.pregledtastature >/dev/null
sleep 5
mkdir -p "$(dirname "$IZLAZ")"
xcrun simctl io "$UDID" screenshot "$IZLAZ"

echo "Snimak: $IZLAZ"
sips -g pixelWidth -g pixelHeight "$IZLAZ" | tail -2 | awk '{print $2}' | paste -sd '×' -

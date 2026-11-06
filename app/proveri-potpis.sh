#!/bin/zsh
# Provera tima, sertifikata i profila pre slanja u App Store Connect.
#
#   app/proveri-potpis.sh              # tim iz project.yml
#   app/proveri-potpis.sh ABCDE12345   # drugi tim
#
# Skripta ništa ne menja: samo čita project.yml, ExportOptions.plist,
# Keychain i profile u ~/Library/MobileDevice/Provisioning Profiles.
set -uo pipefail

SKRIPT="$(cd "$(dirname "$0")" && pwd)"
TIM="${1:-${DIKTATOR_TIM:-$(grep -m1 'DEVELOPMENT_TEAM' "$SKRIPT/project.yml" | sed 's/.*: *//' | tr -d '"')}}"
TIM_IZVOZ="$(/usr/libexec/PlistBuddy -c "Print :teamID" "$SKRIPT/ExportOptions.plist" 2>/dev/null || echo '?')"
APLIKACIJA="com.cedomirovic.diktator.ios"
TASTATURA="com.cedomirovic.diktator.ios.keyboard"

PROBLEM=0
echo "== Diktator iOS: provera potpisa =="
echo "Tim (project.yml):      $TIM"
echo "Tim (ExportOptions):    $TIM_IZVOZ"

if [[ "$TIM" != "$TIM_IZVOZ" ]]; then
  echo "✗ Timovi se ne slažu. Upiši isti tim u app/project.yml i app/ExportOptions.plist." >&2
  PROBLEM=1
else
  echo "✓ project.yml i ExportOptions.plist koriste isti tim."
fi

# Svi DEVELOPMENT_TEAM unosi u pbxproj moraju da budu isti.
TIMOVI_U_PROJEKTU="$(grep -o 'DEVELOPMENT_TEAM = [A-Z0-9]*;' "$SKRIPT/DiktatorIOS.xcodeproj/project.pbxproj" \
  | sed 's/.*= //; s/;//' | sort -u | tr '\n' ' ')"
echo "Timovi u pbxproj:       ${TIMOVI_U_PROJEKTU:-nema}"
if [[ "$TIMOVI_U_PROJEKTU" != "$TIM " ]]; then
  echo "⚠ pbxproj nije usklađen sa project.yml. Pokreni: cd app && xcodegen generate" >&2
  PROBLEM=1
else
  echo "✓ pbxproj koristi isti tim."
fi

echo
echo "== Sertifikati =="
SERTIFIKATI="$(security find-identity -v -p codesigning 2>/dev/null || true)"
if [[ -z "$SERTIFIKATI" ]] || echo "$SERTIFIKATI" | grep -q '0 valid identities found'; then
  echo "  (nema sertifikata za potpisivanje)"
else
  echo "$SERTIFIKATI" | grep '"' | sed 's/^/  /'
fi

if echo "$SERTIFIKATI" | grep -q "Apple Distribution"; then
  echo "✓ Ima Apple Distribution sertifikat."
else
  echo "✗ Nema Apple Distribution sertifikata." >&2
  echo "  Xcode → Settings → Accounts → tim → Manage Certificates → + →" >&2
  echo "  Apple Distribution. Potreban je plaćeni Apple Developer Program." >&2
  PROBLEM=1
fi

echo
echo "== Profili za tim $TIM =="
PROFILI=(
  "$HOME/Library/MobileDevice/Provisioning Profiles"
  "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
)
NADJENO_APP=0
NADJENO_TASTATURA=0
IMA_PROFILA=0
for FOLDER in "${PROFILI[@]}"; do
  [[ -d "$FOLDER" ]] || continue
  IMA_PROFILA=1
  for FAJL in "$FOLDER"/*.mobileprovision(N); do
    PLIST="$(mktemp)"
    if ! security cms -D -i "$FAJL" > "$PLIST" 2>/dev/null; then
      rm -f "$PLIST"
      continue
    fi
    PROFIL_TIM="$(/usr/libexec/PlistBuddy -c 'Print :TeamIdentifier:0' "$PLIST" 2>/dev/null || echo '?')"
    if [[ "$PROFIL_TIM" != "$TIM" ]]; then
      rm -f "$PLIST"
      continue
    fi
    IME="$(/usr/libexec/PlistBuddy -c 'Print :Name' "$PLIST" 2>/dev/null || echo '?')"
    IDENT="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' "$PLIST" 2>/dev/null || echo '?')"
    ISTEK="$(/usr/libexec/PlistBuddy -c 'Print :ExpirationDate' "$PLIST" 2>/dev/null || echo '?')"
    if /usr/libexec/PlistBuddy -c 'Print :ProvisionedDevices' "$PLIST" >/dev/null 2>&1; then
      VRSTA="razvojni/ad hoc"
    else
      VRSTA="App Store"
    fi
    echo "  $IME"
    echo "    $IDENT — $VRSTA, ističe $ISTEK"
    [[ "$IDENT" == *"$APLIKACIJA"* && "$VRSTA" == "App Store" ]] && NADJENO_APP=1
    [[ "$IDENT" == *"$TASTATURA"* && "$VRSTA" == "App Store" ]] && NADJENO_TASTATURA=1
    rm -f "$PLIST"
  done
done
[[ "$IMA_PROFILA" == "1" ]] || echo "  (nema foldera sa profilima)"

if [[ "$NADJENO_APP" == "1" && "$NADJENO_TASTATURA" == "1" ]]; then
  echo "✓ Postoje App Store profili za aplikaciju i tastaturu."
else
  echo "⚠ Nema App Store profila za oba bundle ID-a. Arhiviraj sa" >&2
  echo "  -allowProvisioningUpdates (to radi app/objavi-testflight.sh)." >&2
  PROBLEM=1
fi

echo
if [[ "$PROBLEM" == "0" ]]; then
  echo "Sve je spremno za app/objavi-testflight.sh."
else
  echo "Ima stavki koje treba rešiti pre slanja (vidi ✗ i ⚠ iznad)."
fi

echo
echo "Podsetnik: ako je $TIM tim besplatnog naloga, App Store neće primiti"
echo "build. Upiši tim iz plaćenog Developer Programa u app/project.yml i"
echo "app/ExportOptions.plist, pa pokreni: cd app && xcodegen generate"
exit "$PROBLEM"

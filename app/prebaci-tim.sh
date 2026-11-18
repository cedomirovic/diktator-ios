#!/bin/zsh
# Prebacuje projekat na drugi Apple tim (npr. plaćeni Developer Program).
#
#   app/prebaci-tim.sh ABCDE12345
#
# Menja DEVELOPMENT_TEAM u project.yml, teamID u ExportOptions.plist i sve
# DEVELOPMENT_TEAM unose u pbxproj, pa proveri da su usklađeni. Ne dira
# bundle ID, potpisivanje ni profile — njih Xcode napravi kada je nalog
# prijavljen (Settings → Accounts → Manage Certificates).
set -euo pipefail

SKRIPT="$(cd "$(dirname "$0")" && pwd)"
TIM="${1:-}"
if [[ ! "$TIM" =~ ^[A-Z0-9]{10}$ ]]; then
  echo "Upotreba: app/prebaci-tim.sh <TEAM_ID>" >&2
  echo "Team ID ima 10 slova/cifara (npr. ABCDE12345); vidi ga u" >&2
  echo "App Store Connect → Membership → Team ID." >&2
  exit 1
fi

STARI="$(grep -m1 'DEVELOPMENT_TEAM' "$SKRIPT/project.yml" | sed 's/.*: *//' | tr -d '"')"
if [[ "$STARI" == "$TIM" ]]; then
  echo "Projekat već koristi tim $TIM."
  exit 0
fi

echo "Menjam tim $STARI → $TIM"
for FAJL in \
  "$SKRIPT/project.yml" \
  "$SKRIPT/ExportOptions.plist" \
  "$SKRIPT/DiktatorIOS.xcodeproj/project.pbxproj"; do
  perl -pi -e "s/\Q$STARI\E/$TIM/g" "$FAJL"
done

echo
echo "Provera:"
"$SKRIPT/proveri-potpis.sh" "$TIM" || true

echo
echo "Sledeće:"
echo "1. Xcode → Settings → Accounts → prijavi nalog sa timom $TIM."
echo "2. Manage Certificates → + → Apple Distribution (za App Store) i"
echo "   Apple Development (za uređaj)."
echo "3. app/proveri-potpis.sh $TIM treba da prođe bez ✗ i ⚠."
echo "4. Za uređaj: DIKTATOR_TIM=$TIM app/install-bezicno.sh"
echo "   Za TestFlight: DIKTATOR_TIM=$TIM app/objavi-testflight.sh"

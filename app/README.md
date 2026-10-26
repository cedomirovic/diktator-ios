# app/

Swift izvori i Xcode projekat za **Diktator iOS 0.1.1 (2)**.

```text
app/
  DiktatorIOS/       glavna SwiftUI aplikacija
  DiktatorKeyboard/  custom tastatura (UIInputViewController)
  vendor-ios/        whisper.cpp statičke biblioteke (ne ide u git)
  project.yml        XcodeGen specifikacija
  DiktatorIOS.xcodeproj
  pripremi-whisper-ios.sh
```

## Prvi build

Xcode 27.1 je obavezan; samo Command Line Tools nije dovoljno. Proveren build:
macOS 26.7.1, Xcode 27.1, iOS SDK 27.1; Debug i Release prolaze.

```bash
# 1. whisper.cpp za iOS (arm64, Metal + Accelerate)
cd app
bash pripremi-whisper-ios.sh

# 2. Xcode projekat (ako .xcodeproj nije tu)
xcodegen generate

# 3. Otvori projekat
open DiktatorIOS.xcodeproj
```

U Xcode-u:

1. Settings → Accounts → dodaj Apple ID (Personal Team).
2. Za oba targeta (`DiktatorIOS` i `DiktatorKeyboard`) izaberi isti Team.
3. Bundle ID ostaje `com.cedomirovic.diktator.ios` i
   `com.cedomirovic.diktator.ios.keyboard`; ako je zauzet, dodaj jedinstveni
   deo u oba.
4. Izaberi iPhone i Run.

Ako `xcodebuild` i dalje gleda u Command Line Tools:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Ako Xcode prijavi da uređaj nije uparen („The device must be paired before it
can be connected“), upari ga iz Terminala:

```bash
xcrun devicectl manage pair --device <UDID>
xcrun devicectl list devices
```

Telefon mora biti otključan. Posle uparivanja Xcode Run i `devicectl` instalacija
rade normalno.

## IPA za AltStore/SideStore

```bash
bash scripts/napravi-ipa.sh
```

Skripta pravi nepotpisan `build/DiktatorIOS.ipa`; AltStore/SideStore ga
potpisuje tvojim Apple ID-jem.

## Napomene

- Nema App Group-a; aplikacija i tastatura dele samo clipboard.
- Tastatura ne može da snima (Apple zabranjuje mikrofon u extension-ima).
- Modeli se ne commituju; preuzimaju se u aplikaciji.
- `vendor-ios/` i `build/` su u `.gitignore`.
- App Store/TestFlight detalji: [../docs/distribucija.md](../docs/distribucija.md).

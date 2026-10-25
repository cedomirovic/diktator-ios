# Plan · Diktator iOS

## 1. Arhitektura (potvrđena)

```text
┌─────────────────────────────┐        ┌──────────────────────────────┐
│  DiktatorIOS (glavna app)   │        │  DiktatorKeyboard (extension)│
│                             │        │                              │
│  mikrofon → AVAudioEngine   │        │  puna QWERTY tastatura       │
│  whisper.cpp → tekst        │        │  [Diktiraj] → diktator-ios://│
│  UIPasteboard.general = txt │        │  [Nalepi] ← clipboard        │
│  istorija / rečnik / modeli │        │  textDocumentProxy.insert    │
└──────────────┬──────────────┘        └──────────────┬───────────────┘
               │                                      │
               └────────── UIPasteboard ──────────────┘
                     (nema App Group-a)
```

### Tok rada

1. Korisnik u bilo kojoj aplikaciji prebaci tastaturu na **Diktator**.
2. Tapne **Diktiraj** — tastatura otvara glavnu aplikaciju preko
   `diktator-ios://dictate` (`extensionContext.open`).
3. Aplikacija odmah počinje snimanje (ili pokaže veliko dugme za snimanje).
4. Posle prepisa aplikacija kopira tekst u `UIPasteboard.general` i prikaže
   „Tekst je spreman — vrati se i nalepi“.
5. Korisnik se vrati u prethodnu aplikaciju preko statusne trake
   („Back to …“) ili app switcher-a.
6. Tastatura prikaže **Nalepi**; tap ubaci tekst u aktivno polje.

### Zašto ne tastatura snima

Apple ne dozvoljava nijednom app extension-u pristup mikrofonu. Zato je
arhitektura „app snima, tastatura ubacuje“ jedina koja radi na iOS-u bez
privatnih API-ja.

### Zašto ne App Group

App Groups su capability koji traži plaćeni Apple Developer Program. Sa
besplatnim Apple ID-jem nije dostupan. Clipboard je sistemski kanal koji radi
bez App Group-a; tastatura ga čita samo kada korisnik uključi **Full Access**.

## 2. Komponente

### Glavna aplikacija `DiktatorIOS`

- SwiftUI, minimum iOS 17.
- `DiktatorApp` — ulaz, URL scheme `diktator-ios`, stanje.
- `Snimac` — `AVAudioEngine`, 16 kHz mono, ograničenje 5 min.
- `Prepisivac` — whisper.cpp C API; jezik `auto` (sr/en), režim kvalitet /
  štedljiv.
- `Tekst` / `Transliteracija` — ćirilica → latinica, čišćenje.
- `PonudaModela` — Tiny/Base/Small/Turbo/Large; za iOS kvantizovani modeli.
- `Preuzimanje` — URLSession download sa proverom veličine.
- `Podesavanja` — UserDefaults; API ključevi u Keychain-u.
- `Istorija`, `Recnik`, `PogledPomoc`, `PogledPodesavanja`.
- `Clipboard` — upis u `UIPasteboard.general`.
- Podrazumevani model: **Large v3 Turbo q5_0** (~547 MB).

### Tastatura `DiktatorKeyboard`

- `UIInputViewController`, puna tastatura.
- QWERTY slova, srpska slova `čćžšđ`, brojevi, shift, brisanje, razmak,
  enter, globus.
- Gornja traka: **Diktiraj** i **Nalepi**.
- **Diktiraj**:
  `extensionContext?.open(URL(string: "diktator-ios://dictate")!)`.
- **Nalepi**: čita `UIPasteboard.general.string` i zove
  `textDocumentProxy.insertText`.
- Bez mreže i bez čuvanja istorije u tastaturi.
- `RequestsOpenAccess = true` u `Info.plist`; korisnik mora da uključi
  **Allow Full Access**.

## 3. Whisper.cpp na iOS-u

- Statička biblioteka za `arm64` (iPhone), Metal + Accelerate.
- Skripta `app/pripremi-whisper-ios.sh` (po uzoru na macOS
  `app/pripremi-whisper.sh`):
  - CMake sa `CMAKE_SYSTEM_NAME=iOS`,
    `CMAKE_OSX_ARCHITECTURES=arm64`,
    `CMAKE_OSX_DEPLOYMENT_TARGET=17.0`;
  - `WHISPER_METAL=ON`, `WHISPER_BLAS=ON` (Accelerate);
  - proizvodi `libwhisper.a`, `libggml*.a` i Metal shader.
- Modeli se ne stavljaju u git; preuzimaju se u
  `Application Support/Diktator/models/`.
- Podrazumevano: **Turbo q5_0** (~547 MB); opcije Small q5_1 (~181 MB),
  Base q5_1 (~57 MB), Large v3 q5_0 (~1 GB).

## 4. Xcode projekat

- Dva targeta:
  - `DiktatorIOS` (application), bundle ID
    `com.cedomirovic.diktator.ios`;
  - `DiktatorKeyboard` (app extension), bundle ID
    `com.cedomirovic.diktator.ios.keyboard`.
- Bez App Group entitlement-a.
- `Info.plist` aplikacije:
  - `NSMicrophoneUsageDescription`;
  - URL scheme `diktator-ios`.
- `Info.plist` tastature:
  - `NSExtensionPointIdentifier = com.apple.keyboard-service`;
  - `RequestsOpenAccess = true`;
  - `PrimaryLanguage = sr`;
  - `IsASCIICapable = false`.
- Potpisivanje: free Personal Team u Xcode-u; bez posebnih capability-ja.
- Projektni fajl se pravi ručno ili preko XcodeGen-a (dev alat, nije runtime
  zavisnost); odluka posle instalacije Xcode-a.

## 5. Faze

1. **Skelet** — folder, git, dokumentacija, odluke. ✅
2. **GitHub** — repo, README, licenca, prvi push. ✅
3. **Xcode projekat** — app + keyboard target, Swift kod. ✅ (build čeka Xcode)
4. **Whisper iOS** — skripta `pripremi-whisper-ios.sh`; build čeka Xcode.
5. **Snimanje i prepis** — kod portovan; test čeka build.
6. **Clipboard i tastatura** — kod za Diktiraj/Nalepi i punu tastaturu;
   test čeka build.
7. **Modeli i podešavanja** — download, izbor modela, režim; test čeka build.
8. **Istorija/rečnik** — kod u glavnoj aplikaciji; test čeka build.
9. **Instalacija** — uputstvo i skripta za IPA; test čeka build.
10. **Release** — tag, zip/IPA, uputstvo; posle testa na iPhone-u.

## 6. Rizici

- **7 dana** — besplatni profil ističe; korisnik mora da obnovi build.
- **Full Access** — bez njega tastatura ne može da čita clipboard; ostaje
  ručno lepljenje.
- **Dva prelaska između aplikacija** — iOS ne dozvoljava automatski povratak;
  statusna traka „Back to …“ je najbrži put.
- **Memorija** — Turbo model je ~547 MB; na starijim iPhone-ima može da bude
  tesno. Zato Small/Base ostaju opcije.
- **Xcode** — trenutno nije instaliran; bez njega nema builda ni potpisa.
- **App Store** — tastatura sa Full Access-om je osetljiva za review; ovo je
  za sada sideload/lična instalacija, ne App Store distribucija.
- **Apple Speech** — ne podržava srpski; ne koristimo ga za srpski.

## 7. Alternative (razmotrene)

- **Samo glavna aplikacija + clipboard**: najjednostavnije, ali korisnik mora
  ručno da nalepi tekst; bez tastature.
- **App Group + tastatura**: i dalje tastatura ne može da snima; App Group samo
  deli tekst/podešavanja, a traži plaćeni nalog. Nema prednost za snimanje.
- **Cloud prepis**: brži i lakši, ali krši privatnost i cilj projekta.
- **Apple Speech**: nema srpski; otpada.
- **LLM doterivanje**: nije u MVP-u; može kasnije, opciono.

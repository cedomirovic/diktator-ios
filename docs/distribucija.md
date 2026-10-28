# Distribucija: sideload, TestFlight i App Store

Ovaj dokument objašnjava kako **Diktator iOS** može da dođe do korisnika.
**Sideload** (Xcode/AltStore/SideStore) je potvrđen, a **TestFlight** i
**App Store** su pripremljeni u repou i čekaju plaćeni Apple Developer Program
i app record. Metadata, Review Notes i checklist su u
[app-store.md](app-store.md).

## Pregled načina

| Način | Trošak | Trajanje | Za koga |
|---|---:|---|---|
| **App Store** | 99 USD/god. | nema 7-dnevnog isteka | svi sa kompatibilnim iPhone/iPad-om |
| **TestFlight** | 99 USD/god. | build traje 90 dana | do 10.000 spoljnih testera |
| **Ad Hoc** | 99 USD/god. | do 1 godine | do 100 registrovanih uređaja |
| **AltStore/SideStore** | 0 USD | 7 dana (free) ili 1 godina (paid) | tehnički korisnici; svako potpisuje sam |
| **Enterprise** | 299 USD/god. | do 1 godine | samo zaposleni; **nije** za javnost |

Preporuka: prvo **TestFlight** sa 5–10 ljudi, pa **App Store**. Tako se hvataju
problemi sa tastaturom, Full Access-om i preuzimanjem modela pre javnog izdanja.

## Nalog

### Individual

- **99 USD godišnje** (ili u lokalnoj valuti).
- Seller na App Store-u je **tvoje pravno ime**.
- Potrebni su Apple ID sa **dvo-faktorskom autentifikacijom**, punoletstvo i
  važeći podaci za plaćanje.
- Najjednostavniji put za lični projekat.

### Organization

- Isto **99 USD godišnje**, ali seller je **firma**.
- Potreban je **D-U-N-S broj** i pravno lice.
- Bolje ako želiš brend „Diktator“ bez ličnog imena u seller polju.

### Tuđi nalog

Tehnički je moguće da te vlasnik naloga doda u **App Store Connect** tim kao
**Admin** ili **App Manager** i da ti uploaduješ build. Ali:

- aplikacija pripada **tom timu**, a seller je ta osoba/firma;
- **Account Holder** potpisuje ugovore, kontroliše plaćanje, brisanje i transfer;
- ne deli Apple ID ni 2FA — koristi **svoj Apple ID** kao član tima;
- ako se odnos pokvari, gubiš pristup; transfer app-a je moguć, ali nije
  zagarantovan i traži obe strane.

Ako baš ideš tim putem, napravite kratak pisani dogovor ko je vlasnik app-a i
šta se dešava ako se saradnja prekine. **Ne kupuj „shared“ naloge** — Apple ih
gasi, a app može biti uklonjena.

## App Store: koraci

1. **Uplati Apple Developer Program** i prihvati ugovore u App Store Connect-u.
2. **Napravi app record**:
   - Bundle ID: `com.cedomirovic.diktator.ios`
   - Ime: **Diktator**
   - Primarni jezik: **English (U.S.)** (srpski trenutno nije ponuđen za
     metadata; UI aplikacije može ostati srpski)
   - Kategorija: **Productivity**
   - Cena: **Free**
3. **Potpisivanje za distribuciju**:
   - U Xcode-u izaberi plaćeni tim za oba targeta.
   - Napravi **Archive** (Product → Archive).
   - U Organizer-u izaberi **Distribute App → App Store Connect**.
4. **Privacy**:
   - `PrivacyInfo.xcprivacy` u glavnoj aplikaciji.
   - Privacy policy URL i support URL.
   - U App Store Connect-u prijavi **Data Not Collected** ako nema analitike.
5. **Metadata**:
   - opis, ključne reči, support URL, marketing URL (opciono);
   - screenshots za **iPhone** i **iPad** (target je `1,2`);
   - ikonica 1024×1024;
   - age rating, export compliance.
6. **TestFlight**:
   - prvo internal testeri;
   - zatim external testeri (prvi build prolazi Beta App Review).
7. **Review Notes** — vidi poseban odeljak ispod.
8. **Submit for Review** i izaberi release (ručno ili automatski).

Ručni archive iz Terminala:

```bash
xcodebuild -project app/DiktatorIOS.xcodeproj \
  -scheme DiktatorIOS \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/DiktatorIOS.xcarchive \
  -allowProvisioningUpdates archive
```

Posle toga otvori `build/DiktatorIOS.xcarchive` u Xcode Organizer-u i uploaduj.

## Specifično za Diktator iOS

### Full Access i tastatura

- Tastatura traži **Allow Full Access** da bi čitala clipboard i otvorila
  matičnu aplikaciju dugmetom **Diktiraj** na iOS 26+.
- Bez Full Access-a tastatura i dalje **kuca** (QWERTY, `čćžšđ`, brojevi), pa
  ispunjava Apple zahtev da bude funkcionalna bez Full Access-a.
- U Review Notes objasni da se clipboard čita **samo** kada korisnik tapne
  **Nalepi**, i da se sve dešava lokalno.

### Guideline 4.4.1

Apple traži da keyboard extension ne pokreće „druge aplikacije osim Settings“.
Otvaranje **sopstvene** aplikacije je u praksi prolazilo (npr. „Dictator
Offline Voice to Text“ je na App Store-u sa istim principom), ali to je deo
koji treba jasno objasniti u Review Notes.

Ako App Review ipak odbije:

- ukloni otvaranje aplikacije iz tastature;
- **Diktiraj** neka samo prikaže uputstvo „Otvori Diktator iz app switcher-a“;
- otvaranje prebaci na **Control Center**, **Shortcut** ili **Action Button**.

### Mikrofon

- Mikrofon koristi **samo glavna aplikacija**; keyboard extension ga ne dobija.
- `NSMicrophoneUsageDescription` mora biti jasno napisan.
- Audio se ne šalje na server; nema analitike ni naloga.

### Modeli

- Large v3 q5_0 je ~1,0 GB; Turbo q5_0 ~547 MB; Base/Small su manji.
- Model je **podatak**, ne izvršni kod; sve inference radi lokalno.
- U Review Notes navedi da reviewer može brzo da testira sa **Base** ili
  **Turbo** modelom, a Large v3 je preporučen za srpski.
- Preuzimanje treba da ima progress, preporuku za Wi-Fi, proveru prostora i
  mogućnost ponovnog pokušaja.
- Uključi licence: whisper.cpp i OpenAI Whisper su MIT; proveri i napomene za
  model weights.

### Uređaji

- Minimum iOS 17; testirano na iPhone 15 Pro, iOS 27.0.1.
- Large v3 traži više RAM-a; na starijim uređajima preporuči **Turbo** ili
  **Small**.
- App je universal (`iPhone` + `iPad`), pa su potrebni i iPad screenshots.

### App Group

- Nije obavezan; trenutno aplikacija i tastatura dele samo clipboard.
- Sa plaćenim nalogom se kasnije može dodati App Group za čitanje teksta bez
  clipboarda, ali to menja entitlements i potpisivanje.

## Privacy manifest

`PrivacyInfo.xcprivacy` postoji u **oba** targeta
(`app/DiktatorIOS/PrivacyInfo.xcprivacy` i
`app/DiktatorKeyboard/PrivacyInfo.xcprivacy`). Prijavljeno je:

- `UserDefaults` — reason `CA92.1` (čitanje sopstvenih podešavanja);
- file timestamp/attribute API — reason `C617.1` (fajlovi u sopstvenom
  kontejneru).

Nema tracking-a, reklama ni prikupljanja podataka. U App Store Connect-u
prijavi **Data Not Collected**. U oba `Info.plist`-a je
`ITSAppUsesNonExemptEncryption = NO` (koristi se samo standardni TLS i
SHA-256 iz CryptoKit-a).

Provera da su manifesti u buildu:

```bash
ls build/DiktatorIOS.xcarchive/Products/Applications/Diktator.app/PrivacyInfo.xcprivacy
ls build/DiktatorIOS.xcarchive/Products/Applications/Diktator.app/PlugIns/DiktatorKeyboard.appex/PrivacyInfo.xcprivacy
```

## Stranice za App Store

Objavljene su preko GitHub Pages-a iz foldera `docs/`:

- Politika privatnosti: <https://cedomirovic.github.io/diktator-ios/privatnost.html>
- Podrška: <https://cedomirovic.github.io/diktator-ios/podrska.html>

Izvorni fajlovi su `docs/privatnost.html` i `docs/podrska.html`; ako se
promene, dovoljan je commit i push na `main`.

## Skripte

```bash
# Arhiva + upload u App Store Connect (TestFlight)
app/objavi-testflight.sh

# Isto, preko App Store Connect API ključa (pogodno za CI)
ASC_KEY_PATH=~/kljucevi/AuthKey_ABC123.p8 \
ASC_KEY_ID=ABC123 \
ASC_ISSUER_ID=00000000-0000-0000-0000-000000000000 \
app/objavi-testflight.sh

# Snimci ekrana za App Store (iPhone 6.9" i iPad 13")
app/uzmi-snimke.sh
```

`app/objavi-testflight.sh` pre arhive proverava da postoji **Apple
Distribution** sertifikat i da su privacy manifesti u arhivi. Ako sertifikata
nema, ispiše uputstvo i prekine.

## Snimci ekrana

Snimci su u `docs/slike/app-store/` i imaju tačne rezolucije koje App Store
Connect traži:

| Fajl | Rezolucija |
|---|---|
| `iPhone-17-Pro-Max-*.png` | 1320 × 2868 (6.9") |
| `iPad-Pro-13-inch-M5-*.png` | 2064 × 2752 (13") |

Brojevi u imenu su tabovi: `0` Diktat, `1` Istorija, `3` Podešavanja, `4`
Pomoć. Skripta pravi snimke iz simulatora; za lepši prvi kadar pokreni
diktat na uređaju i snimi ekran ručno.

Snimak **tastature u drugoj aplikaciji** skripta ne može da napravi — custom
tastatura se u simulatoru dodaje ručno (Settings → General → Keyboard →
Keyboards → Add New Keyboard), pa se taj kadar snima ručno.

## Checklist pre slanja

- [ ] Plaćeni Apple Developer Program i tim za oba targeta.
- [x] Verzija i build broj podignuti (`0.2.0 (10)`).
- [x] `PrivacyInfo.xcprivacy` dodat i proveren.
- [x] Privacy policy i support URL postoje (GitHub Pages).
- [x] App Store opis, ključne reči i screenshots (iPhone + iPad).
- [ ] Review Notes sa Full Access, lokalnom obradom i modelima.
- [ ] TestFlight internal + external.
- [ ] AltStore/SideStore tok testiran (opciono, za sideload).
- [ ] Provereno da app radi i bez Full Access-a (kucanje).
- [ ] Provereno da se model preuzima sa čistom greškom i ponovnim pokušajem.

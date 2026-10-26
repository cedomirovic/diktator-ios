# Distribucija: sideload, TestFlight i App Store

Ovaj dokument objašnjava kako **Diktator iOS** može da dođe do korisnika.
Trenutno je potvrđen **sideload** (Xcode/AltStore/SideStore); **TestFlight** i
**App Store** su sledeći korak i traže plaćeni Apple Developer Program.

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

Za App Store je potreban `PrivacyInfo.xcprivacy`. Aplikacija koristi:

- `UserDefaults` — reason `CA92.1` (čitanje sopstvenih podešavanja);
- file timestamp/attribute API — reason `C617.1` (fajlovi u sopstvenom
  kontejneru).

Nema tracking-a, reklama ni prikupljanja podataka. U App Store Connect-u
prijavi **Data Not Collected**.

## Checklist pre slanja

- [ ] Plaćeni Apple Developer Program i tim za oba targeta.
- [ ] Verzija i build broj podignuti (npr. `0.1.1 (2)`).
- [ ] `PrivacyInfo.xcprivacy` dodat i proveren.
- [ ] Privacy policy i support URL postoje.
- [ ] App Store opis, ključne reči i screenshots (iPhone + iPad).
- [ ] Review Notes sa Full Access, lokalnom obradom i modelima.
- [ ] TestFlight internal + external.
- [ ] AltStore/SideStore tok testiran (opciono, za sideload).
- [ ] Provereno da app radi i bez Full Access-a (kucanje).
- [ ] Provereno da se model preuzima sa čistom greškom i ponovnim pokušajem.

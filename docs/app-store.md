# App Store: metadata i odgovori za prijavu

Ovaj dokument sadrži tekst koji se lepi u **App Store Connect**. Ništa ovde
nije tajna i sve može u git.

- Aplikacija: **Diktator**
- Bundle ID: `com.cedomirovic.diktator.ios`
- Verzija u prijavi: `0.2.0 (10)` (vidi `app/project.yml`)
- Privacy policy: <https://cedomirovic.github.io/diktator-ios/privatnost.html>
- Support: <https://cedomirovic.github.io/diktator-ios/podrska.html>
- Marketing (opciono): <https://github.com/cedomirovic/diktator-ios>

## App Information

| Polje | Vrednost |
|---|---|
| Name | Diktator |
| Subtitle (30) | Serbian dictation, on device |
| Primary language | English (U.S.) |
| Bundle ID | com.cedomirovic.diktator.ios |
| SKU | `diktator-ios-001` |
| Primary category | Productivity |
| Secondary category | Utilities |
| Price | Free |
| Age rating | 4+ |
| Made for Kids | No |

## Languages

- **Primary:** English (U.S.) — `CFBundleDevelopmentRegion = en`.
- **Secondary:** Serbian (Latin) — `sr.lproj`.
- Interfejs se prevodi preko `en.lproj` / `sr.lproj`
  (`Localizable.strings` i `InfoPlist.strings`); srpski prevod je identitet, a
  neprevedeni ključ uvek ostaje srpski.
- U App Store Connect-u dodaj **Serbian (Latin)** kao dodatni jezik i popuni
  srpski opis ispod. Engleski je primarni, pa Review Notes i metadata idu na
  engleskom.

## Promotional text (170)

Engleski (primarni):

```
Dictate in Serbian or English and the text lands in any app. Transcription runs
on your iPhone; cloud services only if you turn them on.
```

Srpski:

```
Diktiraj na srpskom ili engleskom i tekst se sam ubaci u bilo koju aplikaciju.
Prepis ide na tvom iPhone-u; servisi u oblaku samo ako ih sam uključiš.
```

## Description (EN, primary)

```
Diktator turns speech into text on your iPhone and iPad — in Serbian and
English — and inserts it into whatever app you are typing in.

Transcription runs on your device, so no account is needed and your recordings
are never stored. There are no ads and no analytics. Cloud services are off by
default and work only if you turn them on with your own API key.

HOW IT WORKS
1. Add the Diktator keyboard in iOS Settings and allow Full Access.
2. Download a speech model once (Turbo ~547 MB, Large v3 ~1.0 GB).
3. In any app, tap Dictate on the Diktator keyboard and speak.
4. Tap Stop. The text is inserted automatically — no copy and paste.

FEATURES
• Serbian and English, including č, ć, ž, š, đ
• Local transcription with Whisper (whisper.cpp)
• Automatic paste into any app, with a manual Paste button as backup
• 15-minute background session, renewed with every dictation
• History, custom vocabulary and statistics
• Optional cloud transcription with Groq for ~1 second results
• Optional text refinement with Gemini, OpenAI, Claude, DeepSeek or Ollama
• API keys stay in the iOS Keychain
• Works offline after the model is downloaded

PRIVACY
Audio is transcribed on device and discarded. The app has no account and no
telemetry. Network is used only to download models and, if you explicitly enable them,
the optional cloud services above. The App Store build does not check GitHub
for updates.

The keyboard needs Full Access for two things only: to read the clipboard when
you tap Paste, and to fetch the finished transcript from the app over a local
server on 127.0.0.1. Without Full Access it still types normally.
```

## Description (SR, secondary)

```
Diktator pretvara govor u tekst na iPhone-u i iPad-u — na srpskom i engleskom —
i ubacuje ga u aplikaciju u kojoj upravo kucaš.

Prepis ide na tvom uređaju, pa nalog nije potreban, a snimci se ne čuvaju. Nema
reklama ni analitike. Servisi u oblaku su isključeni dok ih sam ne uključiš,
sa svojim API ključem.

KAKO RADI
1. Dodaj tastaturu Diktator u iOS Podešavanjima i uključi Full Access.
2. Jednom preuzmi model (Turbo ~547 MB, Large v3 ~1,0 GB).
3. U bilo kojoj aplikaciji tapni Diktiraj u traci iznad tastature Diktator i govori.
4. Tapni Stop. Tekst se sam ubacuje — bez kopiranja i lepljenja.

MOGUĆNOSTI
• Srpski i engleski, uključujući č, ć, ž, š, đ
• Lokalni prepis preko Whisper-a (whisper.cpp)
• Automatsko lepljenje u svaku aplikaciju, uz ručno Nalepi kao rezervu
• Pozadinska sesija od 15 minuta, produžava se svakim diktatom
• Istorija, rečnik i statistika
• Opcioni prepis u oblaku preko Groq-a (~1 s)
• Opciono doterivanje teksta preko Gemini, OpenAI, Claude, DeepSeek ili Ollama
• API ključevi ostaju u iOS Keychain-u
• Radi i bez mreže kada je model preuzet

PRIVATNOST
Zvuk se prepisuje na uređaju i odbacuje. Aplikacija nema nalog ni telemetriju.
Mreža se koristi samo za preuzimanje modela i, ako ih sam uključiš, opcione
servise u oblaku. App Store verzija ne proverava GitHub.

Tastatura traži Full Access za dve stvari: da pročita clipboard kada tapneš
Nalepi i da preuzme gotov prepis iz aplikacije preko lokalnog servera na
127.0.0.1. Bez Full Access-a i dalje normalno kuca.
```

## Keywords (100, EN)

```
dictation,speech to text,voice typing,serbian,transcription,offline,keyboard,voice,notes
```

## Keywords (SR)

```
diktiranje,glas u tekst,srpski,prepis,offline,tastatura,transkripcija,beleške
```

## URLs

| Polje | Vrednost |
|---|---|
| Support URL | https://cedomirovic.github.io/diktator-ios/podrska.html |
| Privacy Policy URL | https://cedomirovic.github.io/diktator-ios/privatnost.html |
| Marketing URL | https://github.com/cedomirovic/diktator-ios |

## App Privacy (App Store Connect)

Koraci u App Store Connect → **Apps → Diktator → App Privacy**:

1. **Get Started** (ili **Edit** ako je upitnik već otvoren).
2. Pitanje **„Do you or your third-party partners collect data from this
   app?“** → **No**.
3. **Save**, pa **Publish**.

Ni jedan tip podataka se ne označava (Contact Info, Health, Audio, User
Content…), jer aplikacija ne šalje podatke programeru ni trećim licima u ime
programera.

- **Data Collection:** *Data Not Collected*.
- Obrazloženje za Review Notes: sve se obrađuje na uređaju; opcioni Groq i
  LLM servisi rade samo ako ih korisnik uključi i unese **svoj** ključ, pa
  programer ne dobija kopiju podataka.
- `PrivacyInfo.xcprivacy` je dodat u oba targeta: nema tracking-a, nema
  prikupljanja, prijavljeni su `UserDefaults` (`CA92.1`) i file timestamp
  (`C617.1`). Manifest i odgovor u upitniku moraju da se poklope — oba kažu
  da nema prikupljanja.
- Zašto ipak „Data Not Collected“ kada postoje Groq i LLM servisi: podatke
  šalje sam korisnik, svom nalogu, svojim ključem, i to samo ako uključi
  servis i da izričitu dozvolu. Programer ne dobija kopiju, nema svog servera
  i ne može da poveže podatke sa korisnikom. Ovo isto napisati u Notes.

### Šta se ne prijavljuje i zašto

| Podatak | Gde završi | Zašto nije „collected“ |
|---|---|---|
| Snimak govora | Obrađuje se u memoriji i odbacuje | Ne napušta uređaj i ne čuva se |
| Tekst diktata | Istorija u aplikaciji (do 200 zapisa) | Ostaje na uređaju dok ga korisnik ne obriše |
| Rečnik i statistika | Lokalni fajlovi | Bez teksta diktata, bez naloga |
| API ključevi | Keychain (`WhenUnlockedThisDeviceOnly`) | Ne napuštaju uređaj |
| Groq / LLM tekst | Samo uz dozvolu, na korisnikov nalog | Programer ne dobija kopiju i ne može da poveže podatke |

## Age Rating (App Store Connect)

App Store Connect → **App Information → Age Rating → Edit**. Odgovori za
verziju **0.2.0**:

| Pitanje | Odgovor |
|---|---|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Prolonged Graphic or Sadistic Realistic Violence | None |
| Profanity or Crude Humor | None |
| Mature or Suggestive Themes | None |
| Horror/Fear Themes | None |
| Medical/Treatment Information | None |
| Alcohol, Tobacco, or Drug Use or References | None |
| Simulated Gambling | None |
| Sexual Content or Nudity | None |
| Graphic Sexual Content and Nudity | None |
| Guns or Other Weapons | None |
| Gambling and Contests | None |
| Unrestricted Web Access | No |
| User-Generated Content | No |
| Messaging and Chat | No |
| Advertising | No |
| In-App Purchases | No |
| Age Assurance | No |
| Made for Kids / Kids Category | No |

Rezultat je **4+**. Obrazloženje ako recenzent pita: aplikacija nema svoj
sadržaj, feed, chat ni pretragu; korisnik diktira sopstveni tekst koji ostaje
na uređaju. Opcioni servisi u oblaku šalju samo tekst koji je korisnik sam
izdiktirao, njegovim ključem i uz njegovu dozvolu.

**Ne prepisivati 4+ naslepo** ako se u međuvremenu promeni sadržaj aplikacije
(npr. doda deljenje teksta u zajednicu) — tada ponovo proći upitnik.

## Sitnice u kodu (tačka 14)

- **`IsASCIICapable`** je sada `true` u `project.yml` i u
  `DiktatorKeyboard/Info.plist`. Tastatura je latinična i treba da se pojavi i
  u poljima tipa `UIKeyboardTypeASCIICapable` (mejl, URL); `čćžšđ` su dodatni
  znaci, ne drugi alfabet.
- **Globus** se dodaje samo kada `needsInputModeSwitchKey` kaže da jeste, pa
  se na iPad-u sa hardverskom tastaturom ne duplira.
- **Dnevnik** se skraćuje na 200 KB (zadržava poslednjih 100 KB, od početka
  reda), pa ne raste bez granice.
- **Opšti clipboard** se posle diktata puni samo kada je diktat pokrenut iz
  same aplikacije. Kada diktat pokreće tastatura, tekst ide imenovanim
  pasteboard-om i lokalnim serverom, pa ga druge aplikacije ne vide; ručno
  **Nalepi** i dalje radi iz imenovanog kanala. `docs/privatnost.html` (SR i
  EN) opisuje tačno to ponašanje.

## Export compliance

- Koristi se samo standardni HTTPS/TLS iz iOS-a (`URLSession`) i `CryptoKit`
  za SHA-256 izvođenje lokalnog ključa.
- Odgovor: **„No“** na pitanje da li aplikacija koristi kriptografiju, uz
  napomenu da je u pitanju samo Apple-ov standardni TLS/SHA.
- Ako App Store Connect traži `ITSAppUsesNonExemptEncryption`, postavi na
  `NO` (dodato u `Info.plist`).

## Tim i nalog

Stanje na Mac-u (06.11.2026): tim **`LHQ4Q44425`** je besplatni lični tim,
postoji samo **Apple Development** sertifikat, a razvojni profili za oba
bundle ID-a ističu **09.11.2026.** Nema **Apple Distribution** sertifikata ni
App Store profila, pa u ovom stanju build ne može u App Store Connect. To se
menja tek kada proradi plaćeni Developer Program.

`app/proveri-potpis.sh` čita `project.yml`, `ExportOptions.plist`, pbxproj,
Keychain i profile, pa tačno pokaže šta nedostaje:

```sh
app/proveri-potpis.sh              # tim iz project.yml
app/proveri-potpis.sh ABCDE12345   # provera drugog tima
```

### Kada proradi plaćeni nalog

1. Prihvati ugovore u App Store Connect-u i zapiši novi **Team ID**.
2. Upiši ga na dva mesta: `DEVELOPMENT_TEAM` u `app/project.yml` i `teamID` u
   `app/ExportOptions.plist`.
3. `cd app && xcodegen generate` (pbxproj preuzme tim iz `project.yml`).
4. Xcode → Settings → Accounts → tim → **Manage Certificates** → **+** →
   **Apple Distribution**.
5. `app/proveri-potpis.sh` mora da prijavi ✓ za tim, sertifikat i App Store
   profile za oba bundle ID-a.
6. `app/objavi-testflight.sh` arhivira sa `DEVELOPMENT_TEAM` i
   `CODE_SIGN_IDENTITY="Apple Distribution"`, a pre slanja odbija arhivu
   potpisanu razvojnim sertifikatom. Za privremenu probu drugog tima:
   `DIKTATOR_TIM=ABCDE12345 app/objavi-testflight.sh`.

### Vlasništvo podataka

Bundle ID, GitHub Pages i mejl podrške (`cedomirovicnemanja@gmail.com`) vezani
su za drugu osobu, pa prodavac u App Store Connect-u, kontakt i URL-ovi treba
da pripadaju onome ko objavljuje. Dve čiste opcije:

- **Objavljuje vlasnik naloga** kome pripada `com.cedomirovic.diktator.ios` —
  tada se menja samo tim u koracima iznad.
- **Objavljuješ sa svog naloga** — tada promeni bundle ID (npr.
  `com.<tvoj>.diktator.ios`) na svim mestima: `PRODUCT_BUNDLE_IDENTIFIER` za
  aplikaciju i tastaturu i `CFBundleURLName` u `app/project.yml`,
  `CFBundleURLSchemes`/`Info.plist` ako se menja šema, `Podesavanja.servis`
  (Keychain), `app/proveri-potpis.sh`, `app/uzmi-snimke.sh` i ovaj dokument.
  Zatim napravi novi app record i postavi svoje GitHub Pages URL-ove i mejl.

Ni u jednoj varijanti ne treba menjati šemu `diktator-ios` ako je već
objavljena — stari linkovi iz tastature bi prestali da rade.

## Review Notes (App Review Information → Notes, 2.1)

Apple traži odgovor na **Guideline 2.1**. Celina ispod pokriva svih šest
traženih stavki i lepi se u **App Review Information → Notes**. Link za video
zameni svojim; ako Apple traži još nešto, odgovori se dopisuju u isti blok.

```
Thank you for the review. Diktator is a dictation app for Serbian and English.
Speech is transcribed on the device with whisper.cpp and inserted into any app
through our keyboard. There are no accounts, no user-generated content
features and no paid content, so account, UGC and purchase flows do not apply.

1) SCREEN RECORDING (physical device, submitted build)
<LINK>
Recorded on a physical iPhone 15 Pro running iOS 27.0.1. It starts by launching
the app and shows the normal flow: the intro, model download, adding the
keyboard and enabling Full Access, enabling the 15-minute session, dictating
from the Diktator keyboard in Notes, the transcript appearing automatically,
the session expiring, and the user enabling it again.

2) PURPOSE AND AUDIENCE
Problem: iOS does not allow a keyboard extension to use the microphone, and
Apple Speech does not support Serbian. People who write Serbian on a phone
therefore cannot dictate into email, Messages or Notes.
Audience: iPhone and iPad users who write Serbian or English, including
accessibility users and privacy-conscious users who do not want audio or text
in the cloud.
Value: private, offline dictation in any app, with no account, subscription or
ads. Audio is processed on device and discarded; text stays in local history
unless the user deletes it.

3) SETUP AND ACCESS
No login, credentials or sample files are needed.
1. Diktator > Settings > Model: download "Base" (~142 MB, enough for review).
2. iOS Settings > General > Keyboard > Keyboards > Add New Keyboard >
   Diktator, then enable "Allow Full Access".
3. Diktator > "Enable session" (max 15 minutes; the keyboard never extends or
   opens the app).
4. In Notes or Messages switch to the Diktator keyboard, tap "Dictate", speak,
   then "Stop". The text appears automatically; "Paste" is the manual
   fallback.
English is detected automatically. Serbian is used on a Serbian system or can
be selected in Settings.

4) EXTERNAL SERVICES
- huggingface.co: model download only; no user data is sent.
- whisper.cpp: open-source engine bundled in the app, runs entirely on device
  (not an external service).
- Optional, off by default, with the user's own API key and explicit
  per-service permission: Groq (audio transcription), and Gemini, OpenAI,
  Claude, DeepSeek, Ollama or any OpenAI-compatible endpoint (text cleanup
  only). The developer has no server and receives no data.
- No authentication, analytics, advertising, payment or crash-reporting
  services. The keyboard receives the transcript from the app over a local
  server bound to 127.0.0.1 with a per-device secret token.

5) REGIONS
The app behaves the same in all regions. The UI is in English and Serbian;
dictation supports Serbian and English. There are no region-specific features
or content. Model download needs internet; optional cloud features depend on
the user's provider and key.

6) REGULATED INDUSTRY / THIRD-PARTY MATERIAL
Not a regulated industry. Third-party material: whisper.cpp (MIT) and Whisper
model weights (MIT), downloaded by the user from Hugging Face. No music,
video, trademarks or other protected content. No authorization documents are
required.

ADDITIONAL CONTEXT
- No account creation, login or deletion, because there are no accounts.
- No user-generated content, feed, sharing, chat or profiles; dictated text
  stays in the user's local history.
- No paid content, in-app purchases or subscriptions.
- The keyboard types without Full Access; Full Access is used only to read the
  clipboard on "Paste" and to fetch the transcript over the local channel. The
  extension never records audio.
- Tested on a physical iPhone 15 Pro (iOS 27.0.1); the iPad layout was verified
  in the simulator. The App Store build caps the background session at 15
  minutes; audio outside an active dictation is discarded.
```

## Test na uređaju i demo video (tačka 5)

Tačka 5 analize (mikrofon u pripravnosti, pravilo 2.5.4) ne može da se proveri
u simulatoru: tamo se custom tastatura ne uključuje skriptom, a pozadinski
audio se ponaša drugačije. Zato pre prijave treba proći ovo na fizičkom
uređaju i snimiti kratak demo.

### Protokol (najslabiji podržani uređaji)

1. **iPhone XR ili noviji sa 3 GB RAM-a** i **iPad 9. generacije** (iOS/iPadOS
   17). Obriši aplikaciju, pa je instaliraj iz Xcode-a kao **AppStore** šemu.
2. Prvo pokretanje: prođi uvod, preuzmi **Base** (~142 MB), pa **Large v3**
   (~1.0 GB). Gledaj da li se pojavi upozorenje za memoriju i da li se model
   učita bez pada.
3. Uključi sesiju, pređi u Notes, prebaci na Diktator tastaturu, diktiraj i
   sačekaj automatsko lepljenje. Ponovi 3–4 puta.
4. Ostavi Diktator u pozadini **14 minuta** (ne zaključavaj telefon), pa
   diktiraj iz Notes-a. Proveri: da li iOS prikazuje indikator mikrofona, da
   li tekst stiže i da li se sesija posle 15 minuta sama gasi.
5. Ugasi Diktator iz prekidača aplikacija i diktiraj ponovo: tastatura treba
   da pokaže **Open Diktator and start the session.**, bez otvaranja
   aplikacije.
6. Otvori **Podešavanja → Model → Oslobodi model sada** posle diktata i
   proveri da se memorija vrati; ponovi sa uključenim Large v3.
7. Pošalji kratak diktat sa uključenim Groq-om (sopstveni ključ) i proveri da
   se pre prvog slanja pojavi dijalog **Snimak ide u Groq?** i da **Povuci**
   zaustavlja dalja slanja.

### Snimak za Guideline 2.1

Apple traži **snimak ekrana na fizičkom uređaju**, sa **najnovijim iOS-om** i
**istim buildom koji je u review-u** (najlakše iz TestFlight-a). Snimak mora
da počne **pokretanjem aplikacije** i prikaže uobičajen tok. Link ide u Notes
(YouTube „Unlisted“ ili iCloud link sa javnim pristupom), ne fajl u repou.

Pre snimanja:

1. Instaliraj build iz TestFlight-a (isti koji je poslat Apple-u). Ako želiš
   uvodni tok u kadru, prvo obriši aplikaciju pa je ponovo instaliraj.
2. Utišaj obaveštenja i ukloni lične podatke: prazna istorija, bez tuđih
   poruka, bez prikaza API ključa.
3. Uključi **Screen Recording** u Control Center i proveri da se snima zvuk
   samo ako je potreban (diktat se čuje, ali nije obavezan).

Kadrovi (2–3 minuta, može sa presecima):

1. **Početak snimka:** home screen, tap na ikonu **Diktator** — aplikacija se
   otvara. Prođi uvod ili ga preskoči.
2. **Model:** Podešavanja → Model → preuzmi **Base** (~142 MB). Sačekaj ili
   ubrzaj; pokaži da je model lokalno.
3. **Tastatura:** iOS Podešavanja → General → Keyboard → Keyboards → Add New
   Keyboard → **Diktator**, pa **Allow Full Access**.
4. **Sesija:** Diktator → **Enable session**; vidi se da traje najviše 15
   minuta.
5. **Diktat:** Notes → nova beleška → globus → Diktator tastatura → **Dictate**
   → izgovori rečenicu → **Stop** → tekst se sam pojavi. Ponovi još jednom,
   po mogućstvu na srpskom.
6. **Ručno lepljenje:** ako želiš, pokaži **Paste** kao rezervu.
7. **Istek sesije (opciono):** posle 15 minuta tastatura pokaže **Open
   Diktator and start the session.**, pa ponovno uključivanje.
8. **Kraj:** kratko Istorija ili Podešavanja, bez ličnih podataka.

Snimak ne mora da bude savršen: Apple proverava da aplikacija radi na uređaju,
da nema naloga/UGC/kupovina i da je tok razumljiv. Ako snimaš u delovima,
spojevi su u redu, ali prvi kadar mora biti pokretanje aplikacije.

## Screenshots

Obavezno za App Store Connect:

| Slot | Rezolucija | Kako |
|---|---|---|
| iPhone 6.9" | 1320 × 2868 | `app/uzmi-snimke.sh` (iPhone 17 Pro Max) |
| iPad 13" | 2064 × 2752 | `app/uzmi-snimke.sh` (iPad Pro 13") |
| Tastatura u aplikaciji | 1320 × 2868 | `app/uzmi-snimak-tastature.sh` |

Poželjni kadrovi (5–6):

1. Glavni ekran sa velikim dugmetom **Dictate**.
2. Rezultat u drugoj aplikaciji (Messages) sa tekstom.
3. Podešavanja → **Speed** (Fast / Most accurate / Groq).
4. Istorija.
5. Statistika.
6. Pomoć ili Rečnik.

Snimci su na engleskom, jer je to primarni jezik. `app/uzmi-snimke.sh` gradi
**App Store** šemu, pa na snimcima nema sekcije **Ažuriranja** i vidi se
sesija od 15 minuta.

`app/uzmi-snimke.sh` pravi snimke iz simulatora u
`docs/slike/app-store/`; snimci se prave iz App Store šeme i sa
`-DiktatorBezUvoda 1`, da uvod ne bi ušao u kadar.

**Snimak tastature** (`docs/slike/app-store/tastatura.png`) pravi
`app/uzmi-snimak-tastature.sh`. Simulator ne može da uključi custom tastaturu
skriptom, pa skripta napravi malu probnu aplikaciju
(`app/alati/pregled-tastature/PregledApp.swift`) i u nju ugradi pravi
`KeyboardViewController`. Snimak tako prikazuje stvarni kod tastature sa
tekstom iznad nje. Probna aplikacija se ne gradi u okviru Diktatora i ne ide u
App Store. Ako se snima na uređaju, isti kadar se pravi ručno u Notes-u ili
Messages-u, sa uključenim Full Access-om.

## Checklist za prijavu

- [ ] Plaćeni Apple Developer Program (99 USD/god.) i ugovori prihvaćeni.
- [ ] Novi tim upisan u `project.yml` i `ExportOptions.plist`, pa `xcodegen generate`.
- [ ] App record napravljen sa bundle ID-em `com.cedomirovic.diktator.ios`.
- [ ] Vlasništvo bundle ID-a, GitHub Pages-a i mejla podrške rešeno.
- [ ] Distribution sertifikat i App Store profil (Xcode → Manage Certificates).
- [ ] `app/proveri-potpis.sh` prolazi bez ✗ i ⚠.
- [ ] `PrivacyInfo.xcprivacy` u oba targeta (urađeno).
- [ ] Privacy policy i support URL dostupni (GitHub Pages).
- [ ] Metadata popunjen iz ovog dokumenta.
- [ ] Screenshots za iPhone 6.9" i iPad 13", uključujući tastaturu u aplikaciji.
- [ ] App Privacy upitnik: **Data Not Collected** (koraci iznad).
- [ ] Age rating upitnik popunjen po tabeli iznad (rezultat **4+**).
- [ ] Review Notes nalepljene (uključujući odgovor na Guideline 2.1).
- [ ] Snimak na fizičkom uređaju (2.1) napravljen i link dodat u Notes.
- [ ] Build ponovo poslat na review posle dopune Notes.
- [ ] TestFlight internal build prošao.
- [ ] Snimak za 2.1 počinje pokretanjem aplikacije i prikazuje diktat iz tastature.
- [ ] Export compliance odgovoreno.

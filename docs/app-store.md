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

## Review Notes (lepi u App Store Connect)

```
Diktator is a dictation app for Serbian and English. Speech is transcribed on
the device with the open-source whisper.cpp engine, and the text is inserted
into whatever app the user is typing in. No account is required.

HOW TO TEST QUICKLY (2-3 minutes)
0. On first launch the app shows a four-step intro (model, keyboard, Full
   Access, session). Tap "Skip" in the top-right corner, or follow it.
1. Launch Diktator and open Settings > Model. Download "Base" (~142 MB) or
   "Turbo" (~547 MB). Base is enough to review the flow. Test audio is not
   needed; any sentence works, and English is detected automatically.
2. iOS Settings > General > Keyboard > Keyboards > Add New Keyboard >
   Diktator, then tap it and enable "Allow Full Access".
3. In Diktator, tap "Enable session". The app then records in the background
   for at most 15 minutes; this is what makes dictation from the keyboard
   possible, because iOS does not allow an app extension to use the
   microphone.
4. Open Notes or Messages, switch to the Diktator keyboard and tap "Dictate".
   Speak a sentence and tap "Stop". The transcript appears in the field
   automatically; "Paste" is the manual fallback.
5. When the 15 minutes run out, the keyboard only shows the message "Open
   Diktator and enable a session". The keyboard never opens another app. The
   user opens Diktator with the app switcher, taps "Enable session" again,
   and returns with the back arrow in the status bar.

KEYBOARD AND FULL ACCESS
The keyboard asks for Full Access for two things only:
- reading the clipboard when the user taps "Paste" (a keyboard extension gets
  stale clipboard data without Full Access);
- fetching the finished transcript from the app over a local server bound to
  127.0.0.1:8765, guarded by a secret token derived on the device. A keyboard
  extension needs Full Access to use the network at all, and this local server
  is how the text reaches the field without the user copying anything.
Without Full Access the keyboard still types normally (QWERTY, numbers,
Serbian characters including c, c, z, s, dj), which satisfies the requirement
that a keyboard must be usable on its own. The extension never records audio -
iOS does not allow microphones in app extensions. Audio is captured only by
the main app, and only while the user has enabled a session or is dictating in
the app.

PRIVACY
Audio is transcribed on the device and then discarded from memory; recordings
are never written to storage. No third-party analytics, advertising or crash
SDKs. No data is sent to the developer, and there is no developer server.

The app offers two optional cloud features, both off by default, both using a
key the user creates with the provider:
- cloud transcription with Groq (sends the recording);
- text cleanup with Gemini, OpenAI, Claude, DeepSeek or any OpenAI-compatible
  endpoint (sends only the finished text).
Before the first use of each service the app names the service and the data,
and asks for explicit permission; the answer is stored per service and can be
withdrawn in Settings, after which nothing more is sent. Because the developer
receives no copy of anything, the App Privacy answer is "Data Not Collected".

This App Store build does not check GitHub for updates, does not ask for
notification permission and never opens another app from the keyboard. The
keyboard session lasts at most 15 minutes and is renewed only when the user
asks for it.

MEMORY
The recommended Serbian model (Large v3, ~1.0 GB) is meant for devices with
enough RAM. The app offers smaller models (Base, Small) and the description
states the download size before any download starts. Models are downloaded
from huggingface.co; an interrupted download is deleted and can be restarted.
```

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
- [ ] Review Notes nalepljene.
- [ ] TestFlight internal build prošao.
- [ ] Export compliance odgovoreno.

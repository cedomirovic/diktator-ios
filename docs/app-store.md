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
| Subtitle (30) | Diktat na srpskom, lokalno |
| Primary language | English (U.S.) |
| Bundle ID | com.cedomirovic.diktator.ios |
| SKU | `diktator-ios-001` |
| Primary category | Productivity |
| Secondary category | Utilities |
| Price | Free |
| Age rating | 4+ |
| Made for Kids | No |

Ako App Store Connect traži engleski subtitle, koristi:
`Serbian dictation, on device`.

## Promotional text (170)

```
Diktiraj na srpskom ili engleskom i tekst se sam ubaci u bilo koju aplikaciju.
Sve se obrađuje na tvom iPhone-u — bez naloga i bez slanja snimka.
```

## Description (EN, primary)

```
Diktator turns speech into text on your iPhone and iPad — in Serbian and
English — and inserts it into whatever app you are typing in.

Everything runs on your device with Whisper. No account, no ads, no analytics,
and your recordings are not stored.

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
telemetry. Network is used only to download models, check for a new version
and, if you explicitly enable them, the optional cloud services above.

The keyboard needs Full Access to read the clipboard when you tap Paste and to
open Diktator from the Dictate button. Without Full Access it still types
normally.
```

## Description (SR, ako se dodaje lokalizacija)

```
Diktator pretvara govor u tekst na iPhone-u i iPad-u — na srpskom i engleskom —
i ubacuje ga u aplikaciju u kojoj upravo kucaš.

Sve se obrađuje na tvom uređaju, preko Whisper modela. Nema naloga, reklama ni
analitike, a snimci se ne čuvaju.

KAKO RADI
1. Dodaj tastaturu Diktator u iOS Podešavanjima i uključi Full Access.
2. Jednom preuzmi model (Turbo ~547 MB, Large v3 ~1,0 GB).
3. U bilo kojoj aplikaciji tapni Diktiraj na tastaturi Diktator i govori.
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
Mreža se koristi samo za preuzimanje modela, proveru nove verzije i, ako ih sam
uključiš, opcione servise u oblaku.

Tastatura traži Full Access da bi pročitala clipboard kada tapneš Nalepi i da bi
otvorila Diktator dugmetom Diktiraj. Bez Full Access-a i dalje normalno kuca.
```

## Keywords (100, EN)

```
dictation,speech to text,voice typing,serbian,transcription,offline,whisper,keyboard,voice
```

## Keywords (SR)

```
diktiranje,glas u tekst,srpski,prepis,offline,tastatura,whisper,transkripcija
```

## URLs

| Polje | Vrednost |
|---|---|
| Support URL | https://cedomirovic.github.io/diktator-ios/podrska.html |
| Privacy Policy URL | https://cedomirovic.github.io/diktator-ios/privatnost.html |
| Marketing URL | https://github.com/cedomirovic/diktator-ios |

## App Privacy (App Store Connect)

- **Data Collection:** *Data Not Collected*.
- Obrazloženje za Review Notes: sve se obrađuje na uređaju; opcioni Groq i
  LLM servisi rade samo ako ih korisnik uključi i unese **svoj** ključ, pa
  programer ne dobija kopiju podataka.
- `PrivacyInfo.xcprivacy` je dodat u oba targeta: nema tracking-a, nema
  prikupljanja, prijavljeni su `UserDefaults` (`CA92.1`) i file timestamp
  (`C617.1`).

## Export compliance

- Koristi se samo standardni HTTPS/TLS iz iOS-a (`URLSession`) i `CryptoKit`
  za SHA-256 izvođenje lokalnog ključa.
- Odgovor: **„No“** na pitanje da li aplikacija koristi kriptografiju, uz
  napomenu da je u pitanju samo Apple-ov standardni TLS/SHA.
- Ako App Store Connect traži `ITSAppUsesNonExemptEncryption`, postavi na
  `NO` (dodato u `Info.plist`).

## Review Notes (lepi u App Store Connect)

```
Diktator is an on-device dictation app for Serbian and English. Everything
runs locally with whisper.cpp; no account is required.

HOW TO TEST QUICKLY (2–3 minutes)
1. Launch Diktator and open Settings → Model. Download "Base" (~142 MB) or
   "Turbo" (~547 MB). Base is enough to review the flow.
2. iOS Settings → General → Keyboard → Keyboards → Add New Keyboard →
   Diktator, then enable "Allow Full Access".
3. Open Notes or Messages, switch to the Diktator keyboard, tap "Dictate".
4. Speak any sentence and tap "Stop". The transcript appears in the field
   automatically. "Paste" is the manual fallback.
5. If the app was closed, tapping "Dictate" opens Diktator, which enables a
   15-minute background session and starts recording immediately.

KEYBOARD AND FULL ACCESS
The keyboard needs Full Access for two things only:
- reading the clipboard when the user taps "Paste" (UIPasteboard in a
  keyboard extension returns stale data without Full Access);
- opening its own containing app from the "Dictate" button (iOS 26 requires
  Full Access for extensionContext.open).
Without Full Access the keyboard still types normally (QWERTY, numbers,
Serbian characters), which satisfies the requirement that a keyboard must be
usable on its own. The extension never records audio — iOS does not allow
microphones in app extensions. Audio is captured only by the main app.

No third-party analytics or advertising SDKs. No data is sent to the
developer. Network access is used for model download (huggingface.co), an
optional update check (api.github.com) and the optional, user-configured
cloud transcription/refinement services. Those are off by default and require
the user's own API key.
```

## Screenshots

Obavezno za App Store Connect:

| Slot | Rezolucija | Kako |
|---|---|---|
| iPhone 6.9" | 1320 × 2868 | `app/uzmi-snimke.sh` (iPhone 17 Pro Max) |
| iPad 13" | 2064 × 2752 | `app/uzmi-snimke.sh` (iPad Pro 13") |

Poželjni kadrovi (5–6):

1. Glavni ekran sa velikim dugmetom **Diktiraj**.
2. Rezultat u drugoj aplikaciji (Poruke) sa tekstom.
3. Podešavanja → Brzina (Brzo / Najtačnije / Groq).
4. Istorija.
5. Statistika.
6. Pomoć ili Rečnik.

`app/uzmi-snimke.sh` pravi snimke iz simulatora u
`docs/slike/app-store/`. Snimak tastature u drugoj aplikaciji mora ručno, jer
simulator ne uključuje custom tastaturu skriptom.

## Checklist za prijavu

- [ ] Plaćeni Apple Developer Program (99 USD/god.) i ugovori prihvaćeni.
- [ ] App record napravljen sa bundle ID-em `com.cedomirovic.diktator.ios`.
- [ ] Distribution sertifikat i App Store profil (Xcode → Manage Certificates).
- [ ] `PrivacyInfo.xcprivacy` u oba targeta (urađeno).
- [ ] Privacy policy i support URL dostupni (GitHub Pages).
- [ ] Metadata popunjen iz ovog dokumenta.
- [ ] Screenshots za iPhone 6.9" i iPad 13".
- [ ] Review Notes nalepljene.
- [ ] TestFlight internal build prošao.
- [ ] Export compliance odgovoreno.

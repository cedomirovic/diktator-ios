# Diktator iOS · mobilna aplikacija za diktiranje

Ovaj projekat je nastao iz macOS aplikacije **Diktator**
(`/Users/cedomirovic/Downloads/Pitchi`). Cilj je iPhone/iPad aplikacija u
kojoj se diktira srpski ili engleski i tekst se ubacuje u bilo koju aplikaciju.

## Status

- **26.10.2026.** — srpski je prioritet: **Large v3 q5_0** je preporučeni
  model, a na srpskom sistemu je podrazumevani jezik `sr`. Tastatura pre
  otvaranja aplikacije proverava **Full Access** i ima fallback za otvaranje.
- **25.10.2026.** — napravljen novi folder, git repo i skelet dokumentacije.
  Odluke su potvrđene:
  - GitHub: <https://github.com/cedomirovic/diktator-ios> (javan).
  - Aplikacija: **Diktator iOS**, bundle ID `com.cedomirovic.diktator.ios`.
  - Tastatura: bundle ID `com.cedomirovic.diktator.ios.keyboard`.
  - Arhitektura: **puna tastatura + clipboard**, bez App Group-a.
  - Podrazumevani model: **Large v3 q5_0** (~1,0 GB), preporučen za srpski.
    **Large v3 Turbo q5_0** (~547 MB) ostaje opcija za brži rad i manje RAM-a.
  - Minimum iOS 17; testirano na iOS 27.0.1.
  - Instalacija: **AltStore/SideStore**; Xcode služi za build i potpis.
  - MVP: diktat + tastatura, istorija, rečnik; **bez** LLM doterivanja.
- macOS 26.7.1 i Xcode 27.1 (27A9275) su instalirani; `xcode-select` pokazuje
  na Xcode. `app/pripremi-whisper-ios.sh` je napravio whisper.cpp biblioteke za
  iOS arm64 (Metal + Accelerate).
- Xcode projekat (`app/DiktatorIOS.xcodeproj`), Swift kod, puna tastatura,
  modeli, istorija i rečnik su u repou. Debug i Release build prolaze.
- Potpisivanje besplatnim **Personal Team**-om radi: Xcode je napravio profile
  za oba targeta, a aplikacija je instalirana i pokrenuta na iPhone 15 Pro
  (iPhone16,1; iOS 27.0.1). Developer Mode je uključen; developer profil je
  trustovan na uređaju.
- `build/DiktatorIOS.ipa` je napravljen (nepotpisan, ~1.6 MB bez modela).
  AltStore/SideStore potpisivanje i instalacija još nisu testirani.
- Simulator (iPhone 17, iOS 26.5): aplikacija se pokreće, UI se prikazuje, a
  `diktator-ios://dictate` pokreće snimanje. iOS prikaže
  **„Open in Diktator?“** i traži potvrdu **Open**.
- Korisnik je potvrdio da aplikacija radi na fizičkom iPhone-u.
- Test srpskog prepisa: **Large v3 Turbo q5_0** ume da pogreši (npr. imena i
  završetke), a **Large v3 q5_0** daje znatno bolji tekst. Zato je Large v3
  sada podrazumevani model, a na srpskom sistemu je podrazumevani jezik `sr`.
- Tastatura na iOS 26+ traži **Full Access** i za otvaranje aplikacije preko
  `extensionContext.open`; dodat je fallback preko responder lanca i jasnija
  poruka kada Full Access nije uključen.

## Cilj

- Diktat na srpskom i engleskom, lokalno (whisper.cpp).
- Tekst u bilo koju aplikaciju preko custom tastature.
- Instalacija bez plaćenog Apple Developer naloga (besplatni Apple ID).
- Novi GitHub repo i uputstvo za instalaciju u
  `docs/instalacija-bez-naloga.md`.

## Ograničenja koja određuju arhitekturu

1. **iOS tastatura ne može da pristupi mikrofonu.** Apple zabranjuje mikrofon
   svim app extension-ima. Tastatura ne može sama da snima.
2. **App Groups nisu dostupne sa besplatnim Apple ID-jem.** Zato aplikacija i
   tastatura ne dele fajlove ni podešavanja preko App Group-a.
3. Rešenje: glavna aplikacija snima i prepisuje; rezultat ide u
   **UIPasteboard**. Tastatura ima dugme **Diktiraj** (otvara app preko URL
   scheme `diktator-ios://dictate`) i **Nalepi** (ubacuje tekst iz clipboarda
   preko `textDocumentProxy.insertText`).
4. Tastatura traži **Full Access** da bi čitala clipboard i, na iOS 26+,
   otvorila aplikaciju dugmetom **Diktiraj**. Bez Full Access-a korisnik može
   ručno da nalepi tekst u ciljnoj aplikaciji.
5. Besplatni Apple ID daje profil od **7 dana**; posle toga build treba
   obnoviti (AltStore/SideStore ili Xcode). Nema App Groups, push, iCloud.
6. Apple Speech / SpeechAnalyzer **ne podržava srpski** (lista locale-a od
   2026. ne uključuje `sr`). Zato je za srpski potreban whisper.cpp.

## Potvrđena arhitektura

- `DiktatorIOS` (SwiftUI): snimanje, whisper.cpp, modeli, istorija, rečnik,
  podešavanja, kopiranje u clipboard, URL scheme `diktator-ios://dictate`.
- `DiktatorKeyboard` (`UIInputViewController`): **puna tastatura** — QWERTY
  slova, srpska slova `čćžšđ`, brojevi, shift, brisanje, razmak, enter, globus;
  gornja traka sa **Diktiraj** i **Nalepi**.
- Bez App Group-a; jedini deljeni kanal je `UIPasteboard.general`.
- Whisper.cpp statički za iOS (arm64); modeli se preuzimaju u aplikaciji.
- Preporučeni model je Large v3 q5_0; Turbo q5_0, Small i Base su opcije za
  brži rad ili manje memorije.
- Istorija i rečnik žive u glavnoj aplikaciji; tastatura ih ne vidi.
- Srpski UI i komentari; imena funkcija i promenljivih na srpskom, bez
  dijakritika.

## Reference iz macOS projekta

- `app/src/Prepisivac.swift` — whisper.cpp C API, jezik, režim.
- `app/src/Snimac.swift` — AVAudioEngine snimanje.
- `app/src/Transliteracija.swift` — ćirilica → latinica.
- `app/src/PonudaModela.swift` — katalog modela i veličine.
- `app/src/Podesavanja.swift` — podešavanja, Keychain.
- `app/src/Preuzimanje.swift` — download modela.
- `app/src/PogledPodesavanja.swift`, `PogledIstorija.swift`,
  `PogledPomoc.swift` — UI obrasci.
- `app/pripremi-whisper.sh` — build whisper.cpp; napraviti iOS varijantu.

## Pravila

- Bez SPM/CocoaPods zavisnosti; Swift, SwiftUI/UIKit i statički whisper.cpp.
- Sve putanje kroz `URL` / `appendingPathComponent`; bez spajanja stringova
  sa `/`.
- Lokalni snimak i tekst; mreža samo za modele, ažuriranja i opciono LLM.
- Bez tajni u git-u; API ključevi u Keychain-u.
- Posle svakog završenog koraka `git add` + `git commit`, poruka na srpskom.
- Ne dirati macOS projekat `Pitchi` iz ovog repoa.

## Sledeći korak

1. Instalirati novi build, uključiti **Full Access** i proveriti da **Diktiraj**
   otvara aplikaciju (u traci treba da piše **Full Access ✓**).
2. Preuzeti **Large v3** i uporediti srpski prepis sa Turbo modelom.
3. Testirati AltStore/SideStore potpisivanje i instalaciju IPA-e, uključujući
   keyboard extension.
4. Proveriti osvežavanje profila posle 7 dana.
5. Ažurirati dokumentaciju rezultatima i pripremiti release tag.

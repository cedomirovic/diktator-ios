# Diktator iOS · mobilna aplikacija za diktiranje

Ovaj projekat je nastao iz macOS aplikacije **Diktator**
(`/Users/cedomirovic/Downloads/Pitchi`). Cilj je iPhone/iPad aplikacija u
kojoj se diktira srpski ili engleski i tekst se ubacuje u bilo koju aplikaciju.

## Status

- **25.10.2026.** — napravljen novi folder, git repo i skelet dokumentacije.
  Arhitektura, GitHub repo, model i potpisivanje još nisu potvrđeni.
- Xcode na ovom Macu **nije instaliran** (aktivan je samo Command Line Tools).
  Za build i potpisivanje potreban je Xcode 26.x iz App Store-a.
- macOS projekat `Pitchi` se **ne dira** iz ovog repoa; on je referenca.

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
   scheme) i **Nalepi** (ubacuje tekst iz clipboarda preko
   `textDocumentProxy.insertText`).
4. Tastatura traži **Full Access** da bi čitala clipboard. Bez Full Access-a
   korisnik može ručno da nalepi tekst u ciljnoj aplikaciji.
5. Besplatni Apple ID daje profil od **7 dana**; posle toga build treba
   obnoviti (Xcode ili AltStore/SideStore). Nema App Groups, push, iCloud.
6. Apple Speech / SpeechAnalyzer **ne podržava srpski** (lista locale-a od
   2026. ne uključuje `sr`). Zato je za srpski potreban whisper.cpp.

## Predložena arhitektura (čeka potvrdu)

- `DiktatorIOS` (SwiftUI): snimanje, whisper.cpp, modeli, istorija, rečnik,
  podešavanja, kopiranje u clipboard, URL scheme `diktator://dictate`.
- `DiktatorKeyboard` (`UIInputViewController`): slova/razmaci, dugme
  **Diktiraj** (otvara app), dugme **Nalepi** (clipboard → tekst), status.
- Bez App Group-a; jedini deljeni kanal je `UIPasteboard.general`.
- Whisper.cpp statički za iOS (arm64); modeli se preuzimaju u aplikaciji.
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

## Otvorena pitanja

- Ime repo-a, vidljivost i vlasnik.
- Ime aplikacije i bundle ID.
- Tastatura + clipboard ili samo aplikacija + clipboard.
- Podrazumevani model (Small q5_1 / Turbo / Base / Large).
- Xcode i iPhone/iOS verzija.
- Način instalacije (Xcode, AltStore/SideStore).
- MVP: istorija, rečnik, LLM doterivanje.

## Sledeći korak

1. Potvrditi gore navedene odluke.
2. Napraviti GitHub repo i prvi commit.
3. Napraviti Xcode projekat sa dva targeta (app + keyboard).
4. Pripremiti whisper.cpp za iOS i portovati snimanje/prepis.
5. Napraviti clipboard tok i tastaturu.
6. Napisati i proveriti uputstvo za instalaciju bez plaćenog naloga.

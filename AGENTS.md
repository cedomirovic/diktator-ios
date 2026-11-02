# Diktator iOS · mobilna aplikacija za diktiranje

Ovaj projekat je nastao iz macOS aplikacije **Diktator**
(`/Users/cedomirovic/Downloads/Pitchi`). Cilj je iPhone/iPad aplikacija u
kojoj se diktira srpski ili engleski i tekst se ubacuje u bilo koju aplikaciju.

## Status

- **02.11.2026.** — **rečnik se gradi iz diktata**: u **Istoriji** svaki
  zapis dobija dugme **Dodaj u rečnik** (ikona `text.badge.plus`), a isto
  dugme je i u meniju zapisa, u kontekstnom meniju (dugi dodir) i na kartici
  **Poslednji tekst** na ekranu **Diktat**. Otvara se lista
  `PogledDodajRecnik` koja predlaže reči sa velikim početnim slovom, unapred
  označava imena koja nisu na početku rečenice, skriva pojmove koji su već u
  rečniku i dopušta ručni unos više pojmova odvojenih zarezom. Novi
  `AppStanje.dodajURecnik` preskače duplikate bez obzira na velika i mala
  slova, vraća broj dodatih pojmova i odmah čuva `recnik.txt`. Provereno u
  simulatoru (svetlo/tamno) i upisom u fajl; verzija ostaje **0.2.0 (10)**.

- **02.11.2026.** — **tastatura redizajnirana kao sistemska iOS tastatura**:
  uklonjena je traka sa plavim **Diktiraj** i zelenim **Nalepi** dugmetom.
  Tastatura sada izgleda kao osnovna iOS tastatura — iste boje pozadine i
  tipki, zaobljene bele tipke sa senkom, sivi specijalni tasteri, sistemski
  fontovi i raspored. Srpska latinica je raspoređena kao kod Apple-a:
  `q w e r t z u i o p` / `a s d f g h j k l č ć` / `⇧ z x c v b n m š đ ⌫`,
  pa nema više zasebnog reda sa `čćžšđ`. **Diktiraj** je sada mikrofon na mestu
  sistemskog mikrofona u donjem redu (`123`, globus, razmak, mikrofon,
  return), a dok snima pokazuje crveni **Stop**. Tanka traka iznad tastature
  (kao sistemska traka predloga) prikazuje samo stanje — `Snimam…`,
  `Prepišujem…`, `Uključi Full Access` — i **Nalepi** samo kada prepis čeka;
  u mirovanju je prazna. Tastatura prati `keyboardAppearance` polja u koje se
  kuca, pa se tamni/svetli izgled poklapa sa host aplikacijom. Provereno u
  simulatoru (iPhone i iPad, svetlo/tamno, slova/brojevi/shift).
- **02.11.2026.** — **tačnost srpskog izjednačena sa desktopom**: uporedni
  test je pokazao tri razlike u odnosu na macOS Diktator, koji radi sa
  **Large v3 + pretragom snopom + punim audio kontekstom**. Mobilna
  aplikacija je do sada podrazumevano koristila **Turbo** (jer je „Brzina“
  bila `brzo`, a `modelZaPrepis` je tada tiho vraćao Turbo i kada je u
  Podešavanjima pisalo „Izabran: Large v3“), **greedy** dekodiranje i
  **skraćen audio kontekst**. Sada: podrazumevani režim je **Najtačnije**
  (Large v3 + beam 5 + pun kontekst), „Brzo“ zadržava Turbo + greedy +
  skraćen kontekst, a skraćeni kontekst je vezan isključivo za taj režim.
  Dodata je jednokratna migracija za nedosledno sačuvano stanje i red u
  Podešavanjima → **Brzina** koji tačno piše šta će se koristiti
  („Prepisaće: Large v3, pretraga snopom, pun audio kontekst.“).
- **01.11.2026.** — **novi vizuelni identitet sa desktop dizajna**: boje,
  stil i tipografija preuzeti su sa macOS Diktatora i prilagođeni telefonu.
  Dodat je `Dizajn.swift` sa tokenima (akcenat **#2F7CF6**, pozadina
  **#F2F3F5**, bele kartice sa ivicom **#E4E6EA**, tekst **#14161A**,
  radijus 18), dinamičkim bojama za tamni režim i komponentama
  (`NaslovEkrana`, `IkonaUKrugu`, `Oznaka`, `RedPodatka`, `StilDugmeta`).
  Svi ekrani su redizajnirani: **Diktat** (kartica mikrofona, sesija,
  statistika, koraci), **Istorija** (pretraga, kartice sa trajanjem
  `01:32`, meni), **Statistika** (4 kartice sa brojevima, stubičasti
  grafikon), **Podešavanja** (kartice u `Form`-i sa bold zaglavljima) i
  **Pomoć** (numerisani koraci, kartica podrške). Verzija ostaje
  **0.2.0 (10)**; snimci za App Store su regenerisani u novom dizajnu.
- **01.11.2026.** — **„Oslobodi model sada“ sada daje povratnu informaciju**:
  u Podešavanjima piše da li je model **u memoriji** ili **nije učitan**, a
  posle dodira se prikaže zelena potvrda „Model je oslobođen iz memorije.“
  (ili narandžasto obaveštenje ako model nije bio učitan). Stanje se prati
  preko `Prepisivac.naPromenuUcitanosti`, pa se osveži i kada model oslobodi
  tajmer ili odlazak u pozadinu.
- **29.10.2026.** — **dugme „Završi sesiju“ je crveno** i punom širinom kada je
  sesija aktivna, da se odmah vidi da je treba ugasiti (u repou je i dalje
  verzija **0.2.0 (10)**). Korisnik je potvrdio da sve radi na uređaju.
- **28.10.2026.** — **priprema za App Store** (verzija **0.2.0 (10)**):
  dodat je `PrivacyInfo.xcprivacy` u aplikaciju i tastaturu (bez tracking-a i
  prikupljanja; `UserDefaults` `CA92.1`, file timestamp `C617.1`),
  `ITSAppUsesNonExemptEncryption = NO`, stranice **privatnosti** i
  **podrške** na GitHub Pages-u, metadata i Review Notes u
  `docs/app-store.md`, snimci ekrana za iPhone 6.9" i iPad 13" u
  `docs/slike/app-store/`, skripte `app/objavi-testflight.sh` i
  `app/uzmi-snimke.sh`, `app/ExportOptions.plist` i
  `app/pripremi-whisper-simulator.sh` (whisper za simulator, da bi snimci
  mogli da se prave bez uređaja). Aplikacija se sada može pokrenuti i u
  simulatoru; tab se bira argumentom `-DiktatorTab`.
- **28.10.2026.** — **sesija se sama obnavlja**: kada sesija istekne, ili
  kada je Diktator ugašen (status tastature nije svež), tap na **Diktiraj**
  otvara Diktator preko `diktator-ios://dictate`, koji uključi sesiju i odmah
  počne snimanje. Svaki diktat produžava sesiju za novih 15 minuta, a
  tastatura posle 6 s bez odgovora na `start` sama otvara aplikaciju.
- **28.10.2026.** — **automatsko lepljenje**: posle diktata iz tastature
  tekst se sam ubacuje u polje, bez klika na **Nalepi**. Aplikacija uz tekst
  upisuje token i vreme, a tastatura preko lokalnog servera prepoznaje novi
  prepis i ubacuje ga preko `textDocumentProxy`; ako to ne uspe, ostaje
  ručni **Nalepi**. Isti tekst se ne lepi dvaput, stari se preskače, a
  čekanje odustaje posle 10 minuta.
- **28.10.2026.** — **bezbednosno ojačanje** (verzija **0.1.8 (9)**):
  lokalni server za **Nalepi** sada traži tajni ključ
  (`X-Diktator-Token`, izveden kao
  `SHA-256("com.cedomirovic.diktator.server." + identifierForVendor)`, pa ga
  aplikacija i tastatura računaju same bez pasteboard-a), prihvata samo
  `GET /tekst` i više nikada ne otvara port na svim interfejsima. Dodati su
  `SECURITY.md`, `Cache-Control: no-store` i provera dužine zaglavlja;
  potvrđeno je da u repou nema tajni, da ATS dozvoljava samo lokalnu mrežu i
  da API ključevi ostaju u Keychain-u (`WhenUnlockedThisDeviceOnly`).
- **28.10.2026.** — **brzina prepisa**: whisper sada računa audio kontekst
  samo za stvarnu dužinu snimka (umesto punih 30 s), koristi 3 niti na CPU i
  podrazumevano bira **Turbo** model. Dodat je i opcioni **Groq** prepis u
  oblaku (~1 s) sa lokalnim fallback-om; u Podešavanjima → **Brzina** biraš
  Brzo / Najtačnije / Groq. Verzija **0.1.7 (8)**.
- **28.10.2026.** — dodato je **opciono doterivanje teksta** preko
  **Gemini**, OpenAI, Claude, DeepSeek, Ollama i drugih OpenAI-kompatibilnih
  servisa. U Podešavanjima je sekcija **Doterivanje** sa API ključem u
  Keychain-u, izborom modela, adresom za custom servis i dugmetom **Test
  veze**. Kada je uključeno, posle lokalnog prepisa samo gotov tekst ide
  servisu; ako doterivanje ne uspe, zadržava se sirov prepis.
- **26.10.2026.** — verzija **0.1.6 (7)**: popravljena je pozadinska sesija
  tako što status nosi **`sesijaDo`** (do kada sesija važi). Tastatura više ne
  gasi sesiju posle 3 sekunde bez novog statusa, pa posle povratka u host
  aplikaciju vidi **Stop** dok je snimanje u toku. Dodati su i timeout-i za
  start/stop ako aplikacija ne odgovori.
- **26.10.2026.** — dodata su **obaveštenja o novim verzijama**: provera
  GitHub release-a, kartica na glavnom ekranu, lokalna notifikacija, prekidač
  u Podešavanjima, „Proveri sada“ i „Testiraj obaveštenje“.
- **26.10.2026.** — dodata je **Statistika** u glavnu aplikaciju (verzija
  **0.1.5 (6)**): današnje reči, niz dana, ušteđeno vreme, prosečna brzina,
  grafikon poslednjih 7 dana, jezici i reset statistike. Statistika se čuva
  odvojeno od istorije (`statistika.json`) i ne sadrži tekst.
- **26.10.2026.** — pozadinska sesija je ojačana: status i komande idu preko
  imenovanih pasteboard-a **i Darwin notifikacija**, tastatura ima timeout i
  više ne može trajno da ostane na „Uključujem…“, a prvi `Diktiraj` odmah
  pokreće snimanje u aplikaciji.
- **26.10.2026.** — iPhone `nemanja` je uparen sa Mac-om preko `devicectl`
  (Xcode je prijavljivao da uređaj nije uparen), a potpisana verzija
  **0.1.1 (2)** je instalirana direktno na uređaj. Pokretanje preko
  `devicectl` je čekalo otključavanje telefona.
- **26.10.2026.** — dodat je stvarni screenshot sa iPhone 15 Pro
  (`docs/slike/diktator-iphone.png`), README je ažuriran, a
  `docs/distribucija.md` opisuje sideload, TestFlight, App Store, naloge,
  Review Notes i checklist. Korisnik je potvrdio da sve radi na telefonu.
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
  - MVP: diktat + tastatura, istorija, rečnik; **LLM doterivanje je
    opciono** (dodato 28.10.2026).
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
- `DiktatorKeyboard` (`UIInputViewController`): **puna tastatura u stilu
  sistemske iOS tastature** — srpska latinica (`čćžšđ` u redovima, kao na
  Apple tastaturi), brojevi, simboli, shift, brisanje, razmak, return i
  globus. Mikrofon u donjem redu je **Diktiraj**, a tanka traka iznad
  tastature prikazuje stanje i **Nalepi** kada tekst čeka.
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
- Lokalni server za tastaturu sluša samo loopback i traži ključ
  (`X-Diktator-Token`); nikada ga ne vezivati na sve interfejse. Detalji su
  u `SECURITY.md`.
- Posle svakog završenog koraka `git add` + `git commit`, poruka na srpskom.
- Ne dirati macOS projekat `Pitchi` iz ovog repoa.

## Sledeći korak

1. Uplatiti **Apple Developer Program** (99 USD/god.), prihvatiti ugovore i u
   Xcode-u napraviti **Apple Distribution** sertifikat za tim.
2. Napraviti app record u App Store Connect-u (`com.cedomirovic.diktator.ios`)
   i popuniti metadata iz `docs/app-store.md`.
3. Pokrenuti `app/objavi-testflight.sh` i sačekati obradu builda.
4. Testirati TestFlight internal, pa external; prikupiti prve povratne
   informacije o srpskom prepisu i preuzimanju modela.
5. Testirati AltStore/SideStore potpisivanje i instalaciju IPA-e, uključujući
   keyboard extension.
6. Proveriti osvežavanje profila posle 7 dana.
7. Pripremiti release tag i objaviti App Store/TestFlight rezultate.

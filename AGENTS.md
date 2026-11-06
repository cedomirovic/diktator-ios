# Diktator iOS · mobilna aplikacija za diktiranje

Ovaj projekat je nastao iz macOS aplikacije **Diktator**
(`/Users/cedomirovic/Downloads/Pitchi`). Cilj je iPhone/iPad aplikacija u
kojoj se diktira srpski ili engleski i tekst se ubacuje u bilo koju aplikaciju.

## Status

- **06.11.2026.** — **sitnice u kodu (tačka 14)**: `IsASCIICapable` je sada
  `true` (`project.yml` i `DiktatorKeyboard/Info.plist`), pa se tastatura
  pojavljuje i u ASCII poljima kao što su mejl i URL; `čćžšđ` su dodatni
  znaci, ne drugi alfabet. Globus se i dalje prikazuje samo uz
  `needsInputModeSwitchKey`, a `Dnevnik` se skraćuje na 200 KB (zadržava
  poslednjih 100 KB). Opšti clipboard se više ne puni posle diktata
  pokrenutog iz tastature — tekst tada ide samo imenovanim pasteboard-om i
  lokalnim serverom, pa ga druge aplikacije ne vide; kada diktiraš iz same
  aplikacije, upis ostaje da bi ručno **Nalepi** radilo u drugoj aplikaciji.
  `docs/privatnost.html` (SR i EN) i `docs/app-store.md` opisuju novo
  ponašanje. Verzija ostaje **0.2.0 (10)**.

- **06.11.2026.** — **App Privacy, Age rating i provera potpisa (tačke 12 i
  13)**: `docs/app-store.md` sada ima tačne korake za App Privacy upitnik
  (**Data Not Collected**, bez označenih tipova podataka), tabelu „šta se ne
  prijavljuje i zašto“ i odgovore na svako pitanje Age rating upitnika
  (rezultat **4+**, uz napomenu da se upitnik ponovo prolazi ako se doda
  deljenje sadržaja). Dodata je sekcija **Tim i nalog**: trenutno stanje
  (besplatni tim `LHQ4Q44425`, samo Apple Development sertifikat, razvojni
  profili ističu 09.11.2026), koraci za prelazak na plaćeni tim i dve opcije
  za vlasništvo bundle ID-a/GitHub Pages-a/mejla. Nova skripta
  `app/proveri-potpis.sh` čita `project.yml`, `ExportOptions.plist`,
  pbxproj, Keychain i profile i pokaže da li se timovi slažu, ima li Apple
  Distribution sertifikata i App Store profila za oba bundle ID-a.
  `app/objavi-testflight.sh` sada prima `DIKTATOR_TIM`, arhivira sa
  `CODE_SIGN_IDENTITY="Apple Distribution"` i odbija arhivu potpisanu
  razvojnim sertifikatom; ExportOptions se pravi sa timom iz builda.
  Verzija ostaje **0.2.0 (10)**.

- **06.11.2026.** — **snimak tastature u „drugoj“ aplikaciji (tačka 10)**:
  dodat je `app/uzmi-snimak-tastature.sh`, koji pravi
  `docs/slike/app-store/tastatura.png` (1320 × 2868) tako što napravi malu
  probnu aplikaciju (`app/alati/pregled-tastature/PregledApp.swift`) i u nju
  ugradi pravi `KeyboardViewController`. Simulator ne može skriptom da
  uključi custom tastaturu, pa bi ručni kadar bio jedina alternativa; ovako
  snimak prikazuje stvarni kod tastature sa tekstom iznad nje. Probna
  aplikacija se ne gradi u okviru Diktatora i ne ide u App Store. Usput je
  tastatura dovršeno lokalizovana: statusi **Prepisujem…**, **Spremno za
  lepljenje**, **Sesija ✓**, **Sesija ✗** i **Uključi Full Access** idu kroz
  `Prevod.t`, a u `app/alati/prevedi.py` su dodati u rečnik tastature.
  `PogledDiktat` prima `-DiktatorBezUvoda 1` (radi i u AppStore buildu, gde
  nema `DEBUG`), pa `app/uzmi-snimke.sh` sada pravi snimke bez uvodnog toka;
  regenerisani su iPhone i iPad snimci u engleskom App Store buildu.
  `docs/app-store.md` ima slot za tastaturu, opis skripte i ažuriranu
  checklistu. Verzija ostaje **0.2.0 (10)**.

- **05.11.2026.** — **prolazak kroz analizu App Store recenzije (tačke 1–4,
  9 i 11)**: kod je očišćen pre prijave. Linkovi koji pokreću snimanje
  (`diktator-ios://dictate`, `sesija`, `sesija-prikaz`, `stop`) postoje samo u
  ličnom buildu, jer svaka aplikacija može da ih otvori. Dozvole za servise se
  sada pamte po servisu (`Podesavanja.odobreniServisi`): pre prvog slanja
  aplikacija imenuje servis („Tekst ide u %@?“), a u Podešavanjima postoji
  **Povuci** za doterivanje i za Groq; bez dozvole se slanje preskače uz
  poruku. Automatsko lepljenje više ne čita opšti clipboard — koristi imenovani
  pasteboard i lokalni server, pa politika privatnosti tačno opisuje šta se
  čita i kada; tekstovi „sve ostaje na uređaju“ važe samo kada nijedan servis
  u oblaku nije uključen. Dodat je **uvodni tok** pri prvom pokretanju
  (`PogledUvod.swift`: model → tastatura → Full Access → sesija), upozorenje
  za uređaje sa malo RAM-a i provera slobodnog prostora pre preuzimanja
  modela. Metadata je usklađen sa App Store buildom: engleski subtitle i
  promotivni tekst, ublažen opis, izbačen `whisper` iz ključnih reči, nove
  Review Notes (Full Access za dve stvari, bez otvaranja aplikacije iz
  tastature) i stranica podrške koja opisuje ručno uključivanje sesije.
  Verzija ostaje **0.2.0 (10)**.

- **05.11.2026.** — **traka „Vrati se u svoju aplikaciju“ posle diktata iz
  tastature**: kada **Diktiraj** u tastaturi otvori Diktator, na vrhu ekrana
  **Diktat** stoji plava traka koja kaže šta se dešava (**Snimanje ide dalje —
  Stop je na tastaturi.**, **Sačekaj trenutak dok se prepis završi.**,
  **Tekst je spreman i nalepiće se sam.**) i pokazuje **gest povratka**:
  tačka klizi udesno po crti, uz tekst **Prevuci prstom udesno po donjoj ivici
  ekrana** i rezervu **ili tapni ‹ u gornjem levom uglu ekrana**. Prva verzija
  je imala veliku strelicu u zaobljenom kvadratu, ali je izgledala kao dugme
  koje ništa ne radi (iOS ne daje način da aplikacija sama prebaci u drugu
  aplikaciju), pa je zamenjena crtežom gesta. Traku uključuje
  `prikaziPovratak` u `AppStanje` (isključuje se kada aplikacija ode u pozadinu
  ili se sesija završi), a stare kratke poruke na dnu ekrana su uklonjene jer
  ih traka zamenjuje. Provereno u simulatoru na engleskom i srpskom, svetlo i
  tamno, preko `-DiktatorPovratak 1` (samo DEBUG, kao `-DiktatorTab`); verzija
  ostaje **0.2.0 (10)**.

- **04.11.2026.** — **engleski je primarni jezik, srpski drugi**: dodat je
  `Prevod.swift` u aplikaciju i tastaturu (`Prevod.t`), a svi tekstovi koji se
  sklapaju u običan `String` prolaze kroz njega. Dodati su
  `en.lproj`/`sr.lproj` fajlovi `Localizable.strings` i `InfoPlist.strings`
  (prevodi se generišu skriptom `app/alati/prevedi.py`), a
  `DEVELOPMENT_LANGUAGE` je sada **en**. Srpski prevod je identitet, pa
  neprevedena stavka ostaje srpska. Localizovane su i sistemske poruke za
  mikrofon i lokalnu mrežu, zaglavlja sekcija u Podešavanjima i naslovi
  tastature (**Diktiraj**, **Nalepi**, **razmak**). Provereno u simulatoru na
  engleskom (svi tabovi i oba builda) i na srpskom; App Store build i dalje
  nudi samo sesiju od 15 minuta, bez sekcije **Ažuriranja**. Verzija ostaje
  **0.2.0 (10)**.

- **03.11.2026.** — **dva builda: lični i App Store**: dodat je `AppStore`
  build (konfiguracija `AppStore` sa uslovom `APPSTORE` i šema
  `DiktatorIOS-AppStore`), pa se isti kod gradi na dva načina. U App Store
  buildu tastatura **nikada ne otvara aplikaciju** (App Store Review 4.4.1) —
  umesto toga piše „Otvori Diktator i uključi sesiju.“; uklonjeni su i
  rezervni put preko responder lanca i programsko zatvaranje `exit(0)` (Apple
  ga ne odobrava). Sesija traje **najviše 15 minuta**, opcija **Bez isteka**
  se ne nudi, a postojeće „bez“ se svodi na 15 minuta. GitHub provera novih
  verzija i sekcija **Ažuriranja** su isključene, a iz Pomoći je uklonjen
  tekst o profilu od 7 dana. Prelazak na Groq sada traži potvrdu da snimak
  napušta uređaj (5.1.2). Lični build zadržava sve dosadašnje ponašanje.
  `app/objavi-testflight.sh` arhivira šemu `DiktatorIOS-AppStore`, a
  `info.plist` opis mikrofona više ne pominje „do 15 minuta“. Verzija ostaje
  **0.2.0 (10)**.

- **03.11.2026.** — **„Testiraj obaveštenje“ reaguje odmah**: poruka
  **Šaljem testno obaveštenje…** pojavi se čim se dodirne dugme, a samo
  obaveštenje stiže bez čekanja na proveru dozvole. `Azuriranja` sada pamti
  poslednju dozvolu (`dozvolaKeš`) i osvežava je tiho kada aplikacija dođe u
  prvi plan ili kada se uključi prekidač **Proveri nove verzije**, pa test
  preskače `notificationSettings()` i sistemski dijalog. Uklonjene su
  dvostruke provere i dve `await` runde u `testirajNotifikaciju`, uveden je
  `RezultatTestaObavestenja` (poslato / odbijeno / greška) da poruka tačno
  kaže šta se desilo, a testno obaveštenje koristi kratak vremenski okidač
  (0,1 s) jer je pouzdaniji od `trigger: nil`. Verzija ostaje **0.2.0 (10)**.

- **03.11.2026.** — **sesija bez isteka — Diktator se više ne otvara pri
  svakom diktatu**: podrazumevano trajanje pozadinske sesije je sada **Bez
  isteka**, pa tastatura diktira u bilo kojoj aplikaciji, a Diktator se
  otvara samo prvi put dok sesija još nije uključena. U Podešavanjima →
  **Diktat** dodat je izbor **Trajanje sesije** (**Bez isteka** / **1 sat** /
  **15 minuta**) koji odmah važi i za sesiju koja je već uključena.
  `AppStanje` kod sesije bez isteka ne postavlja `sesijaKraj`, pa je timer ne
  gasi, a IPC nosi `sesijaNeogranicena = 1`; tastatura zato ne odbija sesiju
  po vremenu i u mirovanju prikazuje **Sesija ✓** ili **Sesija ✗**. Pošto bi
  izlazak iz aplikacije ugasio sesiju, kod sesije bez isteka Diktator posle
  prvog diktata ostaje otvoren i korisnik se vraća strelicom ‹, a dalji
  diktati idu direktno iz tastature. Verzija ostaje **0.2.0 (10)**.

- **03.11.2026.** — **tipke se osećaju i vide pod prstom**: svaka tipka
  tastature (slova, specijalni tasteri, **Diktiraj**, **Nalepi**) sada pusti
  blagi haptički odziv na dodir i uveća se na 112 % dok je pritisnuta, pa se
  tačno vidi šta je kliknuto. Uklonjen je dvostruki haptički odziv pri
  pokretanju diktata, jer ga sada daje sama tipka. Status obrade sada piše
  **Prepisujem…** (ranije „Prepišujem…“), isto kao u glavnoj aplikaciji.

- **02.11.2026.** — **traka sa Diktiraj/Nalepi vraćena iznad tastature**:
  redizajn je bio zadržao samo donji deo, pa su diktat funkcije izgubljene.
  Sada su plavo **Diktiraj** (crveni **Stop** dok snima, sivo kada nema Full
  Access-a ili traje obrada), zeleno **Nalepi** i status desno ponovo u traci
  iznad tipki, a mikrofon je uklonjen iz donjeg reda — on je opet kao na iOS
  tastaturi (`123`, globus, razmak, return). Tekstovi pomoći, README i
  `docs/` sada opisuju dugme **Diktiraj**, a ne mikrofon u donjem redu.
  Provereno u simulatoru (svetlo/tamno, slova/brojevi/shift); verzija ostaje
  **0.2.0 (10)**.

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

- **02.11.2026.** — **tastatura u stilu sistemske iOS tastature, uz
  zadržanu traku sa dugmadima**: donji deo (same tipke) je redizajniran kao
  osnovna iOS tastatura — iste boje pozadine i tipki, zaobljene bele tipke sa
  senkom, sivi specijalni tasteri, sistemski fontovi i raspored. Srpska
  latinica je raspoređena kao kod Apple-a:
  `q w e r t z u i o p` / `a s d f g h j k l č ć` / `⇧ z x c v b n m š đ ⌫`,
  pa nema više zasebnog reda sa `čćžšđ`. Donji red je kao na iOS-u: `123`,
  globus, razmak, return. **Traka iznad tastature je zadržana**: plavo
  **Diktiraj** (crveni **Stop** dok snima, sivo kada nema Full Access-a ili
  traje obrada), zeleno **Nalepi** i status desno (`Snimam…`, `Prepisujem…`,
  `Spremno za lepljenje`, `Uključi Full Access`). Tastatura prati
  `keyboardAppearance` polja u koje se kuca, pa se tamni/svetli izgled
  poklapa sa host aplikacijom. Provereno u simulatoru (svetlo/tamno,
  slova/brojevi/shift).
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
  globus. U traci iznad tastature su **Diktiraj** (plavo), **Nalepi**
  (zeleno) i status prepisa.
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

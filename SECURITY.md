# Bezbednost

Diktator je napravljen tako da **zvuk i tekst podrazumevano ostaju na
uređaju**. Mreža se koristi samo za preuzimanje modela, proveru novih verzija
i za opcione servise koje korisnik sam uključi.

## Šta napušta uređaj

| Radnja | Šta ide na mrežu | Kada |
| --- | --- | --- |
| Preuzimanje modela | samo HTTP zahtev za fajl modela | kada korisnik tapne Preuzmi |
| Provera verzija | javni GitHub release API (`api.github.com`) | povremeno ili na „Proveri sada“ |
| Groq prepis | **snimak** (WAV) | samo ako je u Podešavanjima izabrano **Groq** |
| Doterivanje teksta | **gotov tekst** | samo ako je Doterivanje uključeno |
| Ollama / lokalni LLM | tekst, na adresu koju korisnik unese | samo ako je izabran lokalni servis |

Ako je izabran lokalni whisper (podrazumevano), zvuk **nikada** ne izlazi iz
aplikacije. Ako je Doterivanje isključeno (podrazumevano), tekst ne izlazi.
API ključ i zvuk se nikada ne šalju zajedno.

## Tajne

- API ključevi (Groq, LLM provajderi) čuvaju se u **Keychain**-u sa
  `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` i **ne** idu u `UserDefaults`,
  git, logove ni backup.
- Ključevi se ne loguju. Dnevnik (`diktator-dnevnik.txt`) beleži samo dužine,
  statuse i trajanja, nikada sadržaj prepisa ni ključeve.
- U repou nema tajni; `.gitignore` isključuje modele (`*.bin`, `*.gguf`),
  build i korisničke snimke.

## Lokalni server za „Nalepi“

Aplikacija pokreće mali HTTP server na `127.0.0.1:8765` da bi tastatura dobila
poslednji prepis (u keyboard extension-u `UIPasteboard` ume da vrati zastarelu
vrednost). Zaštita:

- sluša **isključivo loopback**; ako primarni `NWListener` ne uspe, rezervni
  put je vezan na `.loopback` interfejs — nikada na sve interfejse;
- traži zaglavlje **`X-Diktator-Token`**; ključ je 32 slučajna bajta
  (`SecRandomCopyBytes`), pravi se pri svakom pokretanju aplikacije i deli se
  sa tastaturom preko imenovanog pasteboard-a;
- prihvata samo `GET /tekst`; sve ostalo vraća `401`/`404`/`405`;
- odgovor nosi `Cache-Control: no-store`, a veza se zatvara posle 8 s;
- poređenje ključa je bez ranog prekida.

Ključ se **ne** upisuje u dnevnik.

## Fajlovi

- Istorija, statistika, rečnik i dnevnik su u kontejneru aplikacije, van
  Files aplikacije (nema `UIFileSharingEnabled`).
- `istorija.json`, `statistika.json`, `recnik.txt` i modeli dobijaju
  dozvole `0600`.
- iOS data protection je podrazumevano uključen.

## Mreža

- ATS je ograničen na `NSAllowsLocalNetworking`; nema
  `NSAllowsArbitraryLoads`.
- Doterivanje prihvata **HTTPS** svuda, a **HTTP samo za loopback i privatne
  IPv4 adrese** (Ollama u kućnoj mreži). Adrese sa korisničkim imenom ili
  lozinkom u URL-u se odbijaju.
- Provera verzija i Groq idu isključivo preko HTTPS-a.

## Dozvole

- **Mikrofon** — samo glavna aplikacija; tastatura ga ne može dobiti.
- **Full Access** za tastaturu — potreban za čitanje clipboarda i otvaranje
  aplikacije na iOS 26+. Bez njega tastatura ne čita clipboard.
- **Lokalna mreža** — traži se samo ako korisnik izabere Ollama/lokalni servis.

## Poznata ograničenja

- Imenovani pasteboard-i su sistemski vidljivi; aplikacija koja zna njihova
  imena i aktivno ih čita mogla bi da vidi status i ključ lokalnog servera.
  Zato se ključ menja pri svakom pokretanju i server sluša samo loopback.
- URL šema `diktator-ios://dictate` može da pokrene snimanje iz druge
  aplikacije. Snimak ostaje lokalno i ne izlazi nigde; rizik je ograničen na
  neželjeno pokretanje dikta.
- Sideload profil traje 7 dana; posle isteka aplikacija neće da se pokrene
  dok se profil ne obnovi.
- Ako je uključen Groq ili oblak za doterivanje, ti servisi obrađuju sadržaj
  po svojim uslovima; lokalni režim je privatna opcija.

## Prijava problema

Nađeš li propust, otvori **privatni** security advisory na GitHub-u
(<https://github.com/cedomirovic/diktator-ios/security/advisories/new>) ili
piši vlasniku repoa. Nemoj otvarati javni issue sa detaljima eksploatacije.

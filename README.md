# Diktator iOS

Mobilna verzija aplikacije **Diktator** za iPhone/iPad: izdiktiraš na srpskom
ili engleskom, a tekst se lokalno prepiše i ubaci u bilo koju aplikaciju.

![Diktator iOS na iPhone 15 Pro](docs/slike/diktator-iphone.png)

*Stvarni screenshot sa iPhone 15 Pro, iOS 27.0.1 (verzija 0.1.1).*

Projekat je nastao iz macOS aplikacije
[Diktator](https://github.com/cedomirovic/pitchi). Cilj je isti princip:
**snimak i tekst ostaju na uređaju**, bez slanja zvuka na server.

- GitHub: <https://github.com/cedomirovic/diktator-ios>
- Verzija: **0.1.5 (6)**
- Aplikacija: **Diktator iOS** (`com.cedomirovic.diktator.ios`)
- Tastatura: `com.cedomirovic.diktator.ios.keyboard`
- Preporučeni model: **Large v3 q5_0** (~1,0 GB) — tačniji za srpski.
  **Large v3 Turbo q5_0** (~547 MB) je brža opcija sa manje RAM-a.
- Minimum iOS 17; testirano na iPhone 15 Pro (iPhone16,1), iOS 27.0.1.

## Status

Verzija **0.1.5 (6)** je potpisana i instalirana na **iPhone 15 Pro**
(iOS 27.0.1). Debug i Release build prolaze na macOS 26.7.1 i Xcode 27.1;
whisper.cpp za iOS (arm64, Metal + Accelerate) je izgrađen. Skripta pravi
nepotpisan `build/DiktatorIOS.ipa` (~1.6 MB bez modela).

Na uređaju je potvrđeno: snimanje, lokalni whisper.cpp prepis, kopiranje u
clipboard, istorija, rečnik i puna tastatura. Tastatura na iOS 26+ traži
**Allow Full Access** za čitanje clipboarda i otvaranje aplikacije dugmetom
**Diktiraj**; u gornjoj traci treba da piše **Full Access ✓**.

Nova pozadinska sesija omogućava da tastatura snima dok je otvorena bilo koja
aplikacija. Prvi `Diktiraj` otvara Diktator da uključi sesiju i odmah počinje
snimanje; posle toga tastatura ostaje u host aplikaciji i šalje `start`/`stop`.
Status i komande idu preko imenovanih pasteboard-a i Darwin notifikacija, a
gotov tekst preko clipboarda.

Na srpskom sistemu aplikacija podrazumevano bira jezik **Srpski**, a ne
automatsku detekciju. Za srpski je preporučen **Large v3**; Turbo je brži, ali
na srpskom ume više da pogreši.

## Statistika

Glavni ekran ima karticu **Statistika**: današnje reči, niz dana i ušteđeno
vreme. Tap na karticu otvara detalje: ukupno reči i diktata, prosečnu brzinu
(reči/min), grafikon poslednjih 7 dana, vreme govora, najduži niz, jezike i
prosečan diktat. Statistika se računa lokalno iz broja reči i trajanja; ne
čuva tekst i može se obrisati nezavisno od istorije.

Ako Xcode ili `devicectl` prijave da uređaj nije uparen, prvo ga upari:

```bash
xcrun devicectl manage pair --device <UDID>
```

Posle toga rade i `devicectl device install app` i
`devicectl device process launch`. Telefon mora biti **otključan** da bi
`devicectl` pokrenuo aplikaciju.

## Kako radi

1. U bilo kojoj aplikaciji otvori tekstualno polje i prebaci tastaturu na
   **Diktator**.
2. Tapni **Diktiraj**. Prvi put se otvara Diktator, uključuje pozadinsku
   sesiju i odmah počinje snimanje. Ako iOS prikaže **„Open in Diktator?“**,
   tapni **Open**.
3. Vrati se u host aplikaciju i govori. Tastatura preuzima status i prikazuje
   **Snimam…**.
4. Tapni **Stop** — aplikacija prepisuje lokalno, a tastatura automatski
   ubacuje tekst. Nema potrebe za **„Back to …“**.
5. Sledeći put tapni **Diktiraj** direktno u tastaturi; Diktator se ne otvara
   dok je sesija aktivna (do 15 minuta).

## Šta je odlučeno

- iOS tastatura **ne može da pristupi mikrofonu** — Apple to zabranjuje svim
  app extension-ima. Zato glavna aplikacija snima i prepisuje.
- **App Groups nisu dostupne sa besplatnim Apple ID-jem**, pa ih ne koristimo.
  Status i komande idu preko imenovanih pasteboard-a i **Darwin notifikacija**.
- Tekst se predaje tastaturi preko **clipboarda**: aplikacija kopira prepis,
  tastatura ga ubacuje automatski ili dugmetom **Nalepi**.
- Tastatura je **puna QWERTY tastatura** sa srpskim slovima `čćžšđ`, brojevima
  i dugmadima **Diktiraj** / **Nalepi**.
- Za srpski je potreban **whisper.cpp**; Apple Speech ne podržava srpski.
- Instalacija je moguća sa besplatnim Apple ID-jem, ali profil traje **7 dana**
  i mora da se obnovi (AltStore/SideStore ili Xcode).

## Distribucija

- **Sideload (trenutno):** besplatni Apple ID + Xcode/AltStore/SideStore;
  profil traje 7 dana.
- **TestFlight / App Store:** potreban je plaćeni **Apple Developer Program**
  (99 USD/god.). App Store nema 7-dnevni istek; TestFlight build traje 90 dana.
- **Tuđi nalog:** tehnički moguć preko App Store Connect tima, ali app pripada
  tom timu. Za ozbiljan projekat je bolji sopstveni Individual ili Organization
  nalog.

Detalji, koraci za App Store, Review Notes i checklist su u
[docs/distribucija.md](docs/distribucija.md).

## Struktura

```text
app/
  DiktatorIOS/       SwiftUI aplikacija: snimanje, whisper, modeli, istorija
  DiktatorKeyboard/  puna custom tastatura: Diktiraj + Nalepi
  DiktatorIOS.xcodeproj
  project.yml        XcodeGen specifikacija
  pripremi-whisper-ios.sh
scripts/             pravljenje IPA za AltStore/SideStore
docs/                arhitektura, instalacija, distribucija i slike
```

## Dokumentacija

- [Instalacija bez plaćenog naloga](docs/instalacija-bez-naloga.md)
- [Distribucija: sideload, TestFlight i App Store](docs/distribucija.md)
- [PLAN.md](PLAN.md)
- [AGENTS.md](AGENTS.md)

## Licenca

MIT — vidi [LICENSE](LICENSE).

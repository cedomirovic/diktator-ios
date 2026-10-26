# Diktator iOS

Mobilna verzija aplikacije **Diktator** za iPhone/iPad: izdiktiraš na srpskom
ili engleskom, a tekst se lokalno prepiše i ubaci u bilo koju aplikaciju.

Projekat je nastao iz macOS aplikacije
[Diktator](https://github.com/cedomirovic/pitchi). Cilj je isti princip:
**snimak i tekst ostaju na uređaju**, bez slanja zvuka na server.

- GitHub: <https://github.com/cedomirovic/diktator-ios>
- Aplikacija: **Diktator iOS** (`com.cedomirovic.diktator.ios`)
- Tastatura: `com.cedomirovic.diktator.ios.keyboard`
- Preporučeni model: **Large v3 q5_0** (~1,0 GB) — tačniji za srpski.
  **Large v3 Turbo q5_0** (~547 MB) je brža opcija sa manje RAM-a.
- Minimum iOS 17; testirano na iOS 27.0.1

## Status

Razvoj je na macOS 26.7.1 i Xcode 27.1, a whisper.cpp za iOS (arm64,
Metal + Accelerate) je izgrađen. **Debug i Release build prolaze**, a skripta
pravi nepotpisan `build/DiktatorIOS.ipa` (~1.6 MB bez modela).

Potpisivanje besplatnim **Personal Team**-om je potvrđeno: Xcode pravi profile
za oba targeta, a aplikacija je instalirana i pokrenuta na iPhone 15 Pro
(iOS 27.0.1). Developer Mode i trust developer profila su uključeni. Simulator
(iPhone 17, iOS 26.5) takođe potvrđuje da se aplikacija pokreće i da
`diktator-ios://dictate` počinje snimanje.

Za srpski je preporučen model **Large v3**; Turbo je brži, ali na srpskom ume
više da pogreši. Na srpskom sistemu aplikacija podrazumevano bira jezik
**Srpski**, a ne automatsku detekciju.

Sledeće je testiranje **AltStore/SideStore** potpisivanja i instalacije IPA-e,
uključujući keyboard extension.

## Šta je odlučeno

- iOS tastatura **ne može da pristupi mikrofonu** — Apple to zabranjuje svim
  app extension-ima. Zato glavna aplikacija snima i prepisuje.
- **App Groups nisu dostupne sa besplatnim Apple ID-jem**, pa ih ne koristimo.
- Tekst se predaje tastaturi preko **clipboarda**: aplikacija kopira prepis,
  tastatura ga ubacuje dugmetom **Nalepi**.
- Tastatura je **puna QWERTY tastatura** sa srpskim slovima `čćžšđ`, brojevima
  i dugmadima **Diktiraj** / **Nalepi**.
- Za srpski je potreban **whisper.cpp**; Apple Speech ne podržava srpski.
- Instalacija je moguća sa besplatnim Apple ID-jem, ali profil traje **7 dana**
  i mora da se obnovi (AltStore/SideStore ili Xcode).

Detalji: [PLAN.md](PLAN.md) i
[docs/instalacija-bez-naloga.md](docs/instalacija-bez-naloga.md).

## Struktura

```text
app/
  DiktatorIOS/       SwiftUI aplikacija: snimanje, whisper, modeli, istorija
  DiktatorKeyboard/  puna custom tastatura: Diktiraj + Nalepi
  DiktatorIOS.xcodeproj
  project.yml        XcodeGen specifikacija
  pripremi-whisper-ios.sh
scripts/             pravljenje IPA za AltStore/SideStore
docs/                arhitektura i uputstvo za instalaciju
```

## Licenca

MIT — vidi [LICENSE](LICENSE).

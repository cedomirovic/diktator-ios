# Diktator iOS

Mobilna verzija aplikacije **Diktator** za iPhone/iPad: izdiktiraš na srpskom
ili engleskom, a tekst se lokalno prepiše i ubaci u bilo koju aplikaciju.

Projekat je nastao iz macOS aplikacije
[Diktator](https://github.com/cedomirovic/pitchi). Cilj je isti princip:
**snimak i tekst ostaju na uređaju**, bez slanja zvuka na server.

- GitHub: <https://github.com/cedomirovic/diktator-ios>
- Aplikacija: **Diktator iOS** (`com.cedomirovic.diktator.ios`)
- Tastatura: `com.cedomirovic.diktator.ios.keyboard`
- Podrazumevani model: **Large v3 Turbo q5_0** (~547 MB)
- Minimum iOS 17; ciljani test na iOS 26

## Status

Xcode 26.6 je instaliran i whisper.cpp za iOS (arm64, Metal + Accelerate) je
izgrađen. **Debug i Release build prolaze**, a skripta pravi nepotpisan
`build/DiktatorIOS.ipa` (~1.6 MB bez modela). Simulator (iPhone 17, iOS 26.5)
potvrđuje da se aplikacija pokreće i da `diktator-ios://dictate` počinje
snimanje. Potpisivanje i test na iPhone-u tek slede: na Macu trenutno nema
potpisnog identiteta ni povezanog uređaja.

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

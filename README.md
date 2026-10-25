# Diktator iOS

Mobilna verzija aplikacije **Diktator** za iPhone/iPad: izdiktiraš na srpskom
ili engleskom, a tekst se lokalno prepiše i ubaci u bilo koju aplikaciju.

Projekat je nastao iz macOS aplikacije
[Diktator](https://github.com/cedomirovic/pitchi). Cilj je isti princip:
**snimak i tekst ostaju na uređaju**, bez slanja zvuka na server.

## Status

Skelet projekta i odluke su u toku. Xcode još nije instaliran na razvojnom
Macu, pa build još nije pokrenut.

## Šta je već odlučeno

- iOS tastatura **ne može da pristupi mikrofonu** — Apple to zabranjuje svim
  app extension-ima. Zato glavna aplikacija snima i prepisuje.
- **App Groups nisu dostupne sa besplatnim Apple ID-jem**, pa ih ne koristimo.
- Tekst se predaje tastaturi preko **clipboarda**: aplikacija kopira prepis,
  tastatura ga ubacuje dugmetom **Nalepi**.
- Za srpski je potreban **whisper.cpp**; Apple Speech ne podržava srpski.
- Instalacija je moguća sa besplatnim Apple ID-jem, ali profil traje **7 dana**
  i mora da se obnovi (Xcode ili AltStore/SideStore).

Detalji: [PLAN.md](PLAN.md) i
[docs/instalacija-bez-naloga.md](docs/instalacija-bez-naloga.md).

## Predviđena struktura

```text
app/
  DiktatorIOS/       SwiftUI aplikacija: snimanje, whisper, modeli, istorija
  DiktatorKeyboard/  custom tastatura: Diktiraj + Nalepi
  Shared/            transliteracija, modeli, pomoćne funkcije
docs/                arhitektura i uputstvo za instalaciju
```

## Licenca

MIT — vidi [LICENSE](LICENSE).

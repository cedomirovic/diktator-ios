# Instalacija bez plaćenog Apple Developer naloga

Ovo uputstvo je za iPhone/iPad i Mac. **Plaćeni Apple Developer Program
(99 $/god.) nije potreban** — dovoljan je običan Apple ID. Ali postoje
ograničenja koja moraju da se znaju:

- Potpis sa besplatnim Apple ID-jem važi **7 dana**. Posle toga aplikacija
  prestaje da se pokreće dok se build ponovo ne potpiše i instalira.
- Besplatni nalog dozvoljava **najviše 3 aplikacije** istovremeno.
- **App Groups nisu dostupne** sa besplatnim nalogom. Zato Diktator iOS ne
  koristi App Group, nego clipboard za prenos teksta iz aplikacije u
  tastaturu.
- Nema push obaveštenja, iCloud container-a ni App Store distribucije.
- Ovo je lična/sideload instalacija, ne aplikacija iz App Store-a.

Aplikacija se sastoji iz **dva targeta**:

1. `DiktatorIOS` — glavna aplikacija (snima, prepisuje, čuva modele).
2. `DiktatorKeyboard` — puna custom tastatura (kuca, otvara aplikaciju i
   ubacuje tekst iz clipboarda).

Oba targeta moraju da budu potpisana istim timom.

---

## 1. Šta je potrebno

- Mac sa **Xcode 26.x** (App Store). Samo Command Line Tools nije dovoljno.
- iPhone/iPad sa **iOS 17 ili novijim** (preporučeno iOS 26).
- USB kabl (prvi put), Apple ID, internet za prvi build i preuzimanje modela.
- Dovoljno prostora na disku za Xcode (~10 GB) i modele (od ~57 MB do ~1 GB).

Izabrani tok je **AltStore/SideStore**: Xcode služi da se napravi IPA, a
AltStore/SideStore potpisuje i instalira aplikaciju tvojim besplatnim Apple
ID-jem. Xcode može i direktno da instalira aplikaciju; to je rezervni način,
koristan ako AltStore/SideStore ne uspe da potpiše keyboard extension.

---

## 2. Build i potpisivanje u Xcode-u

### 2.1. Pripremi Xcode

1. Instaliraj **Xcode** iz App Store-a.
2. Otvori ga jednom i prihvati licencu; sačekaj da se instalira iOS platforma
   (Xcode → Settings → Platforms).
3. Ako `xcodebuild` i dalje gleda u Command Line Tools, u Terminalu pokreni:

   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   xcodebuild -version
   ```

### 2.2. Dodaj Apple ID i napravi Personal Team

1. Xcode → **Settings** → **Accounts** → **+** → Apple ID.
2. Prijavi se svojim Apple ID-jem.
3. U listi naloga izaberi **Personal Team** (besplatni tim).

### 2.3. Podesi potpisivanje

U projektu postoje dva targeta. Za oba:

1. Izaberi target → **Signing & Capabilities**.
2. Uključi **Automatically manage signing**.
3. **Team**: izaberi svoj Personal Team.
4. **Bundle Identifier** mora da bude jedinstven. Predlog:
   - aplikacija: `com.cedomirovic.diktator.ios`
   - tastatura: `com.cedomirovic.diktator.ios.keyboard`
5. Ako Xcode prijavi da je ID zauzet, dodaj svoj jedinstveni deo, npr.
   `com.cedomirovic.diktator.ios2026` i
   `com.cedomirovic.diktator.ios2026.keyboard`. **Oba ID-ja moraju da počinju
   istim prefiksom** (tastatura je extension aplikacije).

Ne dodaj App Group, push, iCloud ni Keychain Sharing — nisu potrebni i traže
plaćeni nalog.

### 2.4. Uključi Developer Mode na iPhone-u

1. Poveži iPhone kablom sa Macom.
2. Na iPhone-u: **Settings → Privacy & Security → Developer Mode → On**.
3. Potvrdi restart i posle restarta uključi Developer Mode.
4. Ako iPhone pita „Trust This Computer?“, tapni **Trust** i unesi šifru.

### 2.5. Pokreni aplikaciju

1. U Xcode-u izaberi svoj iPhone kao destinaciju (gore levo).
2. Izaberi šemu `DiktatorIOS`.
3. **Run** (⌘R).
4. Xcode će prvi put napraviti profil i potpisati oba targeta. Ako traži
   dozvolu za pristup ključevima, dozvoli.
5. Kada se aplikacija pojavi na iPhone-u, ako se ne otvori, idi na
   **Settings → General → VPN & Device Management → Developer App** i tapni
   **Trust**.

### 2.6. Dodaj tastaturu

1. iPhone: **Settings → General → Keyboard → Keyboards → Add New Keyboard**.
2. Izaberi **Diktator**.
3. Tapni **Diktator** u listi i uključi **Allow Full Access**.
   - Full Access je potreban da tastatura pročita clipboard i ubaci tekst.
   - Bez njega možeš ručno da nalepiš tekst u ciljnoj aplikaciji.
4. U aplikaciji Diktator dozvoli **mikrofon** kada se pojavi pitanje.
5. Otvori aplikaciju, preuzmi model (podrazumevano **Large v3 Turbo q5_0**,
   ~547 MB) i probaj diktat.

### 2.7. Kako se koristi

1. U bilo kojoj aplikaciji otvori tekstualno polje i prebaci tastaturu na
   **Diktator** (globus/ikona tastature).
2. Možeš da kucaš direktno na Diktator tastaturi (QWERTY + `čćžšđ`), ili da
   tapneš **Diktiraj** — otvoriće se Diktator aplikacija.
3. Snimi govor; aplikacija prepisuje lokalno i kopira tekst u clipboard.
4. Vrati se u prethodnu aplikaciju preko **„Back to …“** u statusnoj traci ili
   preko app switcher-a.
5. U tastaturi tapni **Nalepi** — tekst se ubacuje u polje.

---

## 3. IPA za AltStore/SideStore

Kada je projekat napravljen, IPA se pravi iz Xcode-a ili skriptom
`scripts/napravi-ipa.sh`. Ručni postupak:

```bash
xcodebuild -project app/DiktatorIOS.xcodeproj \
  -scheme DiktatorIOS \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO build

mkdir -p build/Payload
cp -R build/Build/Products/Release-iphoneos/DiktatorIOS.app build/Payload/
cd build
zip -r DiktatorIOS.ipa Payload
```

1. Instaliraj **AltServer** na Mac i **AltStore** na iPhone (ili SideStore).
2. Prijavi se svojim Apple ID-jem u AltStore/SideStore.
3. Prenesi `DiktatorIOS.ipa` na iPhone (AirDrop, Files, iCloud Drive…).
4. Otvori IPA u AltStore/SideStore i instaliraj.
5. Uključi Developer Mode i trust developer ako se traži.

**Napomena:** IPA je nepotpisan; AltStore/SideStore ga potpisuje tvojim
Apple ID-jem. Ako alat ne uspe da potpiše ugrađeni keyboard extension,
instaliraj direktno iz Xcode-a (odeljak 2) ili koristi Xcode za osvežavanje.

---

## 4. Osvežavanje posle 7 dana

Besplatni profil ističe posle 7 dana. Aplikacija tada neće da se pokrene.

### Opcija A: AltStore / SideStore

AltStore i SideStore mogu da potpišu aplikaciju tvojim besplatnim Apple ID-jem
i da je osvežavaju pre isteka.

- **AltStore**: na Mac-u instaliraj **AltServer**, na iPhone-u **AltStore**,
  prijavi se Apple ID-jem, pa instaliraj IPA. AltServer osvežava aplikaciju
  dok je iPhone na istoj mreži.
- **SideStore**: slično, ali može da osvežava na samom iPhone-u preko lokalnog
  VPN-a; prvo podešavanje i dalje traži Mac.

### Opcija B: ponovo iz Xcode-a

1. Poveži iPhone (ili koristi bežično povezivanje).
2. Otvori projekat u Xcode-u.
3. Izaberi iPhone i **Run** ponovo.
4. Ako je istekao profil, Xcode će ga obnoviti.

**Napomena:** pošto aplikacija ima keyboard extension, nije svaki IPA tok
podržan. Ako AltStore/SideStore ne uspe da potpiše extension, koristi Xcode.
Xcode je jedini siguran način za prvi build.

---

## 5. Česte greške

| Problem | Rešenje |
|---|---|
| `xcodebuild` ne radi / „requires Xcode“ | `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` |
| `xcodebuild` traži prihvatanje licence | `sudo xcodebuild -license accept` |
| „No signing certificate“ | Xcode → Settings → Accounts → Apple ID → Personal Team; uključi Automatically manage signing. |
| „Bundle identifier is not available“ | Promeni bundle ID za oba targeta, zadrži isti prefiks. |
| Aplikacija se ne otvara posle instalacije | Settings → General → VPN & Device Management → Trust developer. |
| Tastatura se ne vidi | Settings → General → Keyboard → Keyboards → Add New Keyboard → Diktator. |
| **Nalepi** ne radi | Uključi **Allow Full Access** za Diktator tastaturu. |
| Nema zvuka / mikrofon ne radi | Settings → Privacy & Security → Microphone → Diktator. |
| Posle 7 dana „Unable to Verify App“ | Obnovi build preko Xcode-a ili AltStore/SideStore. |
| Model se ne preuzima | Proveri internet i prostor; modeli su veliki (57 MB–1 GB). |
| Aplikacija traži Developer Mode | Settings → Privacy & Security → Developer Mode → On. |

---

## 6. Privatnost i bezbednost

- Snimak se obrađuje **lokalno**; zvuk se ne šalje na server.
- Tastatura sa **Full Access** tehnički može da vidi ono što kucaš. Diktator
  tastatura ne šalje podatke na mrežu i ne čuva istoriju; clipboard čita samo
  kada tapneš **Nalepi**.
- LLM doterivanje nije u prvoj verziji. Ako se kasnije doda, **samo tekst** bi
  se slao izabranom servisu (Gemini/DeepSeek/OpenAI/…); zvuk nikada.
- API ključevi se čuvaju u Keychain-u, ne u git-u.

---

## 7. Šta ovo rešenje ne može

- Tastatura **ne može da snima** — Apple to zabranjuje. Zato se snima u
  glavnoj aplikaciji i vraćaš se u ciljnu aplikaciju.
- Ne postoji automatski povratak u prethodnu aplikaciju; koristi se statusna
  traka „Back to …“.
- Nema App Group-a, pa tastatura i aplikacija ne dele istoriju ni podešavanja;
  istorija i rečnik su samo u glavnoj aplikaciji.
- Nema App Store distribucije; ovo je lična instalacija.
- Besplatni profil traje 7 dana.

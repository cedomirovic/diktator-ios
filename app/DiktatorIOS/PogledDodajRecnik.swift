import SwiftUI

/// Diktat iz kog se dodaju pojmovi u rečnik. `Identifiable` postoji da bi
/// `.sheet(item:)` mogao da prikaže listu.
struct PredlogRecnika: Identifiable {
    let id = UUID()
    let tekst: String
}

/// Brzo građenje rečnika iz gotovog diktata. Predlažu se reči koje počinju
/// velikim slovom (imena, firme, mesta), a preporučene su one koje nisu na
/// početku rečenice — tu su često obične reči. Sve može i ručno da se dopiše,
/// a pojmovi koji su već u rečniku se ne prikazuju i ne dodaju dvaput.
struct PogledDodajRecnik: View {
    @EnvironmentObject private var stanje: AppStanje
    @Environment(\.dismiss) private var dismiss

    let tekst: String

    @State private var izabrano: Set<String> = []
    @State private var noviPojmovi = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    uvodnaKartica
                    predloziKartica
                    rucniUnosKartica
                }
                .frame(maxWidth: 640)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
            }
            .background(Dizajn.pozadina)
            .navigationTitle("Dodaj u rečnik")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Otkaži") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                dugmeDodaj
            }
            .onAppear {
                izabrano = predizabrani
            }
        }
    }

    // MARK: - Delovi

    private var uvodnaKartica: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Iz diktata")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Dizajn.tekst)

            Text(tekst)
                .font(.system(size: 14))
                .foregroundStyle(Dizajn.tekstSekundarni)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)

            Text("Izaberi imena, firme i pojmove koje Whisper treba da prepozna.")
                .font(.system(size: 12))
                .foregroundStyle(Dizajn.tekstTercijarni)
                .fixedSize(horizontal: false, vertical: true)
        }
        .kartica()
    }

    private var predloziKartica: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Predlozi")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Dizajn.tekst)

                Spacer()

                if !kandidati.isEmpty {
                    Button(izabrano.count == kandidati.count ? "Očisti" : "Izaberi sve") {
                        izabrano = izabrano.count == kandidati.count
                            ? []
                            : Set(kandidati)
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Dizajn.akcenat)
                }
            }

            if kandidati.isEmpty {
                Text("U ovom diktatu nema novih imena. Upiši pojam ispod.")
                    .font(.system(size: 14))
                    .foregroundStyle(Dizajn.tekstSekundarni)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 104), spacing: 8)],
                    alignment: .leading,
                    spacing: 8
                ) {
                    ForEach(kandidati, id: \.self) { pojam in
                        dugmeZaPojam(pojam)
                    }
                }
            }

            if !postojeci.isEmpty {
                Text("Pojmovi koji su već u rečniku se preskaču.")
                    .font(.system(size: 12))
                    .foregroundStyle(Dizajn.tekstTercijarni)
            }
        }
        .kartica()
    }

    private var rucniUnosKartica: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Novi pojam")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Dizajn.tekst)

            Text("Ako ime nije predloženo, upiši ga ovde. Više pojmova odvoji zarezom.")
                .font(.system(size: 13))
                .foregroundStyle(Dizajn.tekstSekundarni)
                .fixedSize(horizontal: false, vertical: true)

            TextField("npr. Nemanja, Pitchi, Beograd", text: $noviPojmovi)
                .font(.system(size: 15))
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(12)
                .background(
                    Dizajn.pozadina,
                    in: RoundedRectangle(cornerRadius: Dizajn.radijusReda, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Dizajn.radijusReda, style: .continuous)
                        .stroke(Dizajn.ivica, lineWidth: 1)
                )
        }
        .kartica()
    }

    private var dugmeDodaj: some View {
        VStack(spacing: 6) {
            Button {
                dodaj()
            } label: {
                Label(naslovDugmeta, systemImage: "text.badge.plus")
            }
            .buttonStyle(StilDugmeta())
            .disabled(pojmoviZaDodavanje.isEmpty)
            .opacity(pojmoviZaDodavanje.isEmpty ? 0.5 : 1)

            Text("Duplikati se automatski preskaču.")
                .font(.system(size: 11))
                .foregroundStyle(Dizajn.tekstTercijarni)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    private func dugmeZaPojam(_ pojam: String) -> some View {
        let aktivan = izabrano.contains(pojam)
        return Button {
            if aktivan {
                izabrano.remove(pojam)
            } else {
                izabrano.insert(pojam)
            }
        } label: {
            HStack(spacing: 4) {
                if aktivan {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                }
                Text(pojam)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .foregroundStyle(aktivan ? Color.white : Dizajn.tekst)
            .background(
                aktivan ? Dizajn.akcenat : Dizajn.pozadina,
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .stroke(aktivan ? Color.clear : Dizajn.ivica, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Podaci

    /// Pojmovi koji su već sačuvani u rečniku, malim slovima za poređenje.
    private var postojeci: Set<String> {
        Set(
            stanje.recnik
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                .filter { !$0.isEmpty }
        )
    }

    /// Kandidati iz diktata i oni koje vredi unapred označiti. Prva reč
    /// rečenice se prikazuje, ali nije unapred izabrana jer je najčešće
    /// obična reč, a ne ime.
    private var predlozi: (svi: [String], preporuceni: Set<String>) {
        var svi: [String] = []
        var preporuceni: Set<String> = []
        var vidjeno: Set<String> = []
        let granice: Set<Character> = [".", "!", "?", "\n", ":", ";", "…"]

        tekst.enumerateSubstrings(
            in: tekst.startIndex..<tekst.endIndex,
            options: [.byWords, .localized]
        ) { rec, opseg, _, _ in
            guard let rec, rec.count >= 2,
                  let prvo = rec.first, prvo.isUppercase else {
                return
            }

            let kljuc = rec.lowercased()
            guard !vidjeno.contains(kljuc), !postojeci.contains(kljuc) else { return }

            let pre = String(tekst[tekst.startIndex..<opseg.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let naPocetku = pre.isEmpty
                || (pre.last.map { granice.contains($0) } ?? false)

            vidjeno.insert(kljuc)
            svi.append(rec)
            if !naPocetku {
                preporuceni.insert(rec)
            }
        }

        let ograniceni = Array(svi.prefix(60))
        let dozvoljeni = Set(ograniceni)
        return (ograniceni, preporuceni.intersection(dozvoljeni))
    }

    private var kandidati: [String] { predlozi.svi }
    private var predizabrani: Set<String> { predlozi.preporuceni }

    /// Ručno upisani pojmovi, razdvojeni zarezom, tačkom-zarezom ili novim
    /// redom. Razmaci unutar imena ostaju.
    private var rucniPojmovi: [String] {
        noviPojmovi
            .components(separatedBy: CharacterSet(charactersIn: ",;\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// Sve što će biti dodato: izabrani predlozi i ručni unos, bez duplikata
    /// i bez pojmova koji su već u rečniku.
    private var pojmoviZaDodavanje: [String] {
        var rezultat: [String] = []
        var vidjeno: Set<String> = []

        for pojam in Array(izabrano).sorted() + rucniPojmovi {
            let kljuc = pojam.lowercased()
            guard !kljuc.isEmpty,
                  !postojeci.contains(kljuc),
                  !vidjeno.contains(kljuc) else {
                continue
            }
            vidjeno.insert(kljuc)
            rezultat.append(pojam)
        }
        return rezultat
    }

    private var naslovDugmeta: String {
        let broj = pojmoviZaDodavanje.count
        switch broj {
        case 0:
            return "Dodaj u rečnik"
        case 1:
            return "Dodaj 1 pojam u rečnik"
        default:
            return "Dodaj \(broj) pojmova u rečnik"
        }
    }

    private func dodaj() {
        let pojmovi = pojmoviZaDodavanje
        guard !pojmovi.isEmpty else { return }
        let dodatih = stanje.dodajURecnik(pojmovi)
        if dodatih == 1, let pojam = pojmovi.first {
            stanje.poruka = "„\(pojam)“ je dodat u rečnik."
        } else {
            stanje.poruka = "U rečnik je dodato \(dodatih) pojmova."
        }
        dismiss()
    }
}

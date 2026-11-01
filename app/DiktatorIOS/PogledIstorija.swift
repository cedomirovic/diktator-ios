import SwiftUI

struct PogledIstorija: View {
    @EnvironmentObject var stanje: AppStanje
    @State private var pretraga = ""

    private var filtrirano: [Zapis] {
        let upit = pretraga.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !upit.isEmpty else { return stanje.istorija }
        return stanje.istorija.filter { $0.tekst.lowercased().contains(upit) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        NaslovEkrana(
                            naslov: "Istorija",
                            podnaslov: "Vaše prethodne diktacije na jednom mestu."
                        )

                        Button(role: .destructive) {
                            stanje.obrisiIstoriju()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(
                                    stanje.istorija.isEmpty ? Dizajn.tekstTercijarni : Dizajn.crvena
                                )
                                .frame(width: 40, height: 40)
                                .background(Dizajn.kartica, in: Circle())
                                .overlay(Circle().stroke(Dizajn.ivica, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .disabled(stanje.istorija.isEmpty)
                        .accessibilityLabel("Obriši istoriju")
                    }

                    if !stanje.istorija.isEmpty {
                        poljePretrage
                    }

                    if stanje.istorija.isEmpty {
                        prazno
                    } else if filtrirano.isEmpty {
                        Text("Nema zapisa koji sadrže „\(pretraga)“.")
                            .font(.system(size: 14))
                            .foregroundStyle(Dizajn.tekstSekundarni)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(filtrirano) { zapis in
                            red(zapis)
                        }
                    }
                }
                .frame(maxWidth: 640)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity)
            }
            .background(Dizajn.pozadina)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Delovi

    private var poljePretrage: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Dizajn.tekstTercijarni)

            TextField("Pretraži transkripte…", text: $pretraga)
                .font(.system(size: 15))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !pretraga.isEmpty {
                Button {
                    pretraga = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Dizajn.tekstTercijarni)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Dizajn.kartica, in: RoundedRectangle(cornerRadius: Dizajn.radijusReda, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Dizajn.radijusReda, style: .continuous)
                .stroke(Dizajn.ivica, lineWidth: 1)
        )
    }

    private var prazno: some View {
        VStack(spacing: 10) {
            IkonaUKrugu(simbol: "clock", velicina: 48)
            Text("Nema zapisa")
                .font(.system(size: 17, weight: .semibold))
            Text("Prvi diktat će se pojaviti ovde.")
                .font(.system(size: 14))
                .foregroundStyle(Dizajn.tekstSekundarni)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .kartica(padding: 24)
    }

    private func red(_ zapis: Zapis) -> some View {
        HStack(alignment: .top, spacing: 12) {
            IkonaUKrugu(simbol: "doc.text", boja: Dizajn.akcenat, velicina: 38)

            VStack(alignment: .leading, spacing: 4) {
                Text(zapis.tekst)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Dizajn.tekst)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(zapis.datum.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12))
                    .foregroundStyle(Dizajn.tekstTercijarni)
            }

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 6) {
                Oznaka(tekst: trajanje(zapis.trajanje))
                Menu {
                    Button {
                        stanje.kopiraj(zapis.tekst)
                    } label: {
                        Label("Kopiraj", systemImage: "doc.on.doc")
                    }
                    Button(role: .destructive) {
                        obrisi(zapis)
                    } label: {
                        Label("Obriši", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Dizajn.tekstTercijarni)
                        .frame(width: 28, height: 22)
                }
            }
        }
        .kartica(padding: 14)
        .contentShape(Rectangle())
        .onTapGesture {
            stanje.kopiraj(zapis.tekst)
        }
        .contextMenu {
            Button {
                stanje.kopiraj(zapis.tekst)
            } label: {
                Label("Kopiraj", systemImage: "doc.on.doc")
            }
            Button(role: .destructive) {
                obrisi(zapis)
            } label: {
                Label("Obriši", systemImage: "trash")
            }
        }
    }

    /// Trajanje u formatu iz dizajna: 01:32.
    private func trajanje(_ sekunde: Double) -> String {
        let ukupno = max(0, Int(sekunde.rounded()))
        return String(format: "%02d:%02d", ukupno / 60, ukupno % 60)
    }

    private func obrisi(_ zapis: Zapis) {
        stanje.istorija.removeAll { $0.id == zapis.id }
        IstorijaSkladiste.sacuvaj(stanje.istorija)
    }
}

import SwiftUI

struct PogledStatistika: View {
    @EnvironmentObject var stanje: AppStanje
    @State private var potvrdiBrisanje = false

    private var s: Statistika { stanje.statistika }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                NaslovEkrana(
                    naslov: "Statistika",
                    podnaslov: "Pregled napretka i načina korišćenja aplikacije."
                )

                if s.ukupnoSnimaka == 0 {
                    Text("Još nema diktata. Prvi diktat će pokrenuti statistiku.")
                        .font(.system(size: 14))
                        .foregroundStyle(Dizajn.tekstSekundarni)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                mreza
                grafikon
                detalji
                jezici
                reset
            }
            .frame(maxWidth: 640)
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity)
        }
        .background(Dizajn.pozadina)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Obrisati statistiku?",
            isPresented: $potvrdiBrisanje,
            titleVisibility: .visible
        ) {
            Button("Obriši statistiku", role: .destructive) {
                stanje.obrisiStatistiku()
            }
            Button("Otkaži", role: .cancel) {}
        } message: {
            Text("Brišu se samo brojevi. Tekstovi u istoriji ostaju.")
        }
    }

    // MARK: - Kartice sa brojevima

    private var mreza: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            kartica(
                naslov: "Danas",
                vrednost: s.danasReci.formatted(),
                jedinica: "reči",
                ikona: "sun.max.fill"
            )
            kartica(
                naslov: "Niz",
                vrednost: "\(s.nizDana)",
                jedinica: s.nizDana == 1 ? "dan" : "dana",
                ikona: "flame.fill"
            )
            kartica(
                naslov: "Prosečno",
                vrednost: "\(Int(s.prosecnoReciUMinuti.rounded()))",
                jedinica: "reči/min",
                ikona: "speedometer"
            )
            kartica(
                naslov: "Ušteđeno",
                vrednost: s.ustedaTekst,
                jedinica: "vremena",
                ikona: "hourglass"
            )
        }
    }

    private func kartica(
        naslov: String,
        vrednost: String,
        jedinica: String,
        ikona: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                IkonaUKrugu(simbol: ikona, velicina: 32)
                Text(naslov)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Dizajn.tekstSekundarni)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            Text(vrednost)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Dizajn.tekst)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(jedinica)
                .font(.system(size: 12))
                .foregroundStyle(Dizajn.tekstTercijarni)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .kartica(padding: 14)
    }

    // MARK: - Grafikon

    private var grafikon: some View {
        let podaci = s.poslednjih7Dana
        let najveci = max(podaci.map(\.reci).max() ?? 0, 1)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dnevno korišćenje")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Broj diktiranih reči po danima")
                        .font(.system(size: 13))
                        .foregroundStyle(Dizajn.tekstSekundarni)
                }
                Spacer()
                Oznaka(tekst: "\(s.nedeljaReci.formatted()) reči")
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(podaci) { dan in
                    VStack(spacing: 6) {
                        Text(dan.reci > 0 ? "\(dan.reci)" : "")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Dizajn.tekstTercijarni)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(
                                dan.reci > 0
                                    ? Dizajn.akcenat.opacity(0.85)
                                    : Dizajn.ivica
                            )
                            .frame(height: visina(dan.reci, najveci: najveci))

                        Text(dan.oznaka)
                            .font(.system(size: 11))
                            .foregroundStyle(Dizajn.tekstSekundarni)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 148, alignment: .bottom)
        }
        .kartica()
    }

    private func visina(_ reci: Int, najveci: Int) -> CGFloat {
        guard reci > 0 else { return 5 }
        let odnos = CGFloat(reci) / CGFloat(najveci)
        return max(8, odnos * 104)
    }

    // MARK: - Detalji

    private var detalji: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detalji")
                .font(.system(size: 17, weight: .semibold))

            RedPodatka(naslov: "Ukupno vremena govora", vrednost: s.vremeGovoraTekst)
            Divider().overlay(Dizajn.ivica)
            RedPodatka(naslov: "Prosečan diktat", vrednost: Statistika.vreme(s.prosecanDiktatSekundi))
            Divider().overlay(Dizajn.ivica)
            RedPodatka(naslov: "Ovaj mesec", vrednost: "\(s.mesecReci.formatted()) reči")
            Divider().overlay(Dizajn.ivica)
            RedPodatka(naslov: "Najduži niz", vrednost: "\(s.najduziNiz) \(s.najduziNiz == 1 ? "dan" : "dana")")
            if let prvi = s.prviDatum {
                Divider().overlay(Dizajn.ivica)
                RedPodatka(
                    naslov: "Prvi diktat",
                    vrednost: prvi.formatted(date: .abbreviated, time: .omitted)
                )
            }
        }
        .kartica()
    }

    // MARK: - Jezici

    @ViewBuilder
    private var jezici: some View {
        let podaci = s.jeziciSortirano
        if !podaci.isEmpty {
            let ukupno = max(podaci.reduce(0) { $0 + $1.broj }, 1)

            VStack(alignment: .leading, spacing: 12) {
                Text("Jezici")
                    .font(.system(size: 17, weight: .semibold))

                ForEach(podaci) { jezik in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(jezik.naziv)
                                .font(.system(size: 15))
                            Spacer()
                            Text("\(jezik.broj) \(jezik.broj == 1 ? "diktat" : "diktata")")
                                .font(.system(size: 13))
                                .foregroundStyle(Dizajn.tekstSekundarni)
                        }

                        GeometryReader { geometrija in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Dizajn.pozadina)
                                Capsule()
                                    .fill(Dizajn.akcenat.opacity(0.85))
                                    .frame(
                                        width: geometrija.size.width
                                            * CGFloat(jezik.broj) / CGFloat(ukupno)
                                    )
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
            .kartica()
        }
    }

    // MARK: - Brisanje

    private var reset: some View {
        Button(role: .destructive) {
            potvrdiBrisanje = true
        } label: {
            Label("Obriši statistiku", systemImage: "trash")
        }
        .buttonStyle(StilDugmeta(boja: Dizajn.crvena, pun: false))
        .disabled(s.ukupnoSnimaka == 0)
        .opacity(s.ukupnoSnimaka == 0 ? 0.5 : 1)
        .padding(.top, 2)
    }
}

import SwiftUI

struct PogledStatistika: View {
    @EnvironmentObject var stanje: AppStanje
    @State private var potvrdiBrisanje = false

    private var s: Statistika { stanje.statistika }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if s.ukupnoSnimaka == 0 {
                    Text("Još nema diktata. Prvi diktat će pokrenuti statistiku.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
                hero
                mreza
                grafikon
                detalji
                jezici
                reset
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Statistika")
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

    private var hero: some View {
        VStack(spacing: 10) {
            Text(s.ukupnoReci.formatted())
                .font(.system(size: 54, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text("izdiktiranih reči")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 18) {
                Label(
                    "\(s.ukupnoSnimaka.formatted()) \(s.ukupnoSnimaka == 1 ? "diktat" : "diktata")",
                    systemImage: "mic.fill"
                )
                Label(s.ustedaTekst, systemImage: "clock.fill")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(
            LinearGradient(
                colors: [Color.accentColor.opacity(0.22), Color.accentColor.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var mreza: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            kartica(
                naslov: "Danas",
                vrednost: s.danasReci.formatted(),
                jedinica: "reči",
                ikona: "sun.max.fill",
                boja: .orange
            )
            kartica(
                naslov: "Niz",
                vrednost: "\(s.nizDana)",
                jedinica: s.nizDana == 1 ? "dan" : "dana",
                ikona: "flame.fill",
                boja: .red
            )
            kartica(
                naslov: "Prosečno",
                vrednost: "\(Int(s.prosecnoReciUMinuti.rounded()))",
                jedinica: "reči/min",
                ikona: "speedometer",
                boja: .blue
            )
            kartica(
                naslov: "Ušteđeno",
                vrednost: s.ustedaTekst,
                jedinica: "vremena",
                ikona: "hourglass",
                boja: .green
            )
        }
    }

    private func kartica(
        naslov: String,
        vrednost: String,
        jedinica: String,
        ikona: String,
        boja: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: ikona)
                    .foregroundStyle(boja)
                Text(naslov)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            Text(vrednost)
                .font(.title2.bold())
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(jedinica)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var grafikon: some View {
        let podaci = s.poslednjih7Dana
        let najveci = max(podaci.map(\.reci).max() ?? 0, 1)

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Poslednjih 7 dana")
                    .font(.headline)
                Spacer()
                Text("\(s.nedeljaReci.formatted()) reči")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(podaci) { dan in
                    VStack(spacing: 6) {
                        Text(dan.reci > 0 ? "\(dan.reci)" : "")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                dan.reci > 0
                                    ? Color.accentColor.gradient
                                    : Color.secondary.opacity(0.15).gradient
                            )
                            .frame(height: visina(dan.reci, najveci: najveci))

                        Text(dan.oznaka)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 150, alignment: .bottom)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func visina(_ reci: Int, najveci: Int) -> CGFloat {
        guard reci > 0 else { return 5 }
        let odnos = CGFloat(reci) / CGFloat(najveci)
        return max(8, odnos * 108)
    }

    private var detalji: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detalji")
                .font(.headline)

            red("Ukupno vremena govora", s.vremeGovoraTekst)
            Divider()
            red("Prosečan diktat", Statistika.vreme(s.prosecanDiktatSekundi))
            Divider()
            red("Ovaj mesec", "\(s.mesecReci.formatted()) reči")
            Divider()
            red("Najduži niz", "\(s.najduziNiz) \(s.najduziNiz == 1 ? "dan" : "dana")")
            if let prvi = s.prviDatum {
                Divider()
                red("Prvi diktat", prvi.formatted(date: .abbreviated, time: .omitted))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func red(_ naslov: String, _ vrednost: String) -> some View {
        HStack {
            Text(naslov)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(vrednost)
                .font(.subheadline.weight(.semibold))
        }
    }

    @ViewBuilder
    private var jezici: some View {
        let podaci = s.jeziciSortirano
        if !podaci.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Jezici")
                    .font(.headline)

                ForEach(podaci) { jezik in
                    HStack {
                        Text(jezik.naziv)
                            .font(.subheadline)
                        Spacer()
                        Text("\(jezik.broj) \(jezik.broj == 1 ? "diktat" : "diktata")")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var reset: some View {
        Button(role: .destructive) {
            potvrdiBrisanje = true
        } label: {
            Label("Obriši statistiku", systemImage: "trash")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(s.ukupnoSnimaka == 0)
        .padding(.top, 4)
    }
}

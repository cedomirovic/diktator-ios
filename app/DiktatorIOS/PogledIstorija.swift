import SwiftUI

struct PogledIstorija: View {
    @EnvironmentObject var stanje: AppStanje

    var body: some View {
        NavigationStack {
            Group {
                if stanje.istorija.isEmpty {
                    ContentUnavailableView(
                        "Nema zapisa",
                        systemImage: "clock",
                        description: Text("Prvi diktat će se pojaviti ovde.")
                    )
                } else {
                    List {
                        ForEach(stanje.istorija) { zapis in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(zapis.tekst)
                                    .lineLimit(3)
                                HStack(spacing: 6) {
                                    Text(zapis.datum, style: .date)
                                    Text(zapis.datum, style: .time)
                                    Text("•")
                                    Text(zapis.jezik.uppercased())
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                stanje.kopiraj(zapis.tekst)
                            }
                        }
                        .onDelete { indeksi in
                            stanje.istorija.remove(atOffsets: indeksi)
                            IstorijaSkladiste.sacuvaj(stanje.istorija)
                        }
                    }
                }
            }
            .navigationTitle("Istorija")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        stanje.obrisiIstoriju()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(stanje.istorija.isEmpty)
                }
            }
        }
    }
}

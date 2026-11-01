import SwiftUI

struct PogledRecnik: View {
    @EnvironmentObject var stanje: AppStanje

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    NaslovEkrana(
                        naslov: "Rečnik",
                        podnaslov: "Imena, firme i pojmovi koje Whisper treba da prepozna."
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Jedan pojam po redu. Whisper ih koristi kao nagoveštaj pri prepisu.")
                            .font(.system(size: 13))
                            .foregroundStyle(Dizajn.tekstSekundarni)
                            .fixedSize(horizontal: false, vertical: true)

                        TextEditor(text: $stanje.recnik)
                            .font(.system(size: 15))
                            .scrollContentBackground(.hidden)
                            .padding(10)
                            .frame(minHeight: 300)
                            .background(Dizajn.pozadina)
                            .clipShape(RoundedRectangle(cornerRadius: Dizajn.radijusReda, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: Dizajn.radijusReda, style: .continuous)
                                    .stroke(Dizajn.ivica, lineWidth: 1)
                            )

                        Button("Sačuvaj rečnik") {
                            stanje.sacuvajRecnik()
                        }
                        .buttonStyle(StilDugmeta())
                    }
                    .kartica()
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
}

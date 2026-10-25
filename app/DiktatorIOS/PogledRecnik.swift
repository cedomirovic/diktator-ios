import SwiftUI

struct PogledRecnik: View {
    @EnvironmentObject var stanje: AppStanje

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Upiši imena, firme i pojmove koje Whisper treba da prepozna. Jedan pojam po redu.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                TextEditor(text: $stanje.recnik)
                    .font(.body)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(minHeight: 300)

                Button("Sačuvaj rečnik") {
                    stanje.sacuvajRecnik()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
            .navigationTitle("Rečnik")
        }
    }
}

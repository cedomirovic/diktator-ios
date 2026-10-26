import SwiftUI

struct PogledPodesavanja: View {
    @EnvironmentObject var stanje: AppStanje

    private var verzija: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        Form {
            Section("Model") {
                Text("Izabran: \(Modeli.nadji(stanje.podesavanja.model)?.naziv ?? "—")")
                    .font(.headline)

                if stanje.modelSePreuzima {
                    ProgressView(value: stanje.napredakPreuzimanja ?? 0) {
                        Text("Preuzimanje modela…")
                    }
                }

                ForEach(Modeli.svi) { model in
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(model.naziv)
                                    .font(.headline)
                                if model.preporucen {
                                    Text("Preporučeno")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.blue)
                                }
                            }
                            Text(model.velicinaTekst)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(model.opis)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if stanje.podesavanja.model == model.id && model.preuzet {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else if model.preuzet {
                            Button("Izaberi") {
                                stanje.izaberiModel(model)
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Button("Preuzmi") {
                                stanje.preuzmiModel(model)
                            }
                            .buttonStyle(.bordered)
                            .disabled(stanje.modelSePreuzima)
                        }
                    }
                    .padding(.vertical, 2)
                }

                Button("Oslobodi model sada") {
                    stanje.oslobodiModel()
                }
            }

            Section("Diktat") {
                Picker("Jezik", selection: $stanje.podesavanja.jezik) {
                    Text("Automatski (sr/en)").tag("auto")
                    Text("Srpski").tag("sr")
                    Text("Engleski").tag("en")
                }

                Text("Za najbolji srpski izaberi **Srpski**. Automatska detekcija je korisna kada smenjuješ srpski i engleski, ali na kratkim snimcima ume da pogreši.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("Režim prepisa", selection: $stanje.podesavanja.rezimPrepisa) {
                    ForEach(RezimPrepisa.allCases) { rezim in
                        Text(rezim.naziv).tag(rezim.rawValue)
                    }
                }

                Picker("Oslobodi model", selection: $stanje.podesavanja.oslobadjanjeModela) {
                    ForEach(OslobadjanjeModela.allCases) { opcija in
                        Text(opcija.naziv).tag(opcija.rawValue)
                    }
                }

                Toggle("Čuvaj istoriju", isOn: $stanje.podesavanja.cuvajIstoriju)
            }

            Section("O aplikaciji") {
                LabeledContent("Verzija", value: verzija)
                Link("GitHub projekat", destination: URL(string: "https://github.com/cedomirovic/diktator-ios")!)
                Text("Snimak i tekst ostaju na uređaju. Model se preuzima sa Hugging Face-a.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Podešavanja")
        .onChange(of: stanje.podesavanja) { _, _ in
            stanje.sacuvajPodesavanja()
        }
    }
}

import SwiftUI

struct PogledPodesavanja: View {
    @EnvironmentObject var stanje: AppStanje
    @State private var kljucVidljiv = false

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

            Section("Brzina") {
                Picker(
                    "Način",
                    selection: Binding(
                        get: { stanje.podesavanja.rezimBrzine },
                        set: { stanje.postaviRezimBrzine($0) }
                    )
                ) {
                    ForEach(RezimBrzine.allCases) { rezim in
                        Text(rezim.naziv).tag(rezim.rawValue)
                    }
                }

                Text(RezimBrzine.iz(stanje.podesavanja.rezimBrzine).opis)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if stanje.podesavanja.prepisOblak {
                    HStack {
                        if kljucVidljiv {
                            TextField("Groq API ključ", text: $stanje.kljucOblaka)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("Groq API ključ", text: $stanje.kljucOblaka)
                        }
                        Button {
                            kljucVidljiv.toggle()
                        } label: {
                            Image(systemName: kljucVidljiv ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(kljucVidljiv ? "Sakrij ključ" : "Prikaži ključ")
                    }

                    Button("Sačuvaj ključ") {
                        stanje.sacuvajKljucOblaka()
                    }

                    HStack {
                        Text("Model")
                            .font(.caption.weight(.medium))
                            .frame(width: 58, alignment: .leading)
                        TextField(
                            PrepisOblak.podrazumevaniModel,
                            text: $stanje.podesavanja.modelOblaka
                        )
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    }

                    Button {
                        stanje.testirajOblak()
                    } label: {
                        if stanje.testiraOblak {
                            HStack(spacing: 6) {
                                ProgressView()
                                Text("Testiram…")
                            }
                        } else {
                            Label("Test veze", systemImage: "bolt.horizontal")
                        }
                    }
                    .disabled(
                        stanje.testiraOblak ||
                        stanje.kljucOblaka.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )

                    if let poruka = stanje.porukaOblaka {
                        Text(poruka)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("Ključ praviš na console.groq.com → API Keys. Model: whisper-large-v3-turbo (može i whisper-large-v3). Ako Groq ne odgovori, prepis se radi na uređaju.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if !stanje.podesavanja.prepisOblak {
                    Text("Model za prepis: \(stanje.modelZaPrepis?.naziv ?? "nije preuzet")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if RezimBrzine.iz(stanje.podesavanja.rezimBrzine) == .brzo,
                   let turbo = Modeli.nadji("ggml-large-v3-turbo-q5_0.bin"),
                   !turbo.preuzet {
                    Button("Preuzmi Turbo (~547 MB)") {
                        stanje.preuzmiModel(turbo)
                    }
                    .disabled(stanje.modelSePreuzima)
                }

                Text("Enkoder se sada računa samo za stvarnu dužinu snimka, pa je kratak diktat nekoliko puta brži nego pre.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Section("Doterivanje") {
                Toggle("Popravi interpunkciju i imena", isOn: $stanje.podesavanja.doterivanje)

                Text("Šalje samo gotov tekst izabranom servisu. Isključeno znači da ništa ne napušta uređaj.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if stanje.podesavanja.doterivanje {
                    Picker(
                        "Servis",
                        selection: Binding(
                            get: { stanje.podesavanja.provajderDoterivanja },
                            set: { stanje.izaberiProvajdera($0) }
                        )
                    ) {
                        ForEach(ProvajderiDoterivanja.svi) { provajder in
                            Text(provajder.naziv).tag(provajder.id)
                        }
                    }

                    Text(stanje.provajderDoterivanja.opis)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if stanje.provajderDoterivanja.prikazujeKljuc {
                        HStack {
                            if kljucVidljiv {
                                TextField("API ključ", text: $stanje.kljucDoterivanja)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            } else {
                                SecureField("API ključ", text: $stanje.kljucDoterivanja)
                            }
                            Button {
                                kljucVidljiv.toggle()
                            } label: {
                                Image(systemName: kljucVidljiv ? "eye.slash" : "eye")
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel(kljucVidljiv ? "Sakrij ključ" : "Prikaži ključ")
                        }

                        Button("Sačuvaj ključ") {
                            stanje.sacuvajKljuc()
                        }

                        Text(stanje.provajderDoterivanja.traziKljuc
                            ? "Ključ se čuva u Keychain-u. Ako polje ostane prazno, doterivanje se preskače."
                            : "Ključ nije obavezan; čuva se u Keychain-u ako ga uneseš.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Text(stanje.provajderDoterivanja.uputstvo)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let link = stanje.provajderDoterivanja.link {
                        Link(stanje.provajderDoterivanja.linkNaslov ?? "Otvori", destination: link)
                            .font(.caption)
                    }

                    HStack {
                        Text("Model")
                            .font(.caption.weight(.medium))
                            .frame(width: 58, alignment: .leading)
                        TextField(
                            stanje.provajderDoterivanja.model,
                            text: Binding(
                                get: { stanje.modelDoterivanja },
                                set: { stanje.postaviModelDoterivanja($0) }
                            )
                        )
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    }

                    if stanje.provajderDoterivanja.prikazujeAdresu {
                        HStack {
                            Text("Adresa")
                                .font(.caption.weight(.medium))
                                .frame(width: 58, alignment: .leading)
                            TextField(
                                stanje.provajderDoterivanja.adresa,
                                text: $stanje.podesavanja.adresaCustomDoterivanja
                            )
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                        }
                    }

                    Button {
                        stanje.testirajDoterivanje()
                    } label: {
                        if stanje.testiraDoterivanje {
                            HStack(spacing: 6) {
                                ProgressView()
                                Text("Testiram…")
                            }
                        } else {
                            Label("Test veze", systemImage: "bolt.horizontal")
                        }
                    }
                    .disabled(
                        stanje.testiraDoterivanje ||
                        (stanje.provajderDoterivanja.traziKljuc &&
                         stanje.kljucDoterivanja.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    )

                    if let poruka = stanje.porukaDoterivanja {
                        Text(poruka)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("Ako doterivanje ne uspe, zadržava se sirov prepis.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .onChange(of: stanje.podesavanja.provajderDoterivanja) { _, _ in
                kljucVidljiv = false
            }

            Section("Ažuriranja") {
                Toggle("Proveri nove verzije", isOn: $stanje.podesavanja.proveravajAzuriranja)

                Button("Proveri sada") {
                    stanje.proveriAzuriranja(prisilno: true)
                }

                Button("Testiraj obaveštenje") {
                    stanje.testirajNotifikaciju()
                }

                if let azuriranje = stanje.dostupnoAzuriranje {
                    Link(
                        "Dostupna verzija \(azuriranje.verzija)",
                        destination: azuriranje.url
                    )
                } else {
                    Text("Nema nove verzije.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
        .onChange(of: stanje.podesavanja.proveravajAzuriranja) { _, novo in
            if novo {
                stanje.proveriAzuriranja(prisilno: true)
            } else {
                stanje.dostupnoAzuriranje = nil
            }
        }
    }
}

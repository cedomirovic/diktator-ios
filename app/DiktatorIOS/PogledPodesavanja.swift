import SwiftUI

struct PogledPodesavanja: View {
    @EnvironmentObject var stanje: AppStanje
    @State private var kljucVidljiv = false
    /// Pre prelaska na Groq tražimo potvrdu, jer tada snimak napušta uređaj.
    @State private var potvrdaOblaka = false
    @State private var rezimZaPotvrdu: String?

    private var verzija: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        Form {
            Section {
                NaslovEkrana(
                    naslov: "Podešavanja",
                    podnaslov: "Prilagodi Diktator svom načinu rada."
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 8, trailing: 4))
                .listRowSeparator(.hidden)
            }

            Section(header: zaglavlje("Model")) {
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

                HStack(spacing: 8) {
                    Button("Oslobodi model sada") {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            _ = stanje.oslobodiModel()
                        }
                    }

                    Spacer()

                    Text(Prevod.t(stanje.modelUMemoriji ? "u memoriji" : "nije učitan"))
                        .font(.caption)
                        .foregroundStyle(stanje.modelUMemoriji ? Color.green : Color.secondary)
                }

                if let potvrda = stanje.potvrdaOslobadjanja {
                    Label(
                        potvrda,
                        systemImage: stanje.potvrdaOslobadjanjaUpozorenje
                            ? "info.circle.fill"
                            : "checkmark.circle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        stanje.potvrdaOslobadjanjaUpozorenje ? Color.orange : Color.green
                    )
                    .transition(.opacity)
                }

                Text("Model se sam oslobađa posle izabranog vremena, a ovde možeš da ga oslobodiš odmah. Sledeći diktat ga ponovo učitava.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Section(header: zaglavlje("Diktat")) {
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

                Picker("Trajanje sesije", selection: $stanje.podesavanja.trajanjeSesije) {
                    ForEach(TrajanjeSesije.dostupna) { opcija in
                        Text(opcija.naziv).tag(opcija.rawValue)
                    }
                }

                Text(TrajanjeSesije.iz(stanje.podesavanja.trajanjeSesije).opis)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                #if !APPSTORE
                Toggle("Vrati me u aplikaciju posle diktata", isOn: $stanje.podesavanja.vratiSePosleDiktata)

                if stanje.podesavanja.vratiSePosleDiktata {
                    Text("Kada Diktator otvoriš iz tastature, posle prepisa se sam zatvori i iOS te vrati u aplikaciju u kojoj si diktirao. Tekst se nalepi sam, a pozadinska sesija se pritom gasi.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if TrajanjeSesije.iz(stanje.podesavanja.trajanjeSesije).sekundi == nil {
                        Text("Kod sesije bez isteka Diktator posle prvog diktata ostaje otvoren da sesija ne bi propala — vrati se strelicom ‹, a dalji diktati idu direktno iz tastature.")
                            .font(.caption)
                            .foregroundStyle(Dizajn.tekstTercijarni)
                    }
                } else {
                    Text("Diktator ostaje otvoren posle prepisa; vrati se strelicom ‹ u gornjem levom uglu, a pozadinska sesija ostaje uključena.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                #endif
            }

            Section(header: zaglavlje("Brzina")) {
                Picker(
                    "Način",
                    selection: Binding(
                        get: { stanje.podesavanja.rezimBrzine },
                        set: { novi in
                            if RezimBrzine.iz(novi) == .oblak,
                               !stanje.podesavanja.prepisOblak {
                                rezimZaPotvrdu = novi
                                potvrdaOblaka = true
                            } else {
                                stanje.postaviRezimBrzine(novi)
                            }
                        }
                    )
                ) {
                    ForEach(RezimBrzine.allCases) { rezim in
                        Text(rezim.naziv).tag(rezim.rawValue)
                    }
                }

                Text(RezimBrzine.iz(stanje.podesavanja.rezimBrzine).opis)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !stanje.podesavanja.prepisOblak {
                    Text(stvarnaObrada)
                        .font(.caption)
                        .foregroundStyle(Dizajn.tekstTercijarni)
                }

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
                        withAnimation(.easeInOut(duration: 0.15)) {
                            _ = stanje.sacuvajKljucOblaka()
                        }
                    }

                    if let potvrda = stanje.potvrdaKljucaOblaka {
                        Label(
                            potvrda,
                            systemImage: stanje.potvrdaKljucaOblakaGreska
                                ? "exclamationmark.triangle.fill"
                                : "checkmark.circle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            stanje.potvrdaKljucaOblakaGreska ? Color.orange : Color.green
                        )
                        .transition(.opacity)
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
                            .foregroundStyle(
                                poruka.hasPrefix("Veza radi") ? Color.green : Color.orange
                            )
                        if poruka.contains("401") || poruka.contains("403") {
                            Text("Napravi novi ključ na console.groq.com → API Keys, pa ga nalepi ovde i tapni Sačuvaj ključ. Stari je možda obrisan ili je pogrešno iskopiran.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
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

            Section(header: zaglavlje("Doterivanje")) {
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
                            withAnimation(.easeInOut(duration: 0.15)) {
                                _ = stanje.sacuvajKljuc()
                            }
                        }

                        if let potvrda = stanje.potvrdaKljucaDoterivanja {
                            Label(
                                potvrda,
                                systemImage: stanje.potvrdaKljucaDoterivanjaGreska
                                    ? "exclamationmark.triangle.fill"
                                    : "checkmark.circle.fill"
                            )
                            .font(.caption)
                            .foregroundStyle(
                                stanje.potvrdaKljucaDoterivanjaGreska
                                    ? Color.orange
                                    : Color.green
                            )
                            .transition(.opacity)
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

            #if !APPSTORE
            Section(header: zaglavlje("Ažuriranja")) {
                Toggle("Proveri nove verzije", isOn: $stanje.podesavanja.proveravajAzuriranja)

                Button {
                    stanje.proveriAzuriranja(prisilno: true)
                } label: {
                    HStack {
                        Label("Proveri sada", systemImage: "arrow.clockwise")
                        Spacer()
                        if stanje.proveravaAzuriranja {
                            ProgressView()
                        }
                    }
                }
                .disabled(stanje.proveravaAzuriranja)

                if let azuriranje = stanje.dostupnoAzuriranje {
                    Link(destination: azuriranje.url) {
                        Label(
                            "Preuzmi verziju \(azuriranje.verzija)",
                            systemImage: "arrow.up.right.square"
                        )
                    }
                }

                if let poruka = stanje.porukaAzuriranja {
                    Text(poruka)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    stanje.testirajNotifikaciju()
                } label: {
                    Label("Testiraj obaveštenje", systemImage: "bell.badge")
                }

                if let poruka = stanje.porukaObavestenja {
                    Text(poruka)
                        .font(.caption)
                        .foregroundStyle(stanje.obavestenjaOdbijena ? .orange : .secondary)
                }

                if stanje.obavestenjaOdbijena {
                    Button("Otvori podešavanja iOS-a") {
                        stanje.otvoriPodesavanjaIOS()
                    }
                }
            }
            #endif

            Section(header: zaglavlje("O aplikaciji")) {
                LabeledContent("Verzija", value: verzija)
                #if !APPSTORE
                Link("GitHub projekat", destination: URL(string: "https://github.com/cedomirovic/diktator-ios")!)
                #endif
                Text("Snimak i tekst ostaju na uređaju. Model se preuzima sa Hugging Face-a.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Dizajn.pozadina)
        .listRowBackground(Dizajn.kartica)
        .listSectionSpacing(16)
        .tint(Dizajn.akcenat)
        .navigationTitle("")
        .toolbar(stanje.izabraniTab == 3 ? .hidden : .visible, for: .navigationBar)
        .onChange(of: stanje.podesavanja) { _, _ in
            stanje.sacuvajPodesavanja()
        }
        .onChange(of: stanje.podesavanja.trajanjeSesije) { _, novo in
            stanje.postaviTrajanjeSesije(novo)
        }
        .onChange(of: stanje.podesavanja.proveravajAzuriranja) { _, novo in
            if novo {
                stanje.zatraziDozvoluZaObavestenja()
                stanje.proveriAzuriranja(prisilno: true)
            } else {
                stanje.porukaAzuriranja = nil
            }
        }
        .alert("Snimak ide u Groq?", isPresented: $potvrdaOblaka) {
            Button("Otkaži", role: .cancel) {
                rezimZaPotvrdu = nil
            }
            Button("Nastavi") {
                if let rezim = rezimZaPotvrdu {
                    stanje.postaviRezimBrzine(rezim)
                }
                rezimZaPotvrdu = nil
            }
        } message: {
            Text("U režimu Groq snimak se šalje servisu Groq radi prepisa i tada napušta uređaj. U režimima Brzo i Najtačnije sve ostaje na telefonu. Možeš se vratiti na lokalni prepis u svakom trenutku.")
        }
    }

    /// Zaglavlje grupe u stilu desktop dizajna: bold, bez velikih slova.
    private func zaglavlje(_ naslov: LocalizedStringKey) -> some View {
        Text(naslov)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Dizajn.tekst)
            .textCase(nil)
    }

    /// Tačan opis onoga što se koristi pri prepisu, da izbor modela i režima
    /// nikada ne bude tih. Desktop Diktator radi Large v3, pun audio kontekst
    /// i pretragu snopom — ovde se vidi da li je mobile isto podešen.
    private var stvarnaObrada: String {
        let model = stanje.modelZaPrepis?.naziv ?? "nijedan model"
        let rezim = RezimPrepisa.iz(stanje.podesavanja.rezimPrepisa) == .kvalitet
            ? Prevod.t("pretraga snopom")
            : "greedy"
        let kontekst = stanje.punAudioKontekst
            ? Prevod.t("pun audio kontekst")
            : Prevod.t("skraćen audio kontekst")
        return Prevod.t("Prepisaće: %@, %@, %@.", model, rezim, kontekst)
    }
}

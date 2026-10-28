import SwiftUI
import Foundation

struct PogledDiktat: View {
    @EnvironmentObject var stanje: AppStanje
    @State private var prikaziPodesavanja = false

    private var jeGreska: Bool {
        if case .greska = stanje.stanje { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    Text(stanje.stanje.naslov)
                        .font(.largeTitle.bold())

                    Text(stanje.stanje.detalj)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(jeGreska ? .red : .secondary)
                        .padding(.horizontal)

                    Button {
                        if stanje.stanje.jeSnimanje {
                            stanje.zaustaviSnimanje()
                        } else {
                            stanje.pocniSnimanje()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(stanje.stanje.jeSnimanje ? Color.red : Color.accentColor)
                                .frame(width: 132, height: 132)
                                .shadow(radius: 8)
                            Image(systemName: stanje.stanje.jeSnimanje ? "stop.fill" : "mic.fill")
                                .font(.system(size: 48, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(stanje.stanje.jeZauzet)
                    .padding(.top, 6)

                    if stanje.stanje.jeSnimanje {
                        ProgressView(value: Double(stanje.nivo))
                            .tint(.red)
                            .padding(.horizontal, 44)
                    } else if stanje.stanje.jeZauzet {
                        ProgressView()
                            .tint(.accentColor)
                            .padding(.top, 4)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Sesija diktata", systemImage: "waveform")
                                .font(.headline)
                            Spacer()
                            Text(stanje.sesijaAktivna ? "aktivna" : "isključena")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(stanje.sesijaAktivna ? Color.green : Color.secondary)
                        }

                        if stanje.sesijaAktivna {
                            Text("Tastatura sada može da snima u pozadini, bez otvaranja Diktatora. Preostalo: \(stanje.sesijaPreostalo / 60):\(String(format: "%02d", stanje.sesijaPreostalo % 60))")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            Button("Završi sesiju") {
                                stanje.zavrsiSesiju()
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Text("Uključi sesiju da Diktiraj na tastaturi snima dok je otvorena bilo koja aplikacija. Kada je sesija aktivna, tastatura ne otvara Diktator. Ako sesija nije uključena, otvori Diktator ručno i uključi je.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            Button("Uključi sesiju") {
                                stanje.ukljuciSesiju()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!stanje.modelJePreuzet || stanje.stanje.jeZauzet)
                        }

                        Text("Sesija traje najviše 15 minuta i drži mikrofon u pripravnosti. Zato se automatski gasi.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    statistikaKartica

                    azuriranjeKartica

                    if !stanje.modelJePreuzet {
                        VStack(spacing: 8) {
                            Text("Model još nije preuzet")
                                .font(.headline)
                            Text("Otvori Podešavanja i preuzmi Large v3 (~1,0 GB) — preporučeno za srpski.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Otvori Podešavanja") {
                                prikaziPodesavanja = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    } else if stanje.podesavanja.model == "ggml-large-v3-turbo-q5_0.bin" {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Savet za srpski")
                                .font(.headline)
                            Text("Turbo model je brz, ali za srpski ume da pogreši. Large v3 daje tačniji tekst (~1,0 GB).")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            if let large = Modeli.nadji("ggml-large-v3-q5_0.bin") {
                                if large.preuzet {
                                    Button("Izaberi Large v3") {
                                        stanje.izaberiModel(large)
                                    }
                                    .buttonStyle(.borderedProminent)
                                } else {
                                    Button("Preuzmi Large v3 (~1,0 GB)") {
                                        stanje.preuzmiModel(large)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(stanje.modelSePreuzima)

                                    if stanje.modelSePreuzima {
                                        ProgressView(value: stanje.napredakPreuzimanja ?? 0) {
                                            Text("Preuzimanje Large v3…")
                                                .font(.caption)
                                        }
                                    }
                                }
                            }

                            Button("Otvori Podešavanja") {
                                prikaziPodesavanja = true
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }

                    if stanje.podesavanja.jezik == "auto" {
                        Text("Za srpski je pouzdanije izabrati **Srpski** u Podešavanjima; automatska detekcija je slabija na kratkim snimcima.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    if !stanje.poslednjiTekst.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Poslednji tekst")
                                    .font(.headline)
                                Spacer()
                                Button("Kopiraj") {
                                    stanje.kopirajPoslednji()
                                }
                            }
                            Text(stanje.poslednjiTekst)
                                .textSelection(.enabled)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }

                    if let poruka = stanje.poruka {
                        Text(poruka)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Kako radi")
                            .font(.headline)
                        Text("1. Uključi sesiju ovde (traje do 15 minuta).")
                        Text("2. Pređi u bilo koju aplikaciju i otvori Diktator tastaturu.")
                        Text("3. Tapni Diktiraj — snima u pozadini. Tapni Stop i sačekaj da piše Spremno je, nalepi.")
                        Text("4. Tapni Nalepi — tekst se ubacuje u polje u kome pišeš.")
                        Text("Ako sesija nije uključena, Diktiraj otvara Diktator. Uključi sesiju i vrati se da diktiraš.")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Diktator")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        prikaziPodesavanja = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .navigationDestination(isPresented: $prikaziPodesavanja) {
                PogledPodesavanja()
            }
        }
    }

    private var statistikaKartica: some View {
        NavigationLink {
            PogledStatistika()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Statistika", systemImage: "chart.bar.fill")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }

                if stanje.statistika.ukupnoSnimaka == 0 {
                    Text("Prvi diktat pokreće statistiku.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(stanje.statistika.danasReci.formatted())
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("reči danas")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if stanje.statistika.nizDana > 0 {
                            Label("\(stanje.statistika.nizDana)", systemImage: "flame.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.orange)
                        }
                    }

                    HStack(spacing: 14) {
                        Text("Ukupno \(stanje.statistika.ukupnoReci.formatted())")
                        Text("Ušteđeno \(stanje.statistika.ustedaTekst)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var azuriranjeKartica: some View {
        if let azuriranje = stanje.dostupnoAzuriranje {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Dostupno ažuriranje", systemImage: "arrow.down.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.blue)
                    Spacer()
                    Text("v\(azuriranje.verzija)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Text("Nova verzija je objavljena. Preuzmi je sa GitHub-a.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Link(destination: azuriranje.url) {
                    Label("Preuzmi", systemImage: "arrow.up.right.square")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
}

import SwiftUI

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
                    }

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
                        Text("1. U bilo kojoj aplikaciji otvori Diktator tastaturu.")
                        Text("2. Tapni Diktiraj — ako iOS pita „Open in Diktator?“, tapni Open.")
                        Text("3. Vrati se preko „Back to …“ i tapni Nalepi.")
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
}

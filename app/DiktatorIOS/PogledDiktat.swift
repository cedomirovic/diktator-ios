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
                            Text("Otvori Podešavanja i preuzmi Large v3 Turbo (~547 MB).")
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
                        Text("2. Tapni Diktiraj — aplikacija se otvara i snima.")
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

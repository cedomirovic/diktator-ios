// Kratki zvučni znaci za početak diktata. Puštaju se kroz audio sesiju
// snimanja (`playAndRecord`), pa se čuju i kada je telefon na tihom — za
// razliku od sistemskog zvuka koji prati prekidač za zvono.
import AudioToolbox
import AVFoundation

enum Zvuk {
    /// Zadržavamo poslednji plejer da ga sistem ne bi oslobodio usred tona.
    private static var igrac: AVAudioPlayer?

    /// Dva kratka tona uzlazno — „krećem“.
    static func pustiPocetak() {
        pusti([(880, 0.05), (1320, 0.06)])
    }

    private static func pusti(_ tonovi: [(Double, Double)]) {
        guard let podaci = wav(tonovi) else { return }
        do {
            let novi = try AVAudioPlayer(data: podaci)
            novi.volume = 0.35
            novi.prepareToPlay()
            let pusten = novi.play()
            igrac = novi
            let sesija = AVAudioSession.sharedInstance()
            let izlaz = sesija.currentRoute.outputs.first?.portType.rawValue ?? "-"
            Dnevnik.pisi(
                "Zvuk: play=\(pusten), izlaz=\(izlaz), kategorija=\(sesija.category.rawValue), tihaSesija=\(sesija.isOtherAudioPlaying)"
            )
        } catch {
            // Ako plejer ne uspe, ostaje sistemski zvuk kao rezerva. On se
            // ne čuje na tihom, ali diktat i dalje radi.
            AudioServicesPlaySystemSound(1104)
            Dnevnik.pisi("Zvuk: plejer nije uspeo — \(error.localizedDescription)")
        }
    }

    /// Mono, 44,1 kHz, 16 bita, sa mekim ulazom i izlazom da nema pucanja.
    private static func wav(_ tonovi: [(Double, Double)]) -> Data? {
        let frekvencija = 44_100.0
        var uzorci: [Int16] = []
        for (ton, trajanje) in tonovi {
            let broj = max(1, Int(frekvencija * trajanje))
            for i in 0..<broj {
                let t = Double(i) / frekvencija
                let vrednost = sin(2 * Double.pi * ton * t)
                let ivica = min(1.0, min(Double(i) / 220.0, Double(broj - i) / 220.0))
                let ograniceno = max(-1.0, min(1.0, vrednost * ivica))
                uzorci.append(Int16(ograniceno * 26_000))
            }
        }
        guard !uzorci.isEmpty else { return nil }

        let bitova: UInt16 = 16
        let kanala: UInt16 = 1
        let bajtovaPoUzorku = UInt32(bitova / 8)
        let velicina = UInt32(uzorci.count) * bajtovaPoUzorku

        var podaci = Data(capacity: 44 + Int(velicina))
        func dodaj(_ tekst: String) {
            podaci.append(Data(tekst.utf8))
        }
        func dodaj32(_ vrednost: UInt32) {
            withUnsafeBytes(of: vrednost.littleEndian) { podaci.append(contentsOf: $0) }
        }
        func dodaj16(_ vrednost: UInt16) {
            withUnsafeBytes(of: vrednost.littleEndian) { podaci.append(contentsOf: $0) }
        }

        dodaj("RIFF")
        dodaj32(36 + velicina)
        dodaj("WAVE")
        dodaj("fmt ")
        dodaj32(16)
        dodaj16(1)
        dodaj16(kanala)
        dodaj32(UInt32(frekvencija))
        dodaj32(UInt32(frekvencija) * UInt32(kanala) * bajtovaPoUzorku)
        dodaj16(UInt16(kanala * UInt16(bajtovaPoUzorku)))
        dodaj16(bitova)
        dodaj("data")
        dodaj32(velicina)
        for u in uzorci {
            dodaj16(UInt16(bitPattern: u))
        }
        return podaci
    }
}

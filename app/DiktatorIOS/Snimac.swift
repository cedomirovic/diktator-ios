// Snimanje sa mikrofona i pretvaranje u 16 kHz mono, kako whisper očekuje.
import AVFoundation
import Foundation

enum GreskaSnimka: LocalizedError {
    case nemaMikrofona
    case nemaDozvole
    case pretvaranje

    var errorDescription: String? {
        switch self {
        case .nemaMikrofona:
            return "Nema dostupnog mikrofona."
        case .nemaDozvole:
            return "Diktator nema dozvolu za mikrofon. Otvori Podešavanja → Privatnost i bezbednost → Mikrofon."
        case .pretvaranje:
            return "Snimak nije mogao da se pripremi za prepis."
        }
    }
}

final class Snimac {
    private let motor = AVAudioEngine()
    private let ciljniFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 16_000,
        channels: 1,
        interleaved: false
    )!
    private var pretvarac: AVAudioConverter?
    private let brava = NSLock()
    private var uzorci: [Float] = []
    private var motorRadi = false
    private var sesijaAktivna = false
    private var snimaSada = false
    private var zadnjiNivo = CFAbsoluteTimeGetCurrent()

    var naNivo: ((Float) -> Void)?

    /// Najduži pojedinačni snimak je 5 minuta — duže držanje bi trošilo RAM
    /// i usporilo prepis.
    static let najduzeSekundi = 300

    /// Sesija drži audio motor u pripravnosti da tastatura može da počne
    /// snimanje bez otvaranja aplikacije. Posle ovoga se gasi da ne troši
    /// bateriju i mikrofon.
    static let najduzeSesijeSekundi = 900

    static var dozvola: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .audio)
    }

    static func traziDozvolu() async -> Bool {
        switch dozvola {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { nastavak in
                AVCaptureDevice.requestAccess(for: .audio) { dozvoljeno in
                    nastavak.resume(returning: dozvoljeno)
                }
            }
        default:
            return false
        }
    }

    var snima: Bool {
        brava.lock()
        defer { brava.unlock() }
        return snimaSada
    }

    var jeSesijaAktivna: Bool {
        brava.lock()
        defer { brava.unlock() }
        return sesijaAktivna
    }

    /// Obično snimanje: ako sesija već radi, samo počne da skuplja uzorke.
    func pocni() throws {
        if motorRadi {
            guard sesijaAktivna else { return }
            brava.lock()
            if snimaSada {
                brava.unlock()
                return
            }
            uzorci.removeAll(keepingCapacity: true)
            snimaSada = true
            brava.unlock()
            return
        }

        try pokreniMotor()
        brava.lock()
        snimaSada = true
        brava.unlock()
    }

    /// Uključuje pozadinsku sesiju. Mikrofon i audio motor ostaju aktivni,
    /// ali se uzorci ne skupljaju dok tastatura ne pošalje start.
    func pocniSesiju() throws {
        guard !motorRadi else { return }
        try pokreniMotor()
        brava.lock()
        sesijaAktivna = true
        snimaSada = false
        brava.unlock()
    }

    private func pokreniMotor() throws {
        guard Self.dozvola == .authorized else { throw GreskaSnimka.nemaDozvole }

        let sesija = AVAudioSession.sharedInstance()
        do {
            try sesija.setCategory(.record, mode: .measurement, options: [])
            try sesija.setActive(true, options: [])
        } catch {
            throw GreskaSnimka.nemaMikrofona
        }

        let ulaz = motor.inputNode
        let format = ulaz.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            try? sesija.setActive(false, options: .notifyOthersOnDeactivation)
            throw GreskaSnimka.nemaMikrofona
        }
        guard let pretvarac = AVAudioConverter(from: format, to: ciljniFormat) else {
            try? sesija.setActive(false, options: .notifyOthersOnDeactivation)
            throw GreskaSnimka.pretvaranje
        }
        pretvarac.sampleRateConverterQuality = AVAudioQuality.high.rawValue
        pretvarac.sampleRateConverterAlgorithm = AVSampleRateConverterAlgorithm_Normal

        brava.lock()
        uzorci.removeAll(keepingCapacity: true)
        self.pretvarac = pretvarac
        snimaSada = false
        brava.unlock()

        ulaz.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] bafer, _ in
            self?.obradi(bafer)
        }

        motor.prepare()
        do {
            try motor.start()
        } catch {
            ulaz.removeTap(onBus: 0)
            brava.lock()
            self.pretvarac = nil
            brava.unlock()
            try? sesija.setActive(false, options: .notifyOthersOnDeactivation)
            throw error
        }
        motorRadi = true
    }

    private func obradi(_ bafer: AVAudioPCMBuffer) {
        brava.lock()
        let pretvarac = self.pretvarac
        let trebaSnimati = snimaSada
        brava.unlock()

        guard trebaSnimati, let pretvarac else { return }

        let odnos = ciljniFormat.sampleRate / bafer.format.sampleRate
        let kapacitet = AVAudioFrameCount(Double(bafer.frameLength) * odnos) + 128
        guard let izlaz = AVAudioPCMBuffer(pcmFormat: ciljniFormat, frameCapacity: kapacitet) else {
            return
        }

        var greska: NSError?
        var iskoriscen = false
        let status = pretvarac.convert(to: izlaz, error: &greska) { _, stanje in
            if iskoriscen {
                stanje.pointee = .noDataNow
                return nil
            }
            iskoriscen = true
            stanje.pointee = .haveData
            return bafer
        }
        guard status != .error, let podaci = izlaz.floatChannelData?[0] else { return }

        let broj = Int(izlaz.frameLength)
        guard broj > 0 else { return }
        // Ne pravi privremeni niz za svaki deo — upisujemo direktno iz bafera.
        let deo = UnsafeBufferPointer(start: podaci, count: broj)

        brava.lock()
        uzorci.append(contentsOf: deo)
        brava.unlock()

        // Nivo za UI (RMS u dB, preslikano na 0…1).
        var suma: Float = 0
        for v in deo { suma += v * v }
        let rms = sqrt(suma / Float(broj))
        let db = 20 * log10(max(rms, 0.000_001))
        let nivo = min(1, max(0, (db + 55) / 55))

        let sada = CFAbsoluteTimeGetCurrent()
        if sada - zadnjiNivo > 0.05 {
            zadnjiNivo = sada
            DispatchQueue.main.async { [weak self] in
                self?.naNivo?(nivo)
            }
        }
    }

    func zaustavi() -> [Float] {
        brava.lock()
        guard snimaSada else {
            brava.unlock()
            return []
        }
        snimaSada = false
        let jeSesija = sesijaAktivna
        let rezultat = uzorci
        uzorci.removeAll(keepingCapacity: jeSesija)
        if !jeSesija {
            pretvarac = nil
        }
        brava.unlock()

        if !jeSesija {
            motor.stop()
            motor.inputNode.removeTap(onBus: 0)
            motorRadi = false
            try? AVAudioSession.sharedInstance().setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
        }

        DispatchQueue.main.async { [weak self] in
            self?.naNivo?(0)
        }
        return rezultat
    }

    /// Gasenje pozadinske sesije. Ako je snimanje u toku, uzorci se odbacuju;
    /// aplikacija pre toga poziva `zaustavi()` da bi završila prepis.
    func zavrsiSesiju() {
        brava.lock()
        let jeMotorRadi = motorRadi
        sesijaAktivna = false
        snimaSada = false
        uzorci.removeAll(keepingCapacity: false)
        pretvarac = nil
        motorRadi = false
        brava.unlock()

        if jeMotorRadi {
            motor.stop()
            motor.inputNode.removeTap(onBus: 0)
            try? AVAudioSession.sharedInstance().setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
        }

        DispatchQueue.main.async { [weak self] in
            self?.naNivo?(0)
        }
    }

    func otkazi() {
        _ = zaustavi()
    }

    static func trajanje(_ brojUzoraka: Int) -> Double {
        Double(brojUzoraka) / 16_000.0
    }

    /// Skida tišinu sa početka i kraja, da whisper ne bi izmišljao tekst.
    static func skratiTisinu(_ ulaz: [Float], prag: Float = 0.012) -> [Float] {
        guard !ulaz.isEmpty else { return [] }

        var prvi: Int?
        for (i, v) in ulaz.enumerated() where abs(v) > prag {
            prvi = i
            break
        }
        guard let pocetak = prvi else { return [] }

        var kraj = pocetak
        for i in stride(from: ulaz.count - 1, through: pocetak, by: -1) where abs(ulaz[i]) > prag {
            kraj = i
            break
        }

        let pauza = Int(0.18 * 16_000)
        let od = max(0, pocetak - pauza)
        let doKraja = min(ulaz.count, kraj + pauza)
        guard doKraja > od else { return [] }
        return Array(ulaz[od..<doKraja])
    }
}

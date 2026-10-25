import Foundation

/// Preuzimanje modela sa Hugging Face-a, sa napretkom u UI-ju.
final class Preuzimac: NSObject, URLSessionDownloadDelegate {
    var naNapredak: ((Double) -> Void)?
    var naKraj: ((Result<URL, Error>) -> Void)?

    private var sesija: URLSession!
    private var odrediste: URL?
    private var ocekivanaVelicina: Int64 = 0
    private var greskaStatusa: Error?
    private var zavrseno = false

    override init() {
        super.init()
        sesija = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    func pocni(od url: URL, u odrediste: URL, velicina: Int64) {
        self.odrediste = odrediste
        self.ocekivanaVelicina = velicina
        self.greskaStatusa = nil
        self.zavrseno = false
        naNapredak?(0)
        guard url.scheme?.lowercased() == "https" else {
            zavrsi(.failure(GreskaPreuzimanja.nebezbednaAdresa))
            return
        }
        let zadatak = sesija.downloadTask(with: url)
        zadatak.resume()
    }

    func otkazi() {
        sesija.getAllTasks { zadaci in
            zadaci.forEach { $0.cancel() }
        }
    }

    private func zavrsi(_ rezultat: Result<URL, Error>) {
        guard !zavrseno else { return }
        zavrseno = true
        sesija.finishTasksAndInvalidate()
        DispatchQueue.main.async { [weak self] in self?.naKraj?(rezultat) }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let ukupno = totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : ocekivanaVelicina
        guard ukupno > 0 else { return }
        let procenat = min(1, Double(totalBytesWritten) / Double(ukupno))
        DispatchQueue.main.async { [weak self] in self?.naNapredak?(procenat) }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        guard let url = request.url, url.scheme?.lowercased() == "https" else {
            greskaStatusa = GreskaPreuzimanja.nebezbednaAdresa
            task.cancel()
            completionHandler(nil)
            return
        }
        completionHandler(request)
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        if let greska = greskaStatusa {
            greskaStatusa = nil
            zavrsi(.failure(greska))
            return
        }
        if let http = downloadTask.response as? HTTPURLResponse, http.statusCode != 200 {
            zavrsi(.failure(GreskaPreuzimanja.neispravanStatus(http.statusCode)))
            return
        }
        guard let odrediste else {
            zavrsi(.failure(GreskaPreuzimanja.neispravanFajl))
            return
        }
        do {
            try FileManager.default.createDirectory(
                at: odrediste.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if FileManager.default.fileExists(atPath: odrediste.path) {
                try FileManager.default.removeItem(at: odrediste)
            }
            try FileManager.default.moveItem(at: location, to: odrediste)

            let velicina = Putanje.velicina(odrediste)
            if ocekivanaVelicina > 0 && velicina != ocekivanaVelicina {
                try? FileManager.default.removeItem(at: odrediste)
                throw GreskaPreuzimanja.neispravanFajl
            }
            Putanje.zastitiFajl(odrediste)
            DispatchQueue.main.async { [weak self] in
                self?.naNapredak?(1)
            }
            zavrsi(.success(odrediste))
        } catch {
            zavrsi(.failure(error))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled {
            if let greska = greskaStatusa {
                greskaStatusa = nil
                zavrsi(.failure(greska))
            }
            return
        }
        zavrsi(.failure(error))
    }
}

enum GreskaPreuzimanja: LocalizedError {
    case neispravanFajl
    case neispravanStatus(Int)
    case nebezbednaAdresa

    var errorDescription: String? {
        switch self {
        case .neispravanFajl: return "Preuzeti model nije kompletan. Pokušaj ponovo."
        case .neispravanStatus(let kod): return "Server je vratio HTTP \(kod). Pokušaj ponovo."
        case .nebezbednaAdresa: return "Preuzimanje mora da ide preko https:// veze."
        }
    }
}

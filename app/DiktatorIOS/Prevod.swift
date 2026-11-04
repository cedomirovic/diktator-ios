import Foundation

/// Prevodi tekstove koji se ne prikazuju direktno kroz SwiftUI `Text`.
///
/// SwiftUI sam prevodi literale u `Text`, `Label`, `Button` i slično, ali
/// tekstovi koji se sklapaju u običan `String` (poruke, opisi modela, statusi
/// tastature) moraju kroz `NSLocalizedString`. Ključ je srpski tekst, pa
/// neprevedena stavka uvek ostaje srpska umesto prazna.
enum Prevod {
    static func t(_ tekst: String) -> String {
        NSLocalizedString(tekst, comment: "")
    }

    /// Isti prevod, ali sa vrednostima za `%@` oznake u prevodu.
    static func t(_ tekst: String, _ argumenti: CVarArg...) -> String {
        String(format: NSLocalizedString(tekst, comment: ""), arguments: argumenti)
    }
}

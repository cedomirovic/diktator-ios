import Foundation

/// Isti prevodilac kao u glavnoj aplikaciji, ali u modulu tastature.
/// Tekstovi u tastaturi se sklapaju u `String`, pa ne prolaze kroz SwiftUI
/// lokalizaciju i moraju kroz `NSLocalizedString`.
enum Prevod {
    static func t(_ tekst: String) -> String {
        NSLocalizedString(tekst, comment: "")
    }
}

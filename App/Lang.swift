import Foundation

/// The app speaks Spanish and English. Everything else falls back to English.
enum Lang {
    static let english = !(Bundle.main.preferredLocalizations.first ?? "en").hasPrefix("es")
}

/// Picks the Spanish or the English wording.
func L(_ es: String, _ en: String) -> String {
    Lang.english ? en : es
}

import NearMissCore
import SwiftUI

enum Theme {
    static let paper = Color(red: 0.98, green: 0.96, blue: 0.92)
    static let card = Color.white
    static let ink = Color(red: 0.11, green: 0.10, blue: 0.16)
    static let muted = Color(red: 0.42, green: 0.40, blue: 0.46)
    static let coral = Color(red: 0.93, green: 0.33, blue: 0.27)
    static let teal = Color(red: 0.16, green: 0.49, blue: 0.52)
    static let line = Color(red: 0.11, green: 0.10, blue: 0.16).opacity(0.10)

    static func title(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Theme.line)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(
                isEnabled ? Theme.ink : Theme.ink.opacity(0.25),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isEnabled ? Theme.ink : Theme.muted.opacity(0.6))
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(Theme.ink.opacity(configuration.isPressed ? 0.12 : 0.06), in: Capsule())
    }
}

/// Words for distances, gaps and days. The interface is in Spanish.
enum Phrase {
    static let locale = Locale(identifier: "es_MX")

    static func distance(_ meters: Double) -> String {
        if meters < 150 { return "menos de 150 m" }
        if meters < 950 {
            let rounded = Int((meters / 50).rounded() * 50)
            return "\(rounded) m"
        }
        let km = meters / 1000
        if km < 10 {
            let tenths = (km * 10).rounded() / 10
            return tenths == tenths.rounded()
                ? "\(Int(tenths)) km"
                : String(format: "%.1f km", locale: locale, tenths)
        }
        return "\(Int(km.rounded()).formatted(.number.locale(locale))) km"
    }

    static func gap(_ days: Int) -> String {
        switch days {
        case 0: return "el mismo día"
        case 1: return "1 día de diferencia"
        case ..<60: return "\(days) días de diferencia"
        case ..<730: return "\(Int((Double(days) / 30.44).rounded())) meses de diferencia"
        default: return "\(Int((Double(days) / 365.25).rounded())) años de diferencia"
        }
    }

    static func tolerance(days: Int) -> String {
        switch days {
        case 0: return "El mismo día"
        case 1: return "Hasta 1 día de diferencia"
        default: return "Hasta \(days) días de diferencia"
        }
    }

    static func date(_ day: Int) -> String {
        format(day, "d 'de' MMMM 'de' yyyy")
    }

    static func shortDate(_ day: Int) -> String {
        format(day, "d MMM yyyy")
    }

    static func monthAndYear(_ day: Int) -> String {
        format(day, "MMMM 'de' yyyy")
    }

    static func count(_ n: Int, _ singular: String, _ plural: String) -> String {
        "\(n.formatted(.number.locale(locale))) \(n == 1 ? singular : plural)"
    }

    private static func format(_ day: Int, _ pattern: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = pattern
        return formatter.string(from: SolarDay.date(for: day))
    }
}

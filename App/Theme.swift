import NearMissCore
import SwiftUI

/// Night map: dark ground, two trails that glow.
enum Theme {
    static let bg = Color(red: 0.047, green: 0.043, blue: 0.075)
    static let surface = Color(red: 0.094, green: 0.086, blue: 0.137)
    static let raised = Color(red: 0.141, green: 0.129, blue: 0.2)
    static let text = Color(red: 0.965, green: 0.945, blue: 0.906)
    static let muted = Color(red: 0.63, green: 0.61, blue: 0.71)
    static let coral = Color(red: 1.0, green: 0.42, blue: 0.36)
    static let teal = Color(red: 0.21, green: 0.82, blue: 0.75)
    static let line = Color.white.opacity(0.09)

    static func title(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }

    static let label = Font.caption2.weight(.bold)
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Theme.line)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? Theme.bg : Theme.muted.opacity(0.7))
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                isEnabled ? AnyShapeStyle(Theme.coral) : AnyShapeStyle(Color.white.opacity(0.07)),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .shadow(color: isEnabled ? Theme.coral.opacity(0.35) : .clear, radius: 18, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isEnabled ? Theme.text : Theme.muted.opacity(0.5))
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(Color.white.opacity(configuration.isPressed ? 0.16 : 0.09), in: Capsule())
            .overlay(Capsule().strokeBorder(Theme.line))
    }
}

/// A point of light on the map or in a legend.
struct GlowDot: View {
    let color: Color
    var size: CGFloat = 8

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .shadow(color: color.opacity(0.9), radius: size * 0.7)
    }
}

/// Words for distances, gaps and days, in Spanish or English.
enum Phrase {
    static let locale = Locale(identifier: Lang.english ? "en_US" : "es_MX")

    static func distance(_ meters: Double) -> String {
        if meters < 150 { return L("menos de 150 m", "less than 150 m") }
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
        case 0: return L("el mismo día", "the same day")
        case 1: return L("1 día de diferencia", "1 day apart")
        case ..<60: return L("\(days) días de diferencia", "\(days) days apart")
        case ..<730:
            let months = Int((Double(days) / 30.44).rounded())
            return L("\(months) meses de diferencia", "\(months) months apart")
        default:
            let years = Int((Double(days) / 365.25).rounded())
            return L("\(years) años de diferencia", "\(years) years apart")
        }
    }

    static func tolerance(days: Int) -> String {
        switch days {
        case 0: return L("El mismo día", "The same day")
        case 1: return L("Hasta 1 día de diferencia", "Up to 1 day apart")
        default: return L("Hasta \(days) días de diferencia", "Up to \(days) days apart")
        }
    }

    static func date(_ day: Int) -> String {
        format(day, L("d 'de' MMMM 'de' yyyy", "MMMM d, yyyy"))
    }

    static func shortDate(_ day: Int) -> String {
        format(day, L("d MMM yyyy", "MMM d, yyyy"))
    }

    static func monthAndYear(_ day: Int) -> String {
        format(day, L("MMMM 'de' yyyy", "MMMM yyyy"))
    }

    static func count(_ n: Int, _ singular: String, _ plural: String) -> String {
        "\(n.formatted(.number.locale(locale))) \(n == 1 ? singular : plural)"
    }

    /// "1,204 places and days": how big a trail is.
    static func places(_ n: Int) -> String {
        count(n, L("lugar y día", "place and day"), L("lugares y días", "places and days"))
    }

    private static func format(_ day: Int, _ pattern: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = pattern
        return formatter.string(from: SolarDay.date(for: day))
    }
}

extension String {
    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}

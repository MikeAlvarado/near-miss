import NearMissCore
import SwiftUI

struct ResultsView: View {
    @Environment(AppModel.self) private var model

    static let distances: [Double] = [100, 250, 500, 1000, 2000, 5000]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let comparison = model.comparison {
                    headline(comparison)
                    toleranceCard

                    if comparison.matches.isEmpty {
                        if let closest = comparison.closest {
                            ClosestCard(miss: closest, partner: model.partnerName)
                        }
                    } else {
                        ForEach(comparison.matches) { miss in
                            MissCard(
                                miss: miss,
                                partner: model.partnerName,
                                isClosest: miss == comparison.closest && comparison.matches.count > 1
                            )
                        }
                    }

                    Text("Solo hay datos donde alguno de los dos tomó una foto con ubicación. Las distancias se miden entre cuadros del mapa de unos 150 m, así que son aproximadas.")
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                        .padding(.top, 4)
                } else {
                    ProgressView("Comparando…")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .background(Theme.paper.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.recompute() }
    }

    @ViewBuilder
    private func headline(_ comparison: Comparison) -> some View {
        let count = comparison.matches.count
        VStack(alignment: .leading, spacing: 8) {
            if count > 0 {
                Text("Casi se conocen")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Theme.muted)
                Text(count == 1 ? "1 vez" : "\(count) veces")
                    .font(Theme.title(56))
                    .foregroundStyle(Theme.coral)
                    .contentTransition(.numericText())
            } else if let closest = comparison.closest {
                Text("Nunca se cruzaron.")
                    .font(Theme.title(40))
                    .foregroundStyle(Theme.ink)
                Text(closest.meters <= 10_000 && closest.dayGap <= 30
                    ? "Pero una vez estuvieron cerca."
                    : "Esto es lo más cerca que llegaron.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Theme.muted)
            } else {
                Text("No hay con qué comparar.")
                    .font(Theme.title(34))
                    .foregroundStyle(Theme.ink)
                Text("Alguno de los dos rastros no tiene lugares en ese periodo. Prueba quitando la fecha en que se conocieron.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
            }
        }
        .animation(.snappy, value: count)
        .padding(.bottom, 4)
    }

    private var toleranceCard: some View {
        @Bindable var model = model
        let index = Self.distances.firstIndex(of: model.tolerance.meters) ?? 2

        return Card {
            VStack(alignment: .leading, spacing: 14) {
                Text("¿Qué cuenta como “casi”?")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)

                VStack(alignment: .leading, spacing: 4) {
                    Text("A menos de \(Phrase.distance(model.tolerance.meters))")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.ink)
                    Slider(
                        value: Binding(
                            get: { Double(index) },
                            set: { model.tolerance.meters = Self.distances[Int($0.rounded())] }
                        ),
                        in: 0...Double(Self.distances.count - 1),
                        step: 1
                    )
                    .accessibilityLabel("Distancia máxima")
                    .accessibilityValue(Phrase.distance(model.tolerance.meters))
                }

                Stepper(value: $model.tolerance.days, in: 0...7) {
                    Text(Phrase.tolerance(days: model.tolerance.days))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.ink)
                }

                Divider()

                Toggle(isOn: $model.onlyBeforeMeeting) {
                    Text("Solo antes de conocernos")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.ink)
                }
                if model.onlyBeforeMeeting {
                    DatePicker(
                        "Nos conocimos el",
                        selection: $model.metDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .font(.subheadline)
                    .environment(\.locale, Phrase.locale)
                }
            }
        }
    }
}

/// One near miss within the tolerance.
struct MissCard: View {
    let miss: NearMiss
    let partner: String
    let isClosest: Bool

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                if isClosest {
                    Text("LA MÁS CERCANA")
                        .font(.caption2.weight(.bold))
                        .kerning(0.8)
                        .foregroundStyle(Theme.coral)
                }
                Text(Phrase.date(miss.mine.day).capitalizedFirst)
                    .font(.system(.title3, design: .serif).weight(.bold))
                    .foregroundStyle(Theme.ink)

                GapLine(meters: miss.meters)

                Text(sentence)
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)

                MapsLink(miss: miss)
            }
        }
    }

    private var sentence: String {
        let distance = miss.meters < 150
            ? "Estuvieron a \(Phrase.distance(miss.meters))"
            : "Estuvieron a unos \(Phrase.distance(miss.meters))"
        if miss.dayGap == 0 { return "\(distance), el mismo día." }
        return "\(distance). Tú, el \(Phrase.shortDate(miss.mine.day)); \(partner), el \(Phrase.shortDate(miss.theirs.day))."
    }
}

/// Shown when nothing is within the tolerance: the closest the two ever were.
struct ClosestCard: View {
    let miss: NearMiss
    let partner: String

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("LO MÁS CERCA QUE ESTUVIERON")
                    .font(.caption2.weight(.bold))
                    .kerning(0.8)
                    .foregroundStyle(Theme.coral)

                Text(summary)
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                GapLine(meters: miss.meters)

                Text("Tú, el \(Phrase.shortDate(miss.mine.day)); \(partner), el \(Phrase.shortDate(miss.theirs.day)).\(hint)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)

                MapsLink(miss: miss)
            }
        }
    }

    /// Only offered when the sliders can actually reach this one.
    private var hint: String {
        let reachable = miss.meters <= (ResultsView.distances.last ?? 0) && miss.dayGap <= 7
        return reachable ? " Sube la distancia o los días de arriba y cuenta como “casi”." : ""
    }

    private var summary: String {
        let distance = Phrase.distance(miss.meters)
        let when = Phrase.monthAndYear(miss.mine.day)
        if miss.dayGap == 0 { return "\(distance.capitalizedFirst), el mismo día, en \(when)." }
        return "\(distance.capitalizedFirst) y \(Phrase.gap(miss.dayGap)), en \(when)."
    }
}

/// Two dots and the gap between them. The gap grows with the distance, on a log scale.
struct GapLine: View {
    let meters: Double

    var body: some View {
        GeometryReader { proxy in
            let fraction = min(1, max(0.12, log10(max(meters, 30) / 30) / log10(10_000 / 30)))
            let gap = (proxy.size.width - 150) * fraction
            HStack(spacing: 0) {
                Circle().fill(Theme.coral).frame(width: 18, height: 18)
                Rectangle().fill(Theme.line).frame(width: gap, height: 2)
                Circle().fill(Theme.teal).frame(width: 18, height: 18)
                Text(Phrase.distance(meters))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                    .fixedSize()
                    .padding(.leading, 10)
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 24)
        .accessibilityHidden(true)
    }
}

/// Opens Apple Maps at the midpoint. This is the only thing that leaves the app,
/// and only when the person taps it.
struct MapsLink: View {
    let miss: NearMiss

    var body: some View {
        if let url {
            Link(destination: url) {
                Label("Abrir en Mapas", systemImage: "map")
                    .font(.subheadline.weight(.semibold))
            }
            .tint(Theme.teal)
        }
    }

    private var url: URL? {
        guard let a = Geohash.center(of: miss.mine.cell),
              let b = Geohash.center(of: miss.theirs.cell)
        else { return nil }
        let latitude = (a.latitude + b.latitude) / 2
        let longitude = (a.longitude + b.longitude) / 2
        return URL(string: String(format: "https://maps.apple.com/?ll=%.4f,%.4f&z=15", latitude, longitude))
    }
}

extension String {
    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}

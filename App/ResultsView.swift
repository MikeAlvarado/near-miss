import MapKit
import NearMissCore
import SwiftUI

/// The result is a map. Both trails are painted on it in the order they happened,
/// then the camera flies to the place where the two almost met.
struct ResultsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var scene: MapScene?
    /// Sightings after this day are not drawn yet. `Int.max` shows everything.
    @State private var revealDay = Int.max
    @State private var isReplaying = false
    @State private var selection: String? = ResultsView.overviewID
    @State private var camera: MapCameraPosition = .automatic
    @State private var showingTuning = false
    @State private var replayCount = 0
    /// How far the two have walked toward the selected near miss, 0 to 1.
    @State private var walk = 1.0
    @State private var walkPaths: (mine: [CLLocationCoordinate2D], theirs: [CLLocationCoordinate2D])?
    @State private var walkTask: Task<Void, Never>?

    static let overviewID = "overview"
    static let distances: [Double] = [100, 250, 500, 1000, 2000, 5000]

    var body: some View {
        Map(position: $camera, interactionModes: [.pan, .zoom]) {
            mapContent
        }
        .mapStyle(.standard(elevation: .realistic, emphasis: .muted, pointsOfInterest: .excludingAll))
        .mapControlVisibility(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) { carousel }
        .overlay(alignment: .top) { topPill.padding(.top, 8) }
        .background(Theme.bg)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    replayCount += 1
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .accessibilityLabel("Volver a pintar el mapa")
                .disabled(isReplaying)

                Button {
                    showingTuning = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Ajustar qué cuenta como casi")
            }
        }
        .sheet(isPresented: $showingTuning) {
            TuningSheet()
                .presentationDetents([.height(400)])
                .presentationBackground(Theme.surface)
                .presentationDragIndicator(.visible)
        }
        .onAppear { model.recompute() }
        .task(id: sceneKey) { await buildAndReplay() }
        .onChange(of: selection) { focus(animated: true) }
        .onChange(of: model.comparison) {
            // The tolerance moved: the card that was selected may be gone.
            if let selection, selection != Self.overviewID, !cards.contains(where: { $0.id == selection }) {
                self.selection = Self.overviewID
            }
        }
    }

    // MARK: - Map

    @MapContentBuilder
    private var mapContent: some MapContent {
        if let scene {
            trailLine(scene.mine, color: Theme.coral)
            trailLine(scene.theirs, color: Theme.teal)

            ForEach(scene.mineDots.filter { $0.day <= revealDay }) { point in
                Annotation("", coordinate: point.coordinate, anchor: .center) {
                    GlowDot(color: Theme.coral)
                }
            }
            ForEach(scene.theirsDots.filter { $0.day <= revealDay }) { point in
                Annotation("", coordinate: point.coordinate, anchor: .center) {
                    GlowDot(color: Theme.teal)
                }
            }

            if !isReplaying {
                ForEach(cards) { miss in
                    missMarker(miss)
                }
            }
        }
    }

    @MapContentBuilder
    private func trailLine(_ points: [TrailPoint], color: Color) -> some MapContent {
        let coordinates = points.filter { $0.day <= revealDay }.map(\.coordinate)
        if coordinates.count >= 2 {
            MapPolyline(coordinates: coordinates, contourStyle: .geodesic)
                .stroke(color.opacity(0.22), style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
            MapPolyline(coordinates: coordinates, contourStyle: .geodesic)
                .stroke(color.opacity(0.95), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        }
    }

    @MapContentBuilder
    private func missMarker(_ miss: NearMiss) -> some MapContent {
        if let (a, b) = MapScene.endpoints(of: miss) {
            let isSelected = selection == miss.id
            let middle = MapScene.midpoint(a, b)

            if isSelected {
                let arrived = walk >= 1
                let minePath = walkPaths.map { MapScene.walked($0.mine, progress: walk) } ?? [a]
                let theirsPath = walkPaths.map { MapScene.walked($0.theirs, progress: walk) } ?? [b]

                steps(minePath, color: Theme.coral)
                steps(theirsPath, color: Theme.teal)

                if arrived {
                    MapCircle(center: middle, radius: max(miss.meters / 2 + 45, 75))
                        .foregroundStyle(.white.opacity(0.07))
                        .stroke(.white.opacity(0.45), lineWidth: 1)
                    MapPolyline(coordinates: [a, b])
                        .stroke(.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [3, 7]))
                    if miss.meters >= 150 {
                        Annotation("", coordinate: middle, anchor: .center) {
                            Text(Phrase.distance(miss.meters))
                                .font(.caption.weight(.bold))
                                .monospacedDigit()
                                .foregroundStyle(Theme.bg)
                                .padding(.horizontal, 9)
                                .frame(height: 22)
                                .background(.white, in: Capsule())
                                .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
                        }
                    }
                }
                Annotation("Tú", coordinate: minePath.last ?? a, anchor: .center) {
                    Walker(color: Theme.coral, arrived: arrived, flipped: false, phase: walk)
                }
                Annotation(model.partnerName.capitalizedFirst, coordinate: theirsPath.last ?? b, anchor: .center) {
                    Walker(color: Theme.teal, arrived: arrived, flipped: true, phase: walk)
                }
            } else {
                Annotation("", coordinate: middle, anchor: .center) {
                    Button {
                        withAnimation(.snappy) { selection = miss.id }
                    } label: {
                        PulseMarker()
                    }
                    .accessibilityLabel("Ver el casi del \(Phrase.date(miss.mine.day))")
                }
            }
        }
    }

    /// Footsteps: a soft glow with a line of round dots on top.
    @MapContentBuilder
    private func steps(_ path: [CLLocationCoordinate2D], color: Color) -> some MapContent {
        if path.count >= 2 {
            MapPolyline(coordinates: path)
                .stroke(color.opacity(0.25), style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
            MapPolyline(coordinates: path)
                .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round, dash: [0.1, 3.2]))
        }
    }

    // MARK: - Chrome over the map

    @ViewBuilder
    private var topPill: some View {
        if isReplaying, revealDay != Int.max {
            Text(Phrase.monthAndYear(revealDay).capitalizedFirst)
                .font(.system(.subheadline, design: .serif).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(Theme.text)
                .contentTransition(.numericText())
                .pill()
        } else {
            HStack(spacing: 14) {
                HStack(spacing: 7) {
                    GlowDot(color: Theme.coral)
                    Text("Tú")
                }
                HStack(spacing: 7) {
                    GlowDot(color: Theme.teal)
                    Text(model.partnerName.capitalizedFirst)
                }
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Theme.text)
            .pill()
        }
    }

    private var carousel: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 12) {
                OverviewCard(
                    comparison: model.comparison,
                    partner: model.partnerName,
                    isReplaying: isReplaying,
                    tune: { showingTuning = true }
                )
                .cardFrame()
                .id(Self.overviewID)

                // The answer waits until the map is painted.
                ForEach(Array((isReplaying ? [] : cards).enumerated()), id: \.element.id) { index, miss in
                    MissCard(
                        miss: miss,
                        partner: model.partnerName,
                        label: label(for: miss, at: index)
                    )
                    .cardFrame()
                    .id(miss.id)
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $selection)
        .scrollIndicators(.hidden)
        .frame(height: 214)
        .padding(.top, 28)
        .padding(.bottom, 6)
        .background(
            LinearGradient(
                colors: [Theme.bg.opacity(0), Theme.bg.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
        )
    }

    // MARK: - Data

    /// The near misses within the tolerance, or the single closest one when there are none.
    private var cards: [NearMiss] {
        guard let comparison = model.comparison else { return [] }
        if !comparison.matches.isEmpty { return comparison.matches }
        return comparison.closest.map { [$0] } ?? []
    }

    private func label(for miss: NearMiss, at index: Int) -> String {
        guard let comparison = model.comparison else { return "" }
        if comparison.matches.isEmpty { return "LO MÁS CERCA QUE ESTUVIERON" }
        if comparison.matches.count == 1 { return "EL CASI" }
        let position = "CASI \(index + 1) DE \(comparison.matches.count)"
        return miss == comparison.closest ? "\(position) · EL MÁS CERCANO" : position
    }

    private var sceneKey: String {
        let before = model.beforeDay.map(String.init) ?? "-"
        return [
            model.demo?.rawValue ?? "real",
            String(model.myTrail?.sightings.count ?? 0),
            String(model.partnerTrail?.sightings.count ?? 0),
            before,
            String(replayCount),
        ].joined(separator: "|")
    }

    // MARK: - Motion

    private func buildAndReplay() async {
        guard let mine = model.myTrail, let theirs = model.partnerTrail else { return }
        let built = MapScene(mine: mine, theirs: theirs, beforeDay: model.beforeDay)
        scene = built
        selection = Self.overviewID
        camera = .region(built.region)

        guard !reduceMotion, built.days.count > 1 else {
            revealDay = .max
            isReplaying = false
            return
        }

        // Paint the trails in the order they happened.
        isReplaying = true
        revealDay = built.days[0] - 1
        try? await Task.sleep(for: .milliseconds(700))
        let frames = min(built.days.count, 110)
        let pause = max(28, min(170, 3600 / frames))
        for frame in 1...frames {
            if Task.isCancelled { return }
            let index = (built.days.count - 1) * frame / frames
            withAnimation(.linear(duration: Double(pause) / 1000)) {
                revealDay = built.days[index]
            }
            try? await Task.sleep(for: .milliseconds(pause))
        }
        if Task.isCancelled { return }
        withAnimation(.easeOut(duration: 0.4)) {
            revealDay = .max
            isReplaying = false
        }

        // Then go to the moment that matters.
        try? await Task.sleep(for: .milliseconds(900))
        if Task.isCancelled { return }
        if selection == Self.overviewID, let closest = model.comparison?.closest {
            withAnimation(.snappy) { selection = closest.id }
        }
    }

    private func focus(animated: Bool) {
        guard let scene else { return }
        let target: MapCameraPosition
        let miss = cards.first(where: { $0.id == selection })
        if let miss, let street = MapScene.camera(for: miss) {
            target = street
        } else {
            target = .region(scene.region)
        }
        startWalk(toward: miss)
        if animated, !reduceMotion {
            withAnimation(.easeInOut(duration: 1.8)) { camera = target }
        } else {
            camera = target
        }
    }
}

private extension ResultsView {
    /// The two walk their last steps once the camera has come down to the street.
    func startWalk(toward miss: NearMiss?) {
        walkTask?.cancel()
        guard let miss, miss.meters <= 4000, !reduceMotion, let paths = MapScene.walkPaths(for: miss) else {
            walkPaths = nil
            walk = 1
            return
        }
        walkPaths = paths
        walk = 0
        walkTask = Task {
            try? await Task.sleep(for: .milliseconds(1500))
            let frames = 110
            for frame in 1..<frames {
                if Task.isCancelled { return }
                let t = Double(frame) / Double(frames)
                // Ease out: they slow down as they arrive.
                walk = min(0.999, 1 - (1 - t) * (1 - t))
                try? await Task.sleep(for: .milliseconds(33))
            }
            if Task.isCancelled { return }
            withAnimation(.easeOut(duration: 0.5)) { walk = 1 }
        }
    }
}

// MARK: - Cards

/// The first card: the answer in one line.
struct OverviewCard: View {
    let comparison: Comparison?
    let partner: String
    let isReplaying: Bool
    var tune: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if isReplaying {
                Text("PINTANDO EL MAPA")
                    .font(Theme.label)
                    .kerning(1.4)
                    .foregroundStyle(Theme.muted)
                Text("Por dónde anduvo cada quien…")
                    .font(Theme.title(26))
                    .foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                HStack(spacing: 14) {
                    HStack(spacing: 7) { GlowDot(color: Theme.coral); Text("Tú") }
                    HStack(spacing: 7) { GlowDot(color: Theme.teal); Text(partner.capitalizedFirst) }
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.muted)
            } else if let comparison {
                let count = comparison.matches.count
                if count > 0 {
                    Text("CASI SE CONOCEN")
                        .font(Theme.label)
                        .kerning(1.4)
                        .foregroundStyle(Theme.muted)
                    Text(count == 1 ? "1 vez" : "\(count) veces")
                        .font(Theme.title(52))
                        .foregroundStyle(Theme.coral)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: count)
                    Spacer(minLength: 0)
                    footer(hint: "Desliza para verlas")
                } else if let closest = comparison.closest {
                    Text("NUNCA SE CRUZARON")
                        .font(Theme.label)
                        .kerning(1.4)
                        .foregroundStyle(Theme.muted)
                    Text(closest.meters <= 10_000 && closest.dayGap <= 30
                        ? "Pero una vez estuvieron cerca."
                        : "Esto es lo más cerca que llegaron.")
                        .font(Theme.title(26))
                        .foregroundStyle(Theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    footer(hint: "Desliza para verlo")
                } else {
                    Text("SIN DATOS")
                        .font(Theme.label)
                        .kerning(1.4)
                        .foregroundStyle(Theme.muted)
                    Text("No hay con qué comparar.")
                        .font(Theme.title(26))
                        .foregroundStyle(Theme.text)
                    Text("Alguno de los dos rastros no tiene lugares en ese periodo. Prueba quitando la fecha en que se conocieron.")
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                    Spacer(minLength: 0)
                }
            } else {
                ProgressView("Comparando…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func footer(hint: String) -> some View {
        HStack {
            Button(action: tune) {
                Label("Ajustar", systemImage: "slider.horizontal.3")
            }
            .buttonStyle(SecondaryButtonStyle())
            Spacer()
            Label(hint, systemImage: "arrow.right")
                .labelStyle(TrailingIconLabelStyle())
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.muted)
        }
    }
}

/// One near miss: when, how far, and who was where.
struct MissCard: View {
    let miss: NearMiss
    let partner: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(Theme.label)
                .kerning(1.2)
                .foregroundStyle(Theme.coral)

            Text(Phrase.date(miss.mine.day).capitalizedFirst)
                .font(Theme.title(24))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(miss.meters < 150 ? "< 150 m" : Phrase.distance(miss.meters))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                    .fixedSize()
                Text(miss.dayGap == 0 ? "el mismo día" : "y \(Phrase.gap(miss.dayGap))")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Text(detail)
                .font(.footnote)
                .foregroundStyle(Theme.muted)
                .lineLimit(2)

            Spacer(minLength: 0)

            if let url = mapsURL {
                Link(destination: url) {
                    Label("Abrir en Mapas", systemImage: "map")
                        .font(.footnote.weight(.semibold))
                }
                .tint(Theme.teal)
            }
        }
    }

    private var detail: String {
        if miss.dayGap == 0 {
            if miss.meters < 150 {
                return "Tú y \(partner) en la misma cuadra, sin saberlo."
            }
            if miss.meters <= 1500 {
                let minutes = max(1, Int((miss.meters / 80).rounded()))
                return "Tú y \(partner), a unos \(minutes) min a pie, sin saberlo."
            }
            return "Tú y \(partner) en la misma zona, sin saberlo."
        }
        return "Tú, el \(Phrase.shortDate(miss.mine.day)); \(partner), el \(Phrase.shortDate(miss.theirs.day))."
    }

    /// Opens Apple Maps at the midpoint. It leaves the app only when tapped.
    private var mapsURL: URL? {
        guard let (a, b) = MapScene.endpoints(of: miss) else { return nil }
        let middle = MapScene.midpoint(a, b)
        return URL(string: String(format: "https://maps.apple.com/?ll=%.4f,%.4f&z=17", middle.latitude, middle.longitude))
    }
}

/// Distance, days and the date the two met.
struct TuningSheet: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        let index = ResultsView.distances.firstIndex(of: model.tolerance.meters) ?? 2

        VStack(alignment: .leading, spacing: 18) {
            Text("¿Qué cuenta como “casi”?")
                .font(Theme.title(24))
                .foregroundStyle(Theme.text)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 4) {
                Text("A menos de \(Phrase.distance(model.tolerance.meters))")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.text)
                Slider(
                    value: Binding(
                        get: { Double(index) },
                        set: { model.tolerance.meters = ResultsView.distances[Int($0.rounded())] }
                    ),
                    in: 0...Double(ResultsView.distances.count - 1),
                    step: 1
                )
                .accessibilityLabel("Distancia máxima")
                .accessibilityValue(Phrase.distance(model.tolerance.meters))
            }

            Stepper(value: $model.tolerance.days, in: 0...7) {
                Text(Phrase.tolerance(days: model.tolerance.days))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.text)
            }

            Divider().overlay(Theme.line)

            Toggle(isOn: $model.onlyBeforeMeeting) {
                Text("Solo antes de conocernos")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.text)
            }
            .tint(Theme.coral)

            if model.onlyBeforeMeeting {
                DatePicker(
                    "Nos conocimos el",
                    selection: $model.metDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .font(.subheadline)
                .foregroundStyle(Theme.text)
                .environment(\.locale, Phrase.locale)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
}

// MARK: - Small pieces

/// Where one of the two stood, in the selected near miss.
struct EndpointDot: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 16, height: 16)
            .overlay(Circle().strokeBorder(.white, lineWidth: 2.5))
            .shadow(color: color, radius: 10)
    }
}

/// One of the two, walking toward the near miss and then standing there.
struct Walker: View {
    let color: Color
    let arrived: Bool
    let flipped: Bool
    let phase: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 30, height: 30)
                .overlay(Circle().strokeBorder(.white, lineWidth: 2.5))
                .shadow(color: color, radius: 12)
            Image(systemName: arrived ? "figure.stand" : "figure.walk")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.bg)
                .scaleEffect(x: flipped ? -1 : 1)
        }
        // A small bounce on every step.
        .offset(y: arrived ? 0 : -abs(sin(phase * .pi * 16)) * 3)
        .accessibilityHidden(true)
    }
}

/// A near miss that is not selected: a ring that breathes.
struct PulseMarker: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(.white.opacity(0.7), lineWidth: 1.5)
                .frame(width: 30, height: 30)
                .scaleEffect(pulsing ? 1.5 : 0.7)
                .opacity(pulsing ? 0 : 0.9)
            Circle()
                .fill(.white)
                .frame(width: 10, height: 10)
                .shadow(color: .white, radius: 6)
        }
        .frame(width: 44, height: 44)
        .contentShape(Circle())
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
                pulsing = true
            }
        }
    }
}

struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 5) {
            configuration.title
            configuration.icon
        }
    }
}

private extension View {
    /// A card in the carousel: glass over the map, almost as wide as the screen.
    func cardFrame() -> some View {
        self
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .background(Theme.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12))
            )
            .containerRelativeFrame(.horizontal) { length, _ in length - 28 }
    }

    func pill() -> some View {
        self
            .padding(.horizontal, 16)
            .frame(height: 34)
            .fixedSize()
            .background(.ultraThinMaterial, in: Capsule())
            .background(Theme.surface.opacity(0.6), in: Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.12)))
    }
}

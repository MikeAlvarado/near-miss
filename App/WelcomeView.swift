import SwiftUI

struct WelcomeView: View {
    var start: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bg.ignoresSafeArea()

            HeroCanvas()
                .ignoresSafeArea()
                .frame(maxHeight: .infinity, alignment: .top)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0),
                            .init(color: .black, location: 0.42),
                            .init(color: .clear, location: 0.6),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )

            VStack(alignment: .leading, spacing: 0) {
                Text(L("ANTES DE CONOCERSE", "BEFORE YOU MET"))
                    .font(Theme.label)
                    .kerning(1.6)
                    .foregroundStyle(Theme.coral)
                    .padding(.bottom, 12)

                Text(verbatim: "You almost\nmet.")
                    .font(Theme.title(54))
                    .foregroundStyle(Theme.text)

                Text(L("Quizá ya estuvieron en la misma calle el mismo día. Tus fotos y las de tu pareja lo saben; esta app lo pinta en el mapa.", "Maybe you were already on the same street on the same day. Your photos and your partner's know; this app paints it on the map."))
                    .font(.body)
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 14)
                    .padding(.bottom, 28)

                Button(L("Empezar", "Start"), action: start)
                    .buttonStyle(PrimaryButtonStyle())

                Label(L("Tus fotos no salen de tu iPhone.", "Your photos never leave your iPhone."), systemImage: "lock.fill")
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 14)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 16)
        }
    }
}

/// Two trails of light cross a dark map and pass a few steps from each other.
struct HeroCanvas: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let cycle = 8.0

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let seconds = timeline.date.timeIntervalSinceReferenceDate
                let t = reduceMotion ? 0.7 : seconds.truncatingRemainder(dividingBy: cycle) / cycle
                draw(&context, size: size, t: t)
            }
        }
        .accessibilityHidden(true)
    }

    private func draw(_ context: inout GraphicsContext, size: CGSize, t: Double) {
        let w = size.width
        let h = size.height * 0.5

        // Street grid, like a city seen from far above.
        var grid = Path()
        let step: CGFloat = 26
        var x: CGFloat = step / 2
        while x < w {
            var y: CGFloat = step / 2
            while y < size.height {
                grid.addEllipse(in: CGRect(x: x - 1, y: y - 1, width: 2, height: 2))
                y += step
            }
            x += step
        }
        context.fill(grid, with: .color(.white.opacity(0.07)))

        // Coral comes from the lower left, teal from the upper right.
        var coral = Path()
        coral.move(to: CGPoint(x: -0.08 * w, y: 0.86 * h))
        coral.addCurve(
            to: CGPoint(x: 0.5 * w, y: 0.6 * h),
            control1: CGPoint(x: 0.16 * w, y: 1.02 * h),
            control2: CGPoint(x: 0.3 * w, y: 0.6 * h)
        )
        coral.addCurve(
            to: CGPoint(x: 1.08 * w, y: 0.98 * h),
            control1: CGPoint(x: 0.72 * w, y: 0.6 * h),
            control2: CGPoint(x: 0.84 * w, y: 0.74 * h)
        )

        var teal = Path()
        teal.move(to: CGPoint(x: 1.08 * w, y: 0.2 * h))
        teal.addCurve(
            to: CGPoint(x: 0.5 * w, y: 0.5 * h),
            control1: CGPoint(x: 0.82 * w, y: 0.12 * h),
            control2: CGPoint(x: 0.7 * w, y: 0.5 * h)
        )
        teal.addCurve(
            to: CGPoint(x: -0.08 * w, y: 0.34 * h),
            control1: CGPoint(x: 0.3 * w, y: 0.5 * h),
            control2: CGPoint(x: 0.14 * w, y: 0.22 * h)
        )

        let drawn = ease(min(1, t / 0.6))
        let fade = t > 0.9 ? max(0, 1 - (t - 0.9) / 0.1) : 1

        stroke(&context, path: coral, progress: drawn, color: Theme.coral, fade: fade)
        stroke(&context, path: teal, progress: drawn, color: Theme.teal, fade: fade)

        // The near miss: rings where the two trails pass each other.
        let meet = CGPoint(x: 0.5 * w, y: 0.55 * h)
        let passed = (t - 0.33) / 0.5
        if passed > 0, passed < 1 {
            for offset in [0.0, 0.35] {
                let ring = passed - offset
                guard ring > 0, ring < 0.65 else { continue }
                let life = ring / 0.65
                let radius = 10 + 46 * life
                let circle = Path(ellipseIn: CGRect(
                    x: meet.x - radius, y: meet.y - radius, width: radius * 2, height: radius * 2
                ))
                context.stroke(circle, with: .color(.white.opacity(0.5 * (1 - life) * fade)), lineWidth: 1.5)
            }
        }
    }

    private func stroke(
        _ context: inout GraphicsContext,
        path: Path,
        progress: Double,
        color: Color,
        fade: Double
    ) {
        guard progress > 0.001 else { return }
        let trimmed = path.trimmedPath(from: 0, to: progress)
        let style = StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)

        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 10))
            layer.stroke(
                trimmed,
                with: .color(color.opacity(0.7 * fade)),
                style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round)
            )
        }
        context.stroke(trimmed, with: .color(color.opacity(fade)), style: style)

        if let head = trimmed.currentPoint {
            let dot = Path(ellipseIn: CGRect(x: head.x - 6, y: head.y - 6, width: 12, height: 12))
            context.drawLayer { layer in
                layer.addFilter(.blur(radius: 8))
                layer.fill(
                    Path(ellipseIn: CGRect(x: head.x - 11, y: head.y - 11, width: 22, height: 22)),
                    with: .color(color.opacity(0.8 * fade))
                )
            }
            context.fill(dot, with: .color(.white.opacity(fade)))
        }
    }

    private func ease(_ x: Double) -> Double {
        x * x * (3 - 2 * x)
    }
}

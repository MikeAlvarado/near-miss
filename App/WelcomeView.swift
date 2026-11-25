import SwiftUI

struct WelcomeView: View {
    var start: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 24)

            PassingDots()
                .frame(height: 150)
                .padding(.bottom, 36)

            Text("¿Casi se\nconocen?")
                .font(Theme.title(52))
                .foregroundStyle(Theme.ink)
                .lineSpacing(-4)

            Text("Antes de conocerse, quizá ya estuvieron en el mismo lugar el mismo día. Tus fotos y las de tu pareja lo saben.")
                .font(.title3)
                .foregroundStyle(Theme.muted)
                .padding(.top, 16)

            Spacer(minLength: 24)

            Button("Empezar", action: start)
                .buttonStyle(PrimaryButtonStyle())

            Label("Todo pasa en tu iPhone. Sin cuentas, sin servidor.", systemImage: "lock.fill")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 20)
        .background(Theme.paper.ignoresSafeArea())
    }
}

/// Two dots that walk past each other and never touch.
struct PassingDots: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var passed = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let middle = proxy.size.height / 2
            let travel = width - 56

            ZStack(alignment: .topLeading) {
                trail(y: middle - 22, color: Theme.coral)
                trail(y: middle + 22, color: Theme.teal)

                Circle()
                    .fill(Theme.coral)
                    .frame(width: 40, height: 40)
                    .offset(x: 8 + (passed ? travel : 0), y: middle - 42)

                Circle()
                    .fill(Theme.teal)
                    .frame(width: 40, height: 40)
                    .offset(x: 8 + (passed ? 0 : travel), y: middle + 2)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                passed = true
            }
        }
        .accessibilityHidden(true)
    }

    private func trail(y: CGFloat, color: Color) -> some View {
        GeometryReader { proxy in
            Path { path in
                path.move(to: CGPoint(x: 8, y: y))
                path.addLine(to: CGPoint(x: proxy.size.width - 8, y: y))
            }
            .stroke(color.opacity(0.35), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 9]))
        }
    }
}

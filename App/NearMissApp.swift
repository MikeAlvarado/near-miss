import SwiftUI

@main
struct NearMissApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .preferredColorScheme(.dark)
                .tint(Theme.coral)
        }
    }
}

enum Route: Hashable {
    case setup
    case results
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView { path = [.setup] }
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .setup:
                        SetupView { path.append(.results) }
                    case .results:
                        ResultsView()
                    }
                }
        }
        // A trail file opened from AirDrop, Messages or Files lands here.
        .onOpenURL { url in
            model.importPartner(from: url)
            path = [.setup]
        }
    }
}

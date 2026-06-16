import SwiftUI

@main
struct AshVaultApp: App {
    @StateObject private var engine = GameEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(engine)
        }
    }
}

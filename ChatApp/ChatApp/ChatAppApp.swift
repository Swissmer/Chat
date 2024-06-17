import SwiftUI

@main
struct ChatAppApp: App {
    var body: some Scene {
        WindowGroup {
            MainScreenView()
                .preferredColorScheme(.light)
        }
    }
}

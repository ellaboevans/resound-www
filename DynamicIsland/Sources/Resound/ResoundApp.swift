import SwiftUI

@main
struct ResoundApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
                .frame(width: 0, height: 0)
                .hidden()
        }
    }
}

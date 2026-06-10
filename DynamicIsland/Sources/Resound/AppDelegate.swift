import Cocoa

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private let coordinator = AppCoordinator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        closeEmptyWindow()
        coordinator.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator.stop()
    }

    private func closeEmptyWindow() {
        // Close any SwiftUI-created windows before we create our own
        for window in NSApplication.shared.windows {
            window.close()
        }
    }
}

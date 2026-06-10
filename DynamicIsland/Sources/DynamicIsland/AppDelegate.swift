import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        closeEmptyWindow()
        NowPlayingViewModel.shared.start()
        WindowManager.shared.show()
        MenuBarManager.shared.setup()
        HotkeyManager.shared.start {
            WindowManager.shared.toggle()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.stop()
    }

    private func closeEmptyWindow() {
        // Close any SwiftUI-created windows before we create our own
        for window in NSApplication.shared.windows {
            window.close()
        }
    }
}

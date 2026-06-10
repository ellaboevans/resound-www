import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
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
}

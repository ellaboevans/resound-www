import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowManager: WindowManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        windowManager = WindowManager()
        windowManager?.show()
    }
}

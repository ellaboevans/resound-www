import AppKit
import SwiftUI

final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()
    private var window: NSWindow?

    func open() {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 320),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        win.title = "Settings"
        win.level = .statusBar + 1
        win.isReleasedWhenClosed = false
        win.delegate = self
        let hostingView = NSHostingView(rootView: SettingsView())
        hostingView.sizingOptions = []
        win.contentView = hostingView
        win.center()
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = win
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}

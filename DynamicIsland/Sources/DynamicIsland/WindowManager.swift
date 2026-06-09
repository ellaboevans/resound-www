import Cocoa
import SwiftUI

final class WindowManager {
    private var window: NSWindow?

    func show() {
        let contentView = ContentView()

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)

        positionWindow(window)
        self.window = window
    }

    private func positionWindow(_ window: NSWindow) {
        guard let screen = NSScreen.main?.visibleFrame else { return }
        let windowWidth: CGFloat = 340
        let windowHeight: CGFloat = 34
        let x = screen.midX - windowWidth / 2
        let y = screen.maxY - windowHeight - 8
        window.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
        window.invalidateShadow()
    }

    func toggleExpanded(_ expanded: Bool) {
        guard let window = window, let screen = NSScreen.main?.visibleFrame else { return }
        let windowWidth: CGFloat = 340
        let collapsedHeight: CGFloat = 34
        let expandedHeight: CGFloat = 200

        let height = expanded ? expandedHeight : collapsedHeight
        let y = screen.maxY - height - 8
        let x = screen.midX - windowWidth / 2

        NSAnimationContext.runAnimationGroup { context in
            context.duration = expanded ? 0.4 : 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().setFrame(NSRect(x: x, y: y, width: windowWidth, height: height), display: true)
            window.invalidateShadow()
        }
    }
}

import Cocoa
import SwiftUI

final class WindowManager {
    private var window: NSWindow?
    private var isExpanded = false
    private let collapsedHeight: CGFloat = 40
    private let expandedHeight: CGFloat = 210

    func show() {
        let contentView = ContentView(onToggle: { [weak self] expanded in
            self?.toggleExpanded(expanded)
        })

        let hostingView = NSHostingView(rootView: contentView)

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

        positionWindow(window)
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }

    deinit {
        window?.close()
    }

    private func positionWindow(_ window: NSWindow) {
        guard let screen = NSScreen.main?.visibleFrame else { return }
        let width: CGFloat = 340
        let y = screen.maxY - collapsedHeight - 8
        let x = screen.midX - width / 2
        window.setFrame(NSRect(x: x, y: y, width: width, height: collapsedHeight), display: true)
        window.invalidateShadow()
    }

    func toggleExpanded(_ expanded: Bool) {
        isExpanded = expanded
        guard let window = window, let screen = NSScreen.main?.visibleFrame else { return }
        let width: CGFloat = 340
        let height = expanded ? expandedHeight : collapsedHeight
        let y = screen.maxY - height - 8
        let x = screen.midX - width / 2

        NSAnimationContext.runAnimationGroup { context in
            context.duration = expanded ? 0.4 : 0.2
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.23, 1, 0.32, 1)
            window.animator().setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
            window.invalidateShadow()
        }
    }
}

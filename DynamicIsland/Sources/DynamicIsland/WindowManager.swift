import Cocoa
import SwiftUI

final class WindowManager {
    private var window: NSWindow?
    private let collapsedHeight: CGFloat = 38
    private let expandedHeight: CGFloat = 192

    func show() {
        let contentView = ContentView(onToggle: { [weak self] expanded in
            if expanded {
                self?.expand()
            } else {
                self?.collapse()
            }
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
        window.level = .statusBar
        window.appearance = NSAppearance(named: .darkAqua)
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
        guard let screen = NSScreen.main else { return }
        let width: CGFloat = 340
        let y = screen.frame.maxY - collapsedHeight
        let x = screen.frame.midX - width / 2
        window.setFrame(NSRect(x: x, y: y, width: width, height: collapsedHeight), display: true)
        window.invalidateShadow()
    }

    private func expand() {
        guard let window = window, let screen = NSScreen.main else { return }
        let width: CGFloat = 340
        let y = screen.frame.maxY - expandedHeight
        let x = screen.frame.midX - width / 2
        window.setFrame(NSRect(x: x, y: y, width: width, height: expandedHeight), display: true)
        window.invalidateShadow()
    }

    private func collapse() {
        guard let window = window, let screen = NSScreen.main else { return }
        let width: CGFloat = 340
        let y = screen.frame.maxY - collapsedHeight
        let x = screen.frame.midX - width / 2
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            window.setFrame(NSRect(x: x, y: y, width: width, height: self.collapsedHeight), display: true)
            window.invalidateShadow()
        }
    }
}

import Cocoa
import SwiftUI

@MainActor
final class VolumeOverlayState: ObservableObject {
    static let shared = VolumeOverlayState()
    @Published var isActive = false
    @Published var level: Float = 0.5
    @Published var isMuted = false
    private var hideTask: Task<Void, Never>?
    private var window: NSWindow?
    private var windowVisible = false

    func show(level: Float, muted: Bool) {
        self.level = level
        self.isMuted = muted

        if window == nil { createWindow() }
        guard let win = window else { return }

        hideTask?.cancel()
        positionWindow()

        if windowVisible {
            win.alphaValue = 1
        } else {
            win.alphaValue = 0
            win.makeKeyAndOrderFront(nil)
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.1
                win.animator().alphaValue = 1
            }
            windowVisible = true
        }
        isActive = true

        hideTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            hide()
        }
    }

    func hide() {
        isActive = false
        hideTask?.cancel()
        hideTask = nil
        guard let win = window, windowVisible else { return }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            win.animator().alphaValue = 0
        } completionHandler: {
            win.orderOut(nil)
            self.windowVisible = false
        }
    }

    private func createWindow() {
        let contentView = VolumeOverlayView()

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.sizingOptions = []

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 48),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.isOpaque = false
        win.backgroundColor = .clear
        win.hasShadow = false
        win.level = .floating
        win.ignoresMouseEvents = true
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        win.contentView = hostingView

        window = win
    }

    private func positionWindow() {
        guard let win = window, let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let winWidth = win.frame.width
        let x = screen.frame.midX - winWidth / 2
        let y = screen.visibleFrame.maxY - 64
        win.setFrame(NSRect(x: x, y: y, width: winWidth, height: 48), display: true)
    }
}

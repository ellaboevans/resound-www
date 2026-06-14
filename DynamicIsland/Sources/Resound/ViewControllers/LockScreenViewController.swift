import Cocoa
import SwiftUI

final class LockScreenViewController: NSViewController {
    private var hostingView: NSHostingView<LockScreenPlayerView>?
    private var window: NSWindow?

    private var trackTitle = ""
    private var artistName = ""
    private var albumTitle = ""
    private var artwork: NSImage?
    private var elapsed: TimeInterval = 0
    private var duration: TimeInterval = 0
    private var isPlaying = false

    private static let panelWidth: CGFloat = 340
    private static let panelHeight: CGFloat = 172

    deinit { hide() }

    func show() {
        guard window == nil else { return }

        let hosting = NSHostingView(rootView: makeView())
        hosting.translatesAutoresizingMaskIntoConstraints = false
        self.hostingView = hosting

        let contentRect = NSRect(x: 0, y: 0, width: Self.panelWidth, height: Self.panelHeight)
        let panel = NSPanel(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel.contentView = hosting
        panel.orderFrontRegardless()
        self.window = panel

        positionWindow(panel)
    }

    func hide() {
        window?.orderOut(nil)
        window = nil
        hostingView = nil
    }

    func update(trackTitle: String, artistName: String, albumTitle: String, artwork: NSImage?,
                elapsed: TimeInterval, duration: TimeInterval, isPlaying: Bool) {
        self.trackTitle = trackTitle
        self.artistName = artistName
        self.albumTitle = albumTitle
        self.artwork = artwork
        self.elapsed = elapsed
        self.duration = duration
        self.isPlaying = isPlaying
        hostingView?.rootView = makeView()
    }

    private var isEmpty: Bool { trackTitle.isEmpty }

    private func makeView() -> LockScreenPlayerView {
        LockScreenPlayerView(
            trackTitle: trackTitle,
            artistName: artistName,
            albumTitle: albumTitle,
            artwork: artwork,
            elapsed: elapsed,
            duration: duration,
            isPlaying: isPlaying,
            isEmpty: isEmpty
        )
    }

    private func positionWindow(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let x = (screen.frame.width - Self.panelWidth) / 2
        let y = (screen.frame.height - Self.panelHeight) / 2
        panel.setFrame(NSRect(x: x, y: y, width: Self.panelWidth, height: Self.panelHeight), display: true)
    }
}

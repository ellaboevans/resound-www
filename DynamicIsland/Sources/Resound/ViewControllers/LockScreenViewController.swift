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
    private var isEmpty = true

    func show() {
        guard window == nil else { return }

        let hosting = NSHostingView(rootView: makeView())
        hosting.translatesAutoresizingMaskIntoConstraints = false
        self.hostingView = hosting

        let contentRect = NSRect(x: 0, y: 0, width: 340, height: 172)
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
        self.isEmpty = trackTitle.isEmpty
        hostingView?.rootView = makeView()
    }

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
        let panelWidth: CGFloat = 340
        let panelHeight: CGFloat = 172
        let x = (screen.frame.width - panelWidth) / 2
        let y = (screen.frame.height - panelHeight) / 2
        panel.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true)
        panel.center()
    }
}

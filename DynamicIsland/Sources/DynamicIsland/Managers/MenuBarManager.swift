import SwiftUI
import AppKit

final class MenuBarManager: NSObject {
    static let shared = MenuBarManager()

    private let statusItem: NSStatusItem
    private let popover: NSPopover

    private override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Now Playing")
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover.contentViewController = NSHostingController(rootView: MenuBarView())
        popover.behavior = .transient
    }

    func setup() {}

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            guard let button = statusItem.button else { return }
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}

struct MenuBarView: View {
    @ObservedObject private var nowPlaying = NowPlayingViewModel.shared

    var body: some View {
        VStack(spacing: 0) {
            nowPlayingSection; Divider()
            transportSection; Divider()
            bottomSection
        }
        .frame(width: 220)
        .padding(.vertical, 8)
    }

    private var nowPlayingSection: some View {
        VStack(spacing: 4) {
            Text("Now Playing").font(.caption).fontWeight(.semibold).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
            if nowPlaying.trackTitle.isEmpty {
                Text("No track playing").font(.body).foregroundStyle(.primary).frame(maxWidth: .infinity, alignment: .leading)
                Text("No artist").font(.callout).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(nowPlaying.trackTitle).font(.body).foregroundStyle(.primary).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                Text(nowPlaying.artistName).font(.callout).foregroundStyle(.secondary).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
    }

    private var transportSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "backward.fill").font(.title3).foregroundStyle(.primary).onTapGesture { NowPlayingViewModel.shared.previousTrack() }
            Image(systemName: nowPlaying.isPlaying ? "pause.fill" : "play.fill").font(.title2).foregroundStyle(.primary).onTapGesture { NowPlayingViewModel.shared.playPause() }
            Image(systemName: "forward.fill").font(.title3).foregroundStyle(.primary).onTapGesture { NowPlayingViewModel.shared.nextTrack() }
        }
        .padding(.vertical, 8)
    }

    private var bottomSection: some View {
        VStack(spacing: 4) {
            Text("Settings...").font(.body).foregroundStyle(.primary).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 12).padding(.vertical, 4).onTapGesture { SettingsWindowController.shared.open() }
            Text("Quit").font(.body).foregroundStyle(.primary).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 12).padding(.vertical, 4).onTapGesture { NSApplication.shared.terminate(nil) }
        }
        .padding(.vertical, 4)
    }
}

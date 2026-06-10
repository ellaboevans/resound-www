import SwiftUI
import AppKit

@MainActor
final class MenuBarManager: NSObject, NSMenuDelegate {
    static let shared = MenuBarManager()

    private let statusItem: NSStatusItem
    private let menu = NSMenu()

    private override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Now Playing")
            button.image?.isTemplate = true
        }

        menu.delegate = self
        statusItem.menu = menu
    }

    func setup() {
        rebuildMenu()
    }

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func rebuildMenu() {
        let nowPlaying = NowPlayingViewModel.shared
        menu.removeAllItems()

        let title = nowPlaying.trackTitle.isEmpty ? "No track playing" : nowPlaying.trackTitle
        let artist = nowPlaying.artistName.isEmpty ? "No artist" : nowPlaying.artistName

        let nowPlayingItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        nowPlayingItem.isEnabled = false
        menu.addItem(nowPlayingItem)

        let artistItem = NSMenuItem(title: artist, action: nil, keyEquivalent: "")
        artistItem.isEnabled = false
        menu.addItem(artistItem)

        menu.addItem(.separator())
        addItem("Previous", action: #selector(previousTrack))
        addItem(nowPlaying.isPlaying ? "Pause" : "Play", action: #selector(playPause))
        addItem("Next", action: #selector(nextTrack))
        menu.addItem(.separator())
        addItem("Settings...", action: #selector(openSettings))
        addItem("Quit Resound", action: #selector(quit))
    }

    private func addItem(_ title: String, action: Selector) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        menu.addItem(item)
    }

    @objc private func previousTrack() {
        NowPlayingViewModel.shared.previousTrack()
    }

    @objc private func playPause() {
        NowPlayingViewModel.shared.playPause()
    }

    @objc private func nextTrack() {
        NowPlayingViewModel.shared.nextTrack()
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.open()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

struct MenuRow: View {
    let title: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Text(title)
            .font(.body)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isHovered ? Color.gray.opacity(0.15) : Color.clear)
            .cornerRadius(4)
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
            .onTapGesture { action() }
    }
}

struct TransportButton: View {
    let systemName: String
    var fontSize: Font = .title3
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Image(systemName: systemName)
            .font(fontSize)
            .foregroundStyle(.primary)
            .padding(6)
            .background(isHovered ? Color.gray.opacity(0.15) : Color.clear)
            .cornerRadius(4)
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
            .onTapGesture { action() }
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
            TransportButton(systemName: "backward.fill") { NowPlayingViewModel.shared.previousTrack() }
            TransportButton(systemName: nowPlaying.isPlaying ? "pause.fill" : "play.fill", fontSize: .title2) { NowPlayingViewModel.shared.playPause() }
            TransportButton(systemName: "forward.fill") { NowPlayingViewModel.shared.nextTrack() }
        }
        .padding(.vertical, 8)
    }

    private var bottomSection: some View {
        VStack(spacing: 2) {
            MenuRow(title: "Settings...") { SettingsWindowController.shared.open() }
            MenuRow(title: "Quit") { NSApplication.shared.terminate(nil) }
        }
        .padding(.vertical, 4)
    }
}

import SwiftUI
import AppKit
import OSLog

@MainActor
final class MenuBarManager: NSObject, NSPopoverDelegate {
    static let shared = MenuBarManager()

    private let logger = Logger(subsystem: "com.resound.app", category: "MenuBar")
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()

    private override init() {
        super.init()
        popover.behavior = .transient
        popover.delegate = self
    }

    func setup() {
        logger.info("Setting up status item")
        statusItem = NSStatusBar.system.statusItem(withLength: 24)

        if let button = statusItem.button {
            button.image = Self.loadIcon()
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            let contentView = MenuBarPopoverView()
            popover.contentViewController = NSHostingController(rootView: contentView)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    func popoverDidClose(_ notification: Notification) {
        logger.info("Popover did close")
    }

    private static func loadIcon() -> NSImage? {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let outer = rect.insetBy(dx: 1.5, dy: 1.5)

            let barCount = 3
            let barWidth: CGFloat = 2
            let spacing: CGFloat = 3.5
            let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * spacing
            let startX = outer.midX - totalWidth / 2
            let maxHeight = outer.height - 6

            let heights: [CGFloat] = [0.4, 1.0, 0.7]

            for (i, relHeight) in heights.enumerated() {
                let barHeight = max(maxHeight * relHeight, 2)
                let x = startX + CGFloat(i) * (barWidth + spacing)
                let y = outer.midY - barHeight / 2
                let barRect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
                let barPath = NSBezierPath(roundedRect: barRect, xRadius: 1, yRadius: 1)
                barPath.fill()
            }

            return true
        }
        image.isTemplate = true
        return image
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

struct MenuBarPopoverView: View {
    @ObservedObject private var nowPlaying = NowPlayingViewModel.shared

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            nowPlayingSection
            Divider()
            transportSection
            Divider()
            bottomSection
        }
        .frame(width: 220)
        .padding(.vertical, 8)
    }

    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Resound")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("v1.0")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            Divider()
                .padding(.horizontal, 12)
        }
    }

    private var nowPlayingSection: some View {
        VStack(spacing: 4) {
            Text("Now Playing")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            if nowPlaying.trackTitle.isEmpty {
                Text("No track playing")
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("No artist")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(nowPlaying.trackTitle)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(nowPlaying.artistName)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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

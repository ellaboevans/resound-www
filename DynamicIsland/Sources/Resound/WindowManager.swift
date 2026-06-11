import Cocoa
import SwiftUI
import Combine

final class WindowManager {
    static let shared = WindowManager()
    private var windows: [String: NSWindow] = [:]
    private let collapsedHeight: CGFloat = 38
    private let expandedHeight: CGFloat = 192
    private var collapseWork: DispatchWorkItem?
    private let settings = SettingsViewModel.shared
    private var isResizing = false
    private var isRebuilding = false
    private var cancellables = Set<AnyCancellable>()

    init() {}

    func show() {
        rebuildWindows()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        settings.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.rebuildWindows()
            }
            .store(in: &cancellables)
    }

    deinit {
        for win in windows.values { win.close() }
        NotificationCenter.default.removeObserver(self)
    }

    func toggle() {
        if windows.values.contains(where: { $0.isVisible }) {
            for win in windows.values { win.orderOut(nil) }
        } else {
            for win in windows.values { win.makeKeyAndOrderFront(nil) }
        }
    }

    @objc private func screenConfigurationChanged() {
        rebuildWindows()
    }

    private func rebuildWindows() {
        guard !isRebuilding else { return }
        isRebuilding = true

        let targetScreens = resolveTargetScreens()
        let targetNames = Set(targetScreens.map(\.localizedName))

        for name in windows.keys {
            guard let win = windows[name] else { continue }
            if targetNames.contains(name) {
                if !win.isVisible {
                    win.makeKeyAndOrderFront(nil)
                }
            } else {
                win.orderOut(nil)
            }
        }

        for screen in targetScreens {
            let name = "\(screen.localizedName)"
            if let existing = windows[name] {
                let currentHeight = existing.frame.height
                positionWindow(existing, on: screen, height: currentHeight < collapsedHeight + 10 ? collapsedHeight : currentHeight)
            } else {
                let win = makeWindow(for: screen)
                windows[name] = win
            }
        }

        isRebuilding = false
    }

    private func resolveTargetScreens() -> [NSScreen] {
        switch settings.displayMode {
        case .allScreens:
            return NSScreen.screens
        case .singleScreen:
            guard !NSScreen.screens.isEmpty else { return [] }
            let name = settings.selectedScreenName
            if !name.isEmpty,
               let matched = NSScreen.screens.first(where: { $0.localizedName == name }) {
                return [matched]
            }
            return [NSScreen.screens[0]]
        }
    }

    private func makeWindow(for screen: NSScreen) -> NSWindow {
        let screenName = "\(screen.localizedName)"
        let isInitiallyExpanded = !settings.autoHide
        let contentView = ContentView(onToggle: { [weak self] expanded in
            guard let self else { return }
            guard let win = self.windows[screenName] else { return }
            if expanded {
                self.collapseWork?.cancel()
                self.positionWindow(win, height: self.expandedHeight)
            } else {
                self.scheduleCollapse(win)
            }
        })

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.sizingOptions = []

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

        positionWindow(window, on: screen, height: isInitiallyExpanded ? expandedHeight : collapsedHeight)
        window.makeKeyAndOrderFront(nil)
        return window
    }

    private func scheduleCollapse(_ window: NSWindow) {
        guard settings.autoHide else { return }
        collapseWork?.cancel()
        let work = DispatchWorkItem { [weak self, weak window] in
            guard let self, let win = window else { return }
            self.positionWindow(win, height: self.collapsedHeight)
        }
        collapseWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: work)
    }

    private func positionWindow(_ window: NSWindow, on screen: NSScreen, height: CGFloat) {
        guard !isResizing else { return }
        isResizing = true
        defer { isResizing = false }

        let width = CGFloat(settings.notchWidth)
        let x: CGFloat
        switch settings.notchPosition {
        case .left: x = screen.frame.minX + 8
        case .center: x = screen.frame.midX - width / 2
        case .right: x = screen.frame.maxX - width - 8
        }
        let topEdge = settings.notchPosition == .center ? screen.frame.maxY : screen.visibleFrame.maxY
        let y = topEdge - height
        let frame = NSRect(x: x, y: y, width: width, height: height)
        if window.frame.equalTo(frame) { return }
        window.setFrame(frame, display: true, animate: false)
        window.invalidateShadow()
    }

    private func positionWindow(_ window: NSWindow, height: CGFloat) {
        guard let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first else { return }
        positionWindow(window, on: screen, height: height)
    }
}

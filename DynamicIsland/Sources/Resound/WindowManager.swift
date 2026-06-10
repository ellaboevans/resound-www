import Cocoa
import SwiftUI
import Combine

final class WindowManager {
    static let shared = WindowManager()
    private var window: NSWindow?
    private let collapsedHeight: CGFloat = 38
    private let expandedHeight: CGFloat = 192
    private var isExpanded = false
    private var collapseWorkItem: DispatchWorkItem?
    private let settings = SettingsViewModel.shared
    private var isResizing = false
    private var cancellables = Set<AnyCancellable>()

    init() {}

    func show() {
        if let existing = window, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let contentView = ContentView(onToggle: { [weak self] expanded in
            if expanded { self?.expand() } else { self?.collapse() }
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

        positionWindow(window, height: collapsedHeight)
        window.makeKeyAndOrderFront(nil)
        self.window = window

        settings.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, let window = self.window else { return }
                let height = self.isExpanded ? self.expandedHeight : self.collapsedHeight
                self.positionWindow(window, height: height)
            }
            .store(in: &cancellables)
    }

    deinit { window?.close() }

    func toggle() {
        if isExpanded { collapse() } else { expand() }
    }

    private func expand() {
        collapseWorkItem?.cancel()
        guard !isExpanded else { return }
        isExpanded = true
        guard let window = window else { return }
        positionWindow(window, height: expandedHeight)
    }

    private func collapse() {
        collapseWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.isExpanded else { return }
            self.isExpanded = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                guard let self, let window = self.window else { return }
                self.positionWindow(window, height: self.collapsedHeight)
            }
        }
        collapseWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
    }

    private func positionWindow(_ window: NSWindow, height: CGFloat) {
        guard !isResizing else { return }
        isResizing = true
        defer { isResizing = false }

        guard let screen = NSScreen.main else { return }
        let width = CGFloat(settings.notchWidth)
        let x: CGFloat
        switch settings.notchPosition {
        case .left: x = screen.frame.minX + 8
        case .center: x = screen.frame.midX - width / 2
        case .right: x = screen.frame.maxX - width - 8
        }
        let y = screen.frame.maxY - height
        let frame = NSRect(x: x, y: y, width: width, height: height)
        if window.frame.equalTo(frame) { return }
        window.setFrame(frame, display: true, animate: false)
        window.invalidateShadow()
    }
}

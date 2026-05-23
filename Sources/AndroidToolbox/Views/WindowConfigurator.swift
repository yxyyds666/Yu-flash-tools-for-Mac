import SwiftUI
import AppKit

struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        ConfigView { window in
            context.coordinator.configureIfNeeded(window)
        }
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    final class Coordinator {
        private var configuredWindowNumbers: Set<Int> = []

        func configureIfNeeded(_ window: NSWindow) {
            let windowNumber = window.windowNumber
            guard !configuredWindowNumbers.contains(windowNumber) else { return }

            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
            window.styleMask.remove(.resizable)
            window.isOpaque = false
            window.backgroundColor = .clear
            window.toolbarStyle = .unified
            window.setContentSize(NSSize(width: 1280, height: 860))
            window.minSize = NSSize(width: 1280, height: 860)
            window.maxSize = NSSize(width: 1280, height: 860)

            configuredWindowNumbers.insert(windowNumber)
        }
    }

    final class ConfigView: NSView {
        private let onWindowReady: (NSWindow) -> Void

        init(onWindowReady: @escaping (NSWindow) -> Void) {
            self.onWindowReady = onWindowReady
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let window {
                onWindowReady(window)
            }
        }
    }
}

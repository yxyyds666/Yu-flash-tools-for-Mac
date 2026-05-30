import SwiftUI
import AppKit

enum AppIconProvider {
    static func circularIcon() -> NSImage? {
        guard let url = Bundle.module.url(forResource: "app-icon", withExtension: "png"),
              let source = NSImage(contentsOf: url) else {
            return nil
        }
        return makeCircularIcon(from: source)
    }

    private static func makeCircularIcon(from source: NSImage, outputSize: CGFloat = 512, cropInsetRatio: CGFloat = 0.02) -> NSImage {
        let iconSize = NSSize(width: outputSize, height: outputSize)
        let rendered = NSImage(size: iconSize)
        rendered.lockFocus()
        defer { rendered.unlockFocus() }

        NSColor.clear.setFill()
        NSRect(origin: .zero, size: iconSize).fill()

        let minSide = min(source.size.width, source.size.height)
        let inset = minSide * cropInsetRatio
        let cropSide = max(1, minSide - inset * 2)
        let cropRect = NSRect(
            x: (source.size.width - cropSide) / 2,
            y: (source.size.height - cropSide) / 2,
            width: cropSide,
            height: cropSide
        )

        let destinationRect = NSRect(origin: .zero, size: iconSize)
        NSGraphicsContext.current?.imageInterpolation = .high
        NSBezierPath(ovalIn: destinationRect).addClip()
        source.draw(in: destinationRect, from: cropRect, operation: .sourceOver, fraction: 1.0)
        return rendered
    }
}

@main
struct YutoolsApp: App {
    init() {
        if let icon = AppIconProvider.circularIcon() {
            NSApplication.shared.applicationIconImage = icon
        }
    }

    var body: some Scene {
        WindowGroup("羽工具箱") {
            AppShellView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1280, height: 860)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
    }
}

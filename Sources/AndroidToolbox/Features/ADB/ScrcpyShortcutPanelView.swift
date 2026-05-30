import AppKit
import CoreGraphics
import SwiftUI

struct ScrcpyShortcutPanelView: View {
    let onAction: (ScrcpyShortcutAction) -> Void

    var body: some View {
        VStack(spacing: 8) {
            ForEach(ScrcpyShortcutAction.allCases) { action in
                Button {
                    onAction(action)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: action.systemImage)
                            .font(.system(size: 14, weight: .semibold))
                        Text(action.title)
                            .font(.caption2.weight(.bold))
                    }
                    .frame(maxWidth: .infinity, minHeight: 42)
                }
                .buttonStyle(.plain)
                .foregroundStyle(action == .stop ? .red : .primary)
                .background(LiquidGlassTheme.panelBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(LiquidGlassTheme.secondaryStroke, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(10)
        .frame(width: 86)
        .background(LiquidGlassTheme.cardBackground)
        .background(LiquidGlassTheme.cardTint)
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(LiquidGlassTheme.stroke, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.20), radius: 16, y: 8)
    }
}

@MainActor
final class ScrcpyShortcutPanelController {
    private let panelSize = NSSize(width: 86, height: 426)
    private var panel: NSPanel?
    private var followTimer: Timer?
    private var lastAppliedFrame: NSRect?
    private var trackedWindowTitle: String = ""

    func show(windowTitle: String, onAction: @escaping (ScrcpyShortcutAction) -> Void) {
        trackedWindowTitle = windowTitle

        if panel == nil {
            let panel = NSPanel(
                contentRect: NSRect(origin: .zero, size: panelSize),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = false
            panel.hidesOnDeactivate = false
            panel.contentView = NSHostingView(rootView: ScrcpyShortcutPanelView(onAction: onAction))
            self.panel = panel
        } else if let hostingView = panel?.contentView as? NSHostingView<ScrcpyShortcutPanelView> {
            hostingView.rootView = ScrcpyShortcutPanelView(onAction: onAction)
        }

        syncPosition()
        panel?.orderFrontRegardless()
        startFollowing()
    }

    func close() {
        followTimer?.invalidate()
        followTimer = nil
        panel?.orderOut(nil)
        panel = nil
        lastAppliedFrame = nil
        trackedWindowTitle = ""
    }

    private func startFollowing() {
        followTimer?.invalidate()
        followTimer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.syncPosition()
            }
        }
        followTimer?.tolerance = 0.15
    }

    private func syncPosition() {
        guard let panel else { return }
        guard let targetFrame = findScrcpyWindowFrame() else { return }

        let visibleFrame = NSScreen.screens.first?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let screenMaxY = NSScreen.screens.map { $0.frame.maxY }.max() ?? visibleFrame.maxY
        let gap: CGFloat = 10
        var x = targetFrame.maxX + gap
        if x + panelSize.width > visibleFrame.maxX {
            x = targetFrame.minX - panelSize.width - gap
        }

        let y = min(
            max(screenMaxY - targetFrame.minY - panelSize.height, visibleFrame.minY + gap),
            visibleFrame.maxY - panelSize.height - gap
        )

        let newFrame = NSRect(x: x, y: y, width: panelSize.width, height: panelSize.height)
        guard shouldApplyFrame(newFrame) else { return }

        lastAppliedFrame = newFrame
        panel.setFrame(newFrame, display: false)
    }

    private func shouldApplyFrame(_ frame: NSRect) -> Bool {
        guard let lastAppliedFrame else { return true }
        return abs(lastAppliedFrame.origin.x - frame.origin.x) > 2
            || abs(lastAppliedFrame.origin.y - frame.origin.y) > 2
            || abs(lastAppliedFrame.size.width - frame.size.width) > 1
            || abs(lastAppliedFrame.size.height - frame.size.height) > 1
    }

    private func findScrcpyWindowFrame() -> CGRect? {
        guard let windowInfo = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        for info in windowInfo {
            guard (info[kCGWindowLayer as String] as? Int) == 0 else { continue }
            let owner = info[kCGWindowOwnerName as String] as? String ?? ""
            let name = info[kCGWindowName as String] as? String ?? ""
            let matchesScrcpy = owner.localizedCaseInsensitiveContains("scrcpy")
                || name == trackedWindowTitle
                || name.localizedCaseInsensitiveContains("scrcpy")
            guard matchesScrcpy else { continue }
            guard let frame = windowFrame(from: info[kCGWindowBounds as String]) else { continue }
            return frame
        }

        return nil
    }

    private func windowFrame(from value: Any?) -> CGRect? {
        guard let bounds = value as? [String: Any],
              let x = cgFloatValue(bounds["X"]),
              let y = cgFloatValue(bounds["Y"]),
              let width = cgFloatValue(bounds["Width"]),
              let height = cgFloatValue(bounds["Height"]) else {
            return nil
        }

        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func cgFloatValue(_ value: Any?) -> CGFloat? {
        if let value = value as? CGFloat {
            return value
        }
        if let value = value as? NSNumber {
            return CGFloat(value.doubleValue)
        }
        if let value = value as? Double {
            return CGFloat(value)
        }
        if let value = value as? Int {
            return CGFloat(value)
        }
        return nil
    }
}

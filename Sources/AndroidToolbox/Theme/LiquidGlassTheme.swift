import SwiftUI

struct LiquidGlassTheme {
    static let panelBackground = AnyShapeStyle(.ultraThinMaterial)
    static let cardBackground = AnyShapeStyle(.regularMaterial)
    static let cornerRadius: CGFloat = 20

    static let shellTint = LinearGradient(
        colors: [Color.cyan.opacity(0.16), Color.blue.opacity(0.10), Color.white.opacity(0.06)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardTint = LinearGradient(
        colors: [Color.white.opacity(0.20), Color.cyan.opacity(0.08), Color.blue.opacity(0.08)],
        startPoint: .top,
        endPoint: .bottomTrailing
    )

    static let glow = LinearGradient(
        colors: [Color.white.opacity(0.35), Color.clear],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let stroke = Color.white.opacity(0.26)
    static let shadow = Color.black.opacity(0.16)
    static let secondaryStroke = Color.white.opacity(0.18)
    static let secondaryShadow = Color.black.opacity(0.12)
}

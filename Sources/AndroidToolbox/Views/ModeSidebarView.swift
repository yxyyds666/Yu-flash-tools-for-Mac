import SwiftUI

struct ModeSidebarView: View {
    @Binding var mode: ToolboxMode
    var onEDLTap: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("工具箱")
                .font(.headline)

            modeButton(title: "ADB 工具箱", targetMode: .adb)
            modeButton(title: "Fastboot 工具箱", targetMode: .fastboot)
            modeButton(title: "EDL 工具箱 (9008)", targetMode: .edl)
        }
        .padding(12)
        .background(LiquidGlassTheme.cardBackground)
        .background(LiquidGlassTheme.cardTint)
        .overlay {
            RoundedRectangle(cornerRadius: LiquidGlassTheme.cornerRadius, style: .continuous)
                .stroke(LiquidGlassTheme.secondaryStroke, lineWidth: 1)
        }
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: LiquidGlassTheme.cornerRadius, style: .continuous)
                .fill(LiquidGlassTheme.glow)
                .opacity(0.25)
                .padding(1)
        }
        .clipShape(RoundedRectangle(cornerRadius: LiquidGlassTheme.cornerRadius, style: .continuous))
        .shadow(color: LiquidGlassTheme.secondaryShadow, radius: 8, y: 3)
    }

    private func modeButton(title: String, targetMode: ToolboxMode) -> some View {
        Button {
            if targetMode == .edl {
                onEDLTap?()
            } else {
                mode = targetMode
            }
        } label: {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(mode == targetMode ? LiquidGlassTheme.cardBackground : AnyShapeStyle(Color.white.opacity(0.03)))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(mode == targetMode ? LiquidGlassTheme.stroke : LiquidGlassTheme.secondaryStroke, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(AnimatedGlassButtonStyle())
    }
}

import SwiftUI

struct FastbootRebootSectionView: View {
    let actions: [FastbootRebootAction]
    let canExecuteCommand: Bool
    let isBusy: Bool
    let onReboot: (FastbootRebootAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ForEach(actions) { action in
                    Button {
                        onReboot(action)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: iconName(for: action.target))
                                .font(.system(size: 16, weight: .semibold))
                            Text(action.title)
                                .font(.subheadline.weight(.bold))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .center)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(LiquidGlassTheme.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: LiquidGlassTheme.cornerRadius, style: .continuous)
                                .stroke(LiquidGlassTheme.stroke, lineWidth: 1)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: LiquidGlassTheme.cornerRadius, style: .continuous))
                        .shadow(color: LiquidGlassTheme.shadow, radius: 8, y: 2)
                    }
                    .buttonStyle(AnimatedGlassButtonStyle())
                    .disabled(!canExecuteCommand || isBusy)
                }
            }
        }
        .padding(14)
        .background(LiquidGlassTheme.cardBackground)
        .background(LiquidGlassTheme.cardTint)
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: LiquidGlassTheme.cornerRadius, style: .continuous)
                .fill(LiquidGlassTheme.glow)
                .opacity(0.28)
                .padding(1)
        }
        .overlay {
            RoundedRectangle(cornerRadius: LiquidGlassTheme.cornerRadius, style: .continuous)
                .stroke(LiquidGlassTheme.stroke, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: LiquidGlassTheme.cornerRadius, style: .continuous))
        .shadow(color: LiquidGlassTheme.shadow, radius: 12, y: 5)
    }

    private func iconName(for target: FastbootRebootTarget) -> String {
        switch target {
        case .system:
            return "power"
        case .bootloader:
            return "gearshape.2.fill"
        case .fastbootd:
            return "hare.fill"
        case .recovery:
            return "cross.case.fill"
        }
    }
}

import SwiftUI

struct FastbootRebootSectionView: View {
    let actions: [FastbootRebootAction]
    let canExecuteCommand: Bool
    let isBusy: Bool
    let onReboot: (FastbootRebootAction) -> Void

    var body: some View {
        GroupBox("快速重启") {
            HStack(spacing: 10) {
                ForEach(actions) { action in
                    Button {
                        onReboot(action)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: iconName(for: action.target))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text(action.title)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.primary)
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
            .padding(.vertical, 4)
        }
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

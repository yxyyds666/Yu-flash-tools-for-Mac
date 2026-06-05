import SwiftUI

struct FastbootModeSelectorView: View {
    let modes: [FastbootFlashMode]
    @Binding var selectedMode: FastbootFlashMode
    var accent: Color = .red

    var body: some View {
        HStack(spacing: 8) {
            ForEach(modes) { mode in
                let isSelected = selectedMode == mode
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedMode = mode
                    }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: mode.systemImage)
                            .font(.system(size: 13, weight: .semibold))
                        Text(mode.title)
                            .font(.caption.weight(.bold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(isSelected ? accent : .primary)
                    .frame(maxWidth: .infinity, minHeight: 34)
                    .background(isSelected ? AnyShapeStyle(accent.opacity(0.10)) : LiquidGlassTheme.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isSelected ? accent.opacity(0.45) : LiquidGlassTheme.secondaryStroke, lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

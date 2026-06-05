import SwiftUI

struct FastbootModeSelectorView: View {
    let modes: [FastbootFlashMode]
    @Binding var selectedMode: FastbootFlashMode
    var body: some View {
        VStack(spacing: 6) {
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
                    .foregroundStyle(isSelected ? Color.red : .primary)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .padding(.horizontal, 10)
                    .background(isSelected ? AnyShapeStyle(Color.red.opacity(0.10)) : LiquidGlassTheme.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isSelected ? Color.red.opacity(0.45) : LiquidGlassTheme.secondaryStroke, lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 140)
    }
}

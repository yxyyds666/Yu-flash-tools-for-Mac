import SwiftUI

struct DeviceStatusCardView: View {
    let device: DeviceInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("设备状态")
                .font(.headline)
            Divider()
            Label(device.state, systemImage: device.isOnline ? "checkmark.circle.fill" : "bolt.horizontal.circle")
                .foregroundStyle(device.isOnline ? .green : .orange)
                .font(.subheadline)
            LabeledContent("序列号", value: device.serial)
                .font(.caption)
            LabeledContent("机型", value: device.model)
                .font(.caption)
        }
        .padding(10)
        .background(LiquidGlassTheme.cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: LiquidGlassTheme.cornerRadius, style: .continuous)
                .stroke(LiquidGlassTheme.secondaryStroke, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: LiquidGlassTheme.cornerRadius, style: .continuous))
        .shadow(color: LiquidGlassTheme.secondaryShadow, radius: 8, y: 3)
    }
}

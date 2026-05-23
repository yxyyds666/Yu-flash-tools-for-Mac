import SwiftUI

struct EDLPanelView: View {
    @Bindable var viewModel: EDLViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("EDL (9008)")
                    .font(.largeTitle.bold())
                Spacer()
                Button("探测 9008") {
                    viewModel.refreshDevices()
                }
            }

            GroupBox("原始命令") {
                HStack {
                    TextField("例如: --help", text: $viewModel.rawCommand)
                    Button("执行") { viewModel.runRawCommand() }
                }
            }

            Spacer()
        }
        .padding(20)
        .background(LiquidGlassTheme.panelBackground)
        .overlay {
            RoundedRectangle(cornerRadius: LiquidGlassTheme.cornerRadius, style: .continuous)
                .stroke(LiquidGlassTheme.stroke, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: LiquidGlassTheme.cornerRadius, style: .continuous))
        .shadow(color: LiquidGlassTheme.shadow, radius: 18, y: 8)
        .onAppear {
            viewModel.refreshDevices()
        }
    }
}

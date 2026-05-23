import SwiftUI

struct FastbootPanelView: View {
    @Bindable var viewModel: FastbootViewModel

    private let rebootColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            rebootSection
            getVarSection
            Spacer(minLength: 0)
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
            viewModel.startAutoRefresh()
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
    }

    private var headerRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Fastboot")
                    .font(.largeTitle.bold())
                Text("设备重启与变量读取")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if viewModel.isAutoRefreshing {
                Label("搜索设备中", systemImage: "dot.radiowaves.left.and.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Button("刷新设备") {
                viewModel.refreshDevices()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private var rebootSection: some View {
        GroupBox("快速重启") {
            LazyVGrid(columns: rebootColumns, spacing: 10) {
                ForEach(viewModel.rebootActions) { action in
                    Button {
                        viewModel.reboot(to: action.target, label: action.title)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: iconName(for: action.target))
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text(action.title)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 84, alignment: .center)
                        .padding(10)
                        .background(LiquidGlassTheme.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: LiquidGlassTheme.cornerRadius, style: .continuous)
                                .stroke(LiquidGlassTheme.stroke, lineWidth: 1)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: LiquidGlassTheme.cornerRadius, style: .continuous))
                        .shadow(color: LiquidGlassTheme.shadow, radius: 8, y: 2)
                    }
                    .buttonStyle(AnimatedGlassButtonStyle())
                    .disabled(!viewModel.canExecuteCommand || viewModel.isBusy)
                }
            }
        }
    }

    private var getVarSection: some View {
        GroupBox("读取变量 (getvar)") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    TextField("变量名", text: $viewModel.varKey)
                        .textFieldStyle(.roundedBorder)
                    Button("读取") {
                        viewModel.readVar()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canExecuteCommand || viewModel.isBusy || viewModel.varKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Text(viewModel.canExecuteCommand ? "当前设备可执行 fastboot 命令" : "请先连接并选择 fastboot 设备")
                    .font(.caption)
                    .foregroundStyle(viewModel.canExecuteCommand ? .green : .secondary)
            }
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

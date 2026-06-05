import SwiftUI

struct FastbootPanelView: View {
    @Bindable var viewModel: FastbootViewModel
    @State private var selectedFlashMode: FastbootFlashMode = .generic
    @State private var isFilePickerPresented = false
    @State private var showFlashConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerRow
            rebootSection
            flashDetailCard
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
                Text("设备重启与刷写入口")
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

            FastbootModeSelectorView(modes: viewModel.flashModes, selectedMode: $selectedFlashMode)
        }
    }

    private var rebootSection: some View {
        FastbootRebootSectionView(
            actions: viewModel.rebootActions,
            canExecuteCommand: viewModel.canExecuteCommand,
            isBusy: viewModel.isBusy
        ) { action in
            viewModel.reboot(to: action.target, label: action.title)
        }
    }

    private var flashDetailCard: some View {
        Group {
            if selectedFlashMode == .generic {
                GenericFastbootFlashCardView(
                    viewModel: viewModel,
                    isFilePickerPresented: $isFilePickerPresented,
                    showFlashConfirmation: $showFlashConfirmation
                )
            } else {
                placeholderFlashDetailCard
            }
        }
        .fileImporter(isPresented: $isFilePickerPresented, allowedContentTypes: [.data], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.customImagePath = url.path
                }
            case .failure:
                break
            }
        }
        .confirmationDialog(
            "确认刷写",
            isPresented: $showFlashConfirmation,
            titleVisibility: .visible
        ) {
            Button("确认刷写", role: .destructive) {
                let image = viewModel.customImagePath.trimmingCharacters(in: .whitespaces)
                let partition = viewModel.customPartitionText.trimmingCharacters(in: .whitespaces)
                guard !image.isEmpty, !partition.isEmpty else { return }
                viewModel.flashGeneric(imagePath: image, partition: partition)
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("即将把「\(viewModel.customImagePath.isEmpty ? "未知文件" : viewModel.customImagePath)」刷入「\(viewModel.customPartitionText)」分区。\n此操作不可撤销！")
        }
    }

    private var placeholderFlashDetailCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedFlashMode.title)
                        .font(.title2.bold())
                    Text("当前仅搭建刷写工作台 UI，真实刷写命令后续接入。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Label(viewModel.canExecuteCommand ? "Fastboot 已就绪" : "等待 fastboot 设备", systemImage: viewModel.canExecuteCommand ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(viewModel.canExecuteCommand ? .green : .orange)
            }

            HStack(spacing: 10) {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(.secondary)
                Text("刷写配置与分区预览将在后续版本中接入")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(LiquidGlassTheme.cardBackground)
        .background(LiquidGlassTheme.cardTint)
        .overlay {
            RoundedRectangle(cornerRadius: LiquidGlassTheme.cornerRadius, style: .continuous)
                .stroke(LiquidGlassTheme.stroke, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: LiquidGlassTheme.cornerRadius, style: .continuous))
        .shadow(color: LiquidGlassTheme.secondaryShadow, radius: 9, y: 4)
    }

}

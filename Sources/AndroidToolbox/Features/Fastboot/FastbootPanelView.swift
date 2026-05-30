import SwiftUI

struct FastbootPanelView: View {
    @Bindable var viewModel: FastbootViewModel
    @State private var selectedFlashMode: FastbootFlashMode = .generic
    @State private var isFilePickerPresented = false
    @State private var showFlashConfirmation = false

    private let flashColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            rebootSection
            flashWorkspaceSection
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
        }
    }

    private var rebootSection: some View {
        GroupBox("快速重启") {
            HStack(spacing: 10) {
                ForEach(viewModel.rebootActions) { action in
                    Button {
                        viewModel.reboot(to: action.target, label: action.title)
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
                    .disabled(!viewModel.canExecuteCommand || viewModel.isBusy)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var flashWorkspaceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            GroupBox("刷写模式") {
                LazyVGrid(columns: flashColumns, spacing: 12) {
                    ForEach(viewModel.flashModes) { mode in
                        flashModeCard(mode)
                    }
                }
                .padding(.vertical, 4)
            }

            flashDetailCard
        }
    }

    private func flashModeCard(_ mode: FastbootFlashMode) -> some View {
        let isSelected = selectedFlashMode == mode

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedFlashMode = mode
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: mode.systemImage)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(isSelected ? .orange : .primary)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(mode.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Text("配置入口")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isSelected ? .orange : .secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(LiquidGlassTheme.panelBackground)
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
            .padding(12)
            .background(LiquidGlassTheme.cardBackground)
            .overlay {
                RoundedRectangle(cornerRadius: LiquidGlassTheme.cornerRadius, style: .continuous)
                    .stroke(isSelected ? Color.orange.opacity(0.55) : LiquidGlassTheme.secondaryStroke, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: LiquidGlassTheme.cornerRadius, style: .continuous))
            .shadow(color: isSelected ? Color.orange.opacity(0.16) : LiquidGlassTheme.secondaryShadow, radius: 9, y: 3)
        }
        .buttonStyle(AnimatedGlassButtonStyle())
    }

    private var flashDetailCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedFlashMode.title)
                        .font(.title2.bold())
                    Text(selectedFlashMode == .generic ? "刷写工作台" : "当前仅搭建刷写工作台 UI，真实刷写命令后续接入。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Label(viewModel.canExecuteCommand ? "Fastboot 已就绪" : "等待 fastboot 设备", systemImage: viewModel.canExecuteCommand ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(viewModel.canExecuteCommand ? .green : .orange)
            }

            Divider()

            HStack(alignment: .top, spacing: 14) {
                flashConfigColumn
                flashPartitionPreviewColumn
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

    @ViewBuilder
    private var flashConfigColumn: some View {
        if selectedFlashMode == .generic {
            genericFlashConfigColumn
        } else {
            placeholderFlashConfigColumn
        }
    }

    private var placeholderFlashConfigColumn: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("刷写配置")
                .font(.headline)

            flashPlaceholderRow(title: packageTitle(for: selectedFlashMode), value: "未选择")
            flashPlaceholderRow(title: "刷写脚本", value: scriptHint(for: selectedFlashMode))
            flashPlaceholderRow(title: "设备校验", value: viewModel.selectedDevice.serial == "-" ? "未选择设备" : viewModel.selectedDevice.serial)

            HStack(spacing: 10) {
                Button("选择文件…") {}
                    .buttonStyle(.bordered)
                    .disabled(true)
                Button("开始刷写") {}
                    .buttonStyle(.borderedProminent)
                    .disabled(true)
            }

            Text("危险操作默认禁用；接入真实刷写前需要增加文件校验、分区确认和二次确认。")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var flashPartitionPreviewColumn: some View {
        if selectedFlashMode == .generic {
            genericPartitionPreviewColumn
        } else {
            placeholderPartitionPreviewColumn
        }
    }

    private var placeholderPartitionPreviewColumn: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("分区预览")
                .font(.headline)

            ForEach(partitionPreview(for: selectedFlashMode), id: \.self) { partition in
                HStack {
                    Image(systemName: "internaldrive.fill")
                        .foregroundStyle(.secondary)
                    Text(partition)
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Text("待配置")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(LiquidGlassTheme.panelBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func flashPlaceholderRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(LiquidGlassTheme.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var genericFlashConfigColumn: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("刷写配置")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("镜像文件")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("选择或输入镜像路径", text: $viewModel.customImagePath)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(LiquidGlassTheme.panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text("目标分区")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("输入分区名，例如 boot 或 my_partition", text: $viewModel.customPartitionText)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(LiquidGlassTheme.panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            flashPlaceholderRow(title: "设备校验", value: viewModel.selectedDevice.serial == "-" ? "未选择设备" : viewModel.selectedDevice.serial)

            HStack(spacing: 10) {
                Button("选择镜像…") {
                    isFilePickerPresented = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button("开始刷写") {
                    showFlashConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(!viewModel.canFlashGeneric || viewModel.isBusy)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var genericPartitionPreviewColumn: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("常用分区")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 6)], spacing: 6) {
                ForEach(viewModel.genericPartitions, id: \.self) { partition in
                    genericPartitionButton(partition)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func genericPartitionButton(_ partition: String) -> some View {
        let isSelected = viewModel.customPartitionText == partition
        return Button {
            viewModel.customPartitionText = partition
        } label: {
            Text(partition)
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 32)
                .background(isSelected ? AnyShapeStyle(Color.orange.opacity(0.2)) : LiquidGlassTheme.panelBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.orange.opacity(0.5) : LiquidGlassTheme.secondaryStroke, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func packageTitle(for mode: FastbootFlashMode) -> String {
        switch mode {
        case .generic:
            return "镜像文件"
        case .xiaomi:
            return "Fastboot ROM"
        case .oplusRealme:
            return "刷机包 / Payload"
        }
    }

    private func scriptHint(for mode: FastbootFlashMode) -> String {
        switch mode {
        case .generic:
            return "手动选择分区"
        case .xiaomi:
            return "flash_all / clean_all"
        case .oplusRealme:
            return "payload 解析后刷写"
        }
    }

    private func partitionPreview(for mode: FastbootFlashMode) -> [String] {
        switch mode {
        case .generic:
            return ["boot", "vendor_boot", "dtbo", "vbmeta"]
        case .xiaomi:
            return ["boot", "super", "vbmeta", "cust"]
        case .oplusRealme:
            return ["boot", "init_boot", "vendor_boot", "super"]
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

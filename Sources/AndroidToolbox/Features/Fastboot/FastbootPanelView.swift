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

    private let fastbootAccent = Color(red: 0.875, green: 0.184, blue: 0.184)
    private let fastbootPageBackground = Color(red: 0.969, green: 0.969, blue: 0.969)
    private let fastbootCardBackground = Color.white
    private let fastbootBorder = Color.black.opacity(0.08)

    private var genericFlashStep: Int {
        if viewModel.customImagePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return 1
        }
        if viewModel.customPartitionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return 2
        }
        return 3
    }

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
        Group {
            if selectedFlashMode == .generic {
                genericFlashWorkspace
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
    }

    private var genericFlashWorkspace: some View {
        VStack(alignment: .leading, spacing: 22) {
            genericStepTabs
            HStack(alignment: .top, spacing: 22) {
                genericMainFlashCard
                genericSummaryCard
            }
        }
        .padding(24)
        .background(fastbootCardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(fastbootBorder, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 18, y: 8)
    }

    private var genericStepTabs: some View {
        HStack(spacing: 12) {
            genericStepCard(index: 1, title: "选择镜像", subtitle: "选择或输入 .img 文件路径")
            genericStepCard(index: 2, title: "配置参数", subtitle: "选择或自定义刷入分区")
            genericStepCard(index: 3, title: "开始刷写", subtitle: "确认后执行 fastboot flash")
        }
    }

    private func genericStepCard(index: Int, title: String, subtitle: String) -> some View {
        let isCurrent = genericFlashStep == index
        let isDone = genericFlashStep > index

        return HStack(spacing: 12) {
            Text("\(index)")
                .font(.headline.weight(.bold))
                .foregroundStyle(isCurrent || isDone ? .white : .secondary)
                .frame(width: 36, height: 36)
                .background(isCurrent ? fastbootAccent : (isDone ? Color.black.opacity(0.82) : Color.black.opacity(0.08)))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
        .padding(.horizontal, 14)
        .background(isCurrent ? fastbootAccent.opacity(0.08) : fastbootPageBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isCurrent ? fastbootAccent.opacity(0.35) : fastbootBorder, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var genericMainFlashCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("通用刷机")
                        .font(.title2.weight(.bold))
                    Text("用于标准 Fastboot 分区刷写。输入镜像路径和目标分区即可执行。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Label(viewModel.canExecuteCommand ? "设备已就绪" : "等待设备", systemImage: viewModel.canExecuteCommand ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(viewModel.canExecuteCommand ? .green : fastbootAccent)
            }

            genericImageSelectorRow
            genericPartitionInputRow
            genericPartitionChips

            HStack(spacing: 16) {
                Text("刷写会修改设备分区。点击开始后会先弹出确认对话框。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("开始刷写") {
                    showFlashConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(fastbootAccent)
                .disabled(!viewModel.canFlashGeneric || viewModel.isBusy)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 360, alignment: .topLeading)
        .padding(22)
        .background(fastbootCardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(fastbootBorder, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var genericImageSelectorRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("镜像文件")
                    .font(.caption.weight(.bold))
                Spacer()
                Text("支持选择文件或手动输入路径")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 10) {
                TextField("选择或输入镜像路径", text: $viewModel.customImagePath)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption.weight(.semibold))
                Button("浏览...") {
                    isFilePickerPresented = true
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
        }
    }

    private var genericPartitionInputRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("刷入分区")
                    .font(.caption.weight(.bold))
                Spacer()
                Text("可直接输入自定义分区名")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            TextField("输入分区名，例如 boot 或 my_partition", text: $viewModel.customPartitionText)
                .textFieldStyle(.roundedBorder)
                .font(.caption.weight(.semibold))
        }
    }

    private var genericPartitionChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("常用分区")
                    .font(.caption.weight(.bold))
                Spacer()
                Text("点击后填入上方输入框")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
                ForEach(viewModel.genericPartitions, id: \.self) { partition in
                    genericPartitionButton(partition)
                }
            }
        }
    }

    private var genericSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("刷写摘要")
                    .font(.title3.weight(.bold))
                Text("执行前快速确认目标设备、镜像和分区。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            genericSummaryRow(title: "当前设备", value: viewModel.selectedDevice.serial == "-" ? "未选择设备" : "\(viewModel.selectedDevice.serial) / \(viewModel.selectedDevice.state)")
            genericSummaryRow(title: "镜像文件", value: imageFileName)
            genericSummaryRow(title: "目标分区", value: viewModel.customPartitionText.isEmpty ? "未配置" : viewModel.customPartitionText)
            genericSummaryRow(title: "命令预览", value: commandPreview)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 5) {
                Text("ready fastboot device detected")
                    .foregroundStyle(.green)
                Text(commandPreview)
                    .foregroundStyle(fastbootAccent)
                Text("waiting for confirmation...")
                    .foregroundStyle(.secondary)
            }
            .font(.caption.monospaced())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.black.opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .frame(width: 360, alignment: .topLeading)
        .frame(minHeight: 360, alignment: .topLeading)
        .padding(22)
        .background(fastbootPageBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(fastbootBorder, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var imageFileName: String {
        let path = viewModel.customImagePath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else { return "未选择镜像" }
        return URL(fileURLWithPath: path).lastPathComponent
    }

    private var commandPreview: String {
        let partition = viewModel.customPartitionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let image = imageFileName == "未选择镜像" ? "<image>" : imageFileName
        return "fastboot flash \(partition.isEmpty ? "<partition>" : partition) \(image)"
    }

    private func genericSummaryRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(fastbootCardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(fastbootBorder, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 34)
                .background(isSelected ? AnyShapeStyle(fastbootAccent.opacity(0.10)) : AnyShapeStyle(fastbootPageBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? fastbootAccent.opacity(0.38) : fastbootBorder, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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

import SwiftUI

struct GenericFastbootFlashCardView: View {
    @Bindable var viewModel: FastbootViewModel
    @Binding var isFilePickerPresented: Bool
    @Binding var showFlashConfirmation: Bool
    @State private var showCustomPartitionInput = false
    @State private var customPartitionInput = ""

    private var currentStep: Int {
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
            stepTabs
            mainCard
        }
    }

    private var stepTabs: some View {
        HStack(spacing: 8) {
            stepCard(index: 1, title: "选择镜像", subtitle: "选择 .img 文件")
            stepCard(index: 2, title: "配置参数", subtitle: "选择或自定义刷入分区")
            stepCard(index: 3, title: "开始刷写", subtitle: "确认后执行 fastboot flash")
        }
    }

    private func stepCard(index: Int, title: String, subtitle: String) -> some View {
        let isCurrent = currentStep == index
        let isDone = currentStep > index

        return HStack(spacing: 9) {
            Text("\(index)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(isCurrent || isDone ? .white : .secondary)
                .frame(width: 28, height: 28)
                .background(isCurrent ? Color.red : (isDone ? Color.black.opacity(0.82) : Color.black.opacity(0.08)))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.horizontal, 10)
        .background(isCurrent ? AnyShapeStyle(Color.red.opacity(0.08)) : LiquidGlassTheme.panelBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isCurrent ? Color.red.opacity(0.35) : Color.black.opacity(0.08), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var mainCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("通用刷机")
                        .font(.headline.weight(.bold))
                    Text("用于标准 Fastboot 分区刷写。选择镜像文件和目标分区即可执行。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Label(viewModel.canExecuteCommand ? "设备已就绪" : "等待设备", systemImage: viewModel.canExecuteCommand ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(viewModel.canExecuteCommand ? .green : Color.red)
            }

            HStack(alignment: .top, spacing: 12) {
                imagePickerButton
                partitionPickerMenu
            }
            commandPreviewRow

            HStack(spacing: 12) {
                Text("刷写会修改设备分区。点击开始后会先弹出确认对话框。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("开始刷写") {
                    showFlashConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .tint(Color.red)
                .disabled(!viewModel.canFlashGeneric || viewModel.isBusy)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(14)
        .background(LiquidGlassTheme.cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LiquidGlassTheme.secondaryStroke, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var imagePickerButton: some View {
        Button {
            isFilePickerPresented = true
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.badge.plus")
                        .font(.caption.weight(.semibold))
                    Text("选择镜像文件")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(Color.red)

                Text(viewModel.customImagePath.isEmpty ? "点击选择 .img 文件" : viewModel.customImagePath)
                    .font(.caption2.monospaced())
                    .foregroundStyle(viewModel.customImagePath.isEmpty ? .secondary : .primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(LiquidGlassTheme.cardBackground)
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(LiquidGlassTheme.secondaryStroke, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var partitionPickerMenu: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "folder.badge.gearshape")
                    .font(.caption.weight(.semibold))
                Text("刷入分区")
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(Color.red)

            Menu {
                ForEach(viewModel.genericPartitions, id: \.self) { partition in
                    Button(partition) {
                        viewModel.customPartitionText = partition
                    }
                }
                Divider()
                Button("✏️ 输入自定义分区名...") {
                    customPartitionInput = ""
                    showCustomPartitionInput = true
                }
            } label: {
                HStack(spacing: 8) {
                    Text(viewModel.customPartitionText.isEmpty ? "选择分区" : viewModel.customPartitionText)
                        .font(.caption.weight(.bold))
                        .lineLimit(1)
                        .foregroundStyle(viewModel.customPartitionText.isEmpty ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 34)
                .padding(.horizontal, 10)
                .background(LiquidGlassTheme.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .menuStyle(.borderlessButton)

            if showCustomPartitionInput {
                HStack(spacing: 8) {
                    TextField("输入自定义分区名", text: $customPartitionInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                    Button("确认") {
                        let trimmed = customPartitionInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            viewModel.customPartitionText = trimmed
                        }
                        showCustomPartitionInput = false
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(Color.red)
                    .disabled(customPartitionInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(LiquidGlassTheme.cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(LiquidGlassTheme.secondaryStroke, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var commandPreviewRow: some View {
        HStack(spacing: 8) {
            Text("命令预览")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Text(viewModel.genericFlashCommandPreview)
                .font(.caption.monospaced().weight(.semibold))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(LiquidGlassTheme.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

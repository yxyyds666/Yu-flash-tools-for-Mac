# Fastboot Generic Flash Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Map the approved `docs/fastboot-redesign-preview.html` design into the SwiftUI Fastboot generic flashing area while preserving the existing Fastboot header and quick reboot section.

**Architecture:** Keep the implementation localized to `FastbootPanelView.swift`. Reuse existing `FastbootViewModel` state and commands; this is a visual/layout refactor, not a command-flow change. Add small private SwiftUI helpers for the new step tabs, generic flash card, summary card, and Windows 11-style controls.

**Tech Stack:** SwiftUI, Observation `@Bindable`, existing `FastbootViewModel`, existing `FastbootService.flash(partition:image:serial:)`, Swift Package Manager test/build commands.

---

## File Structure

- Modify: `Sources/AndroidToolbox/Features/Fastboot/FastbootPanelView.swift`
  - Preserve `headerRow` and `rebootSection`.
  - Replace the generic-mode detail area with the approved three-step card design.
  - Keep Xiaomi / OPlus placeholder behavior unchanged.
  - Keep `.fileImporter` and `.confirmationDialog` attached to the main flash card.
- No model/service changes expected.
- No new tests expected because this is a SwiftUI visual layout change using existing behavior; verification is `swift build` and `swift test`.

---

### Task 1: Add Generic Flash Step State

**Files:**
- Modify: `Sources/AndroidToolbox/Features/Fastboot/FastbootPanelView.swift`

- [ ] **Step 1: Add a private computed property for current step**

Add this inside `FastbootPanelView` near the other private computed properties:

```swift
private var genericFlashStep: Int {
    if viewModel.customImagePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return 1
    }
    if viewModel.customPartitionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return 2
    }
    return 3
}
```

- [ ] **Step 2: Build to verify no syntax issues**

Run: `swift build 2>&1`

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Sources/AndroidToolbox/Features/Fastboot/FastbootPanelView.swift
git commit -m "refactor(fastboot): derive generic flash workflow step"
```

---

### Task 2: Replace Generic Detail Card With Windows 11 Style Workspace

**Files:**
- Modify: `Sources/AndroidToolbox/Features/Fastboot/FastbootPanelView.swift`

- [ ] **Step 1: Add local design constants**

Add this inside `FastbootPanelView`:

```swift
private let fastbootAccent = Color(red: 0.875, green: 0.184, blue: 0.184)
private let fastbootPageBackground = Color(red: 0.969, green: 0.969, blue: 0.969)
private let fastbootCardBackground = Color.white
private let fastbootBorder = Color.black.opacity(0.08)
```

- [ ] **Step 2: Update `flashDetailCard` generic branch**

Change the body of `flashDetailCard` so generic mode renders the new workspace while non-generic modes keep the existing placeholder layout:

```swift
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
```

- [ ] **Step 3: Rename the current implementation to `placeholderFlashDetailCard`**

Move the existing `VStack(alignment: .leading, spacing: 12) { ... }` card body into:

```swift
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
            placeholderFlashConfigColumn
            placeholderPartitionPreviewColumn
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
```

- [ ] **Step 4: Build**

Run: `swift build 2>&1`

Expected: build succeeds.

- [ ] **Step 5: Commit**

```bash
git add Sources/AndroidToolbox/Features/Fastboot/FastbootPanelView.swift
git commit -m "refactor(fastboot): split generic flash workspace from placeholders"
```

---

### Task 3: Implement Generic Flash Workspace Views

**Files:**
- Modify: `Sources/AndroidToolbox/Features/Fastboot/FastbootPanelView.swift`

- [ ] **Step 1: Add the workspace container**

Add:

```swift
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
```

- [ ] **Step 2: Add the three step tabs**

Add:

```swift
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
```

- [ ] **Step 3: Add the main flash card**

Add:

```swift
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
```

- [ ] **Step 4: Add input rows and partition chips**

Add:

```swift
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
```

- [ ] **Step 5: Update `genericPartitionButton(_:)` to use red accent**

Replace the button styling with:

```swift
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
```

- [ ] **Step 6: Build and commit**

Run: `swift build 2>&1`

Expected: build succeeds.

```bash
git add Sources/AndroidToolbox/Features/Fastboot/FastbootPanelView.swift
git commit -m "feat(fastboot): redesign generic flash workspace"
```

---

### Task 4: Add Summary Card and Final Verification

**Files:**
- Modify: `Sources/AndroidToolbox/Features/Fastboot/FastbootPanelView.swift`

- [ ] **Step 1: Add summary card helpers**

Add:

```swift
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
    .frame(width: 360, minHeight: 360, alignment: .topLeading)
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
```

- [ ] **Step 2: Run final build**

Run: `swift build 2>&1`

Expected: build succeeds.

- [ ] **Step 3: Run all tests**

Run: `swift test 2>&1`

Expected: 22 tests pass.

- [ ] **Step 4: Commit final UI polish**

```bash
git add Sources/AndroidToolbox/Features/Fastboot/FastbootPanelView.swift
git commit -m "feat(fastboot): add generic flash summary and command preview"
```

---

## Self-Review

- Spec coverage: The plan preserves header and quick reboot, updates only generic flashing, adds three workflow steps, large card layout, image selector, path field, browse button, partition input, common partition chips, flash button, red accent, white cards, light gray Windows 11-style background, summary, and command preview.
- Placeholder scan: No TBD/TODO/fill-in placeholders remain.
- Type consistency: Uses existing `viewModel.customImagePath`, `viewModel.customPartitionText`, `viewModel.genericPartitions`, `viewModel.canFlashGeneric`, `viewModel.flashGeneric(imagePath:partition:)`, `isFilePickerPresented`, and `showFlashConfirmation`.
